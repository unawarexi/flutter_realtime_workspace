// ============================================================================
// TeamSpot — Issue Service (full infrastructure integration)
// Bugs, features, tasks with attachments, comments, linking, Kafka events
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Issue from "./models/issue.model.js";
import { notFound, forbidden, badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";

class IssueRepository extends BaseRepository {
  constructor() { super(Issue, { tenantScoped: true }); }
}

class IssueService extends BaseService {
  constructor() {
    super(new IssueRepository(), {
      name: "IssueService",
      cachePrefix: "issue",
      cacheTTL: CacheTTL.TASK_LIST || 30,
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────
  async createIssue({ tenantId, userId, projectId, workspaceId, title, description, type = "bug",
    priority = "medium", severity = "minor", assignedTo, dueDate, labels, tags,
  }) {
    const count = await this.repository.count({ projectId }, { tenantId });
    const key = `ISS-${String(count + 1).padStart(4, "0")}`;

    const issue = await this.repository.create({
      tenantId, projectId, workspaceId, key,
      title, description, type, priority, severity,
      assignedTo, dueDate, labels, tags,
      createdBy: userId, reporter: userId,
      status: "open",
    }, { tenantId });

    // Notify assignee
    if (assignedTo && String(assignedTo) !== String(userId)) {
      emitToUser(String(assignedTo), SocketEvents.NOTIFICATION, {
        type: "issue.assigned", issueId: issue._id, key, title, priority,
      });
      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email", _meta: { userId: String(assignedTo) },
        templateName: "issueAssigned",
        templateData: { key, title, priority, type },
      });
    }

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "issue.created", issueId: issue._id, projectId, tenantId, userId, key,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "issue.created", resourceType: "issue",
      resourceId: issue._id, actor: { id: userId }, tenantId,
    });

    eventBus.publish(DomainEvents.ISSUE_CREATED || "issue.created", { issueId: issue._id, tenantId });
    return issue;
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  async listIssues({ tenantId, projectId, workspaceId, status, type, priority, assignedTo, userId, page = 1, limit = 20, sort }) {
    const filter = {};
    if (projectId)   filter.projectId   = projectId;
    if (workspaceId) filter.workspaceId = workspaceId;
    if (status)      filter.status      = status;
    if (type)        filter.type        = type;
    if (priority)    filter.priority    = priority;
    if (assignedTo)  filter.assignedTo  = assignedTo === "me" ? userId : assignedTo;

    return this.repository.paginate({ filter, page: +page, limit: +limit, sort: sort || { createdAt: -1 } }, { tenantId });
  }

  // ── Get ──────────────────────────────────────────────────────────────────────
  async getIssueById(id, tenantId) {
    const issue = await this.cachedFindById(id, { tenantId });
    if (!issue) throw notFound("Issue");
    return issue;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateIssue({ id, updates, tenantId, userId }) {
    const issue = await this.getIssueById(id, tenantId);

    const statusChange = updates.status && updates.status !== issue.status;
    if (statusChange) {
      if (updates.status === "resolved") updates.resolvedAt = new Date();
      if (updates.status === "closed")   updates.closedAt   = new Date();
    }

    // Notify new assignee if changed
    if (updates.assignedTo && String(updates.assignedTo) !== String(issue.assignedTo)) {
      emitToUser(String(updates.assignedTo), SocketEvents.NOTIFICATION, {
        type: "issue.reassigned", issueId: id, key: issue.key, title: issue.title,
      });
    }

    const updated = await this.updateById(id, updates, { tenantId });

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: statusChange ? "issue.status_changed" : "issue.updated",
      issueId: id, userId, tenantId,
      ...(statusChange ? { oldStatus: issue.status, newStatus: updates.status } : {}),
    });

    return updated;
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  async deleteIssue({ id, tenantId, userId }) {
    const issue = await this.getIssueById(id, tenantId);
    if (String(issue.createdBy) !== String(userId)) throw forbidden("Only the reporter can delete this issue");

    await this.deleteById(id, { tenantId });
    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, { type: "issue.deleted", issueId: id, tenantId, userId });
  }

  // ── Comment ──────────────────────────────────────────────────────────────────
  async addComment({ id, content, tenantId, userId }) {
    if (!content?.trim()) throw badRequest("Comment content is required");

    const issue = await this.getIssueById(id, tenantId);
    const updated = await this.updateById(id, {
      $push: { comments: { userId, content: content.trim(), createdAt: new Date() } },
    }, { tenantId });

    // Notify reporter/assignee
    const notifyIds = [String(issue.reporter), String(issue.assignedTo)].filter(u => u && u !== String(userId));
    for (const uid of [...new Set(notifyIds)]) {
      emitToUser(uid, SocketEvents.NOTIFICATION, { type: "issue.comment_added", issueId: id, key: issue.key });
    }

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, { type: "issue.comment_added", issueId: id, userId, tenantId });
    return updated;
  }

  // ── Link Issues ──────────────────────────────────────────────────────────────
  async linkIssue({ id, targetIssueId, relation, tenantId }) {
    const [issue, target] = await Promise.all([
      this.getIssueById(id, tenantId),
      this.getIssueById(targetIssueId, tenantId),
    ]);

    const updated = await this.updateById(id, {
      $addToSet: { linkedIssues: { issueId: targetIssueId, relation } },
    }, { tenantId });
    return updated;
  }

  // ── Attachments ──────────────────────────────────────────────────────────────
  async addAttachment({ id, file, tenantId, userId }) {
    const result = await uploadBuffer(file.buffer, {
      folder: `teamspot/${tenantId}/issues/${id}`, resource_type: "auto",
    });
    const attachment = { url: result.secure_url, publicId: result.public_id, filename: file.originalname, bytes: result.bytes };

    await this.updateById(id, { $push: { attachments: attachment } }, { tenantId });
    await publishEvent(KafkaTopics.STORAGE_EVENTS || KafkaTopics.TASK_EVENTS, tenantId, {
      type: "issue.attachment_added", issueId: id, userId, tenantId,
    });
    return attachment;
  }
}

export const issueService = new IssueService();
