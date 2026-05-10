// ============================================================================
// TeamSpot — Workspace Service (full infrastructure integration)
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Workspace from "./models/workspace.model.js";
import { AppError, notFound, conflict, forbidden } from "../../core/errors/app-error.js";
import { HttpStatus, KafkaTopics, RabbitQueues, SocketEvents, CacheTTL, ErrorCodes } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToWorkspace, emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("WorkspaceService");

class WorkspaceRepository extends BaseRepository {
  constructor() {
    super(Workspace, { tenantScoped: true });
  }
}

class WorkspaceService extends BaseService {
  constructor() {
    super(new WorkspaceRepository(), {
      name: "WorkspaceService",
      cachePrefix: "workspace",
      cacheTTL: CacheTTL.WORKSPACE || 120,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────
  async createWorkspace({ name, slug, description, icon, color, settings, tenantId, orgId, userId }) {
    const existing = await this.repository.findOne({ tenantId, slug });
    if (existing) throw conflict("Workspace slug is already taken");

    const workspace = await this.repository.create({
      name, slug, description, icon, color, settings,
      tenantId, orgId,
      owner: userId,
      members: [{ userId, role: "workspace_admin", joinedAt: new Date() }],
      memberCount: 1,
    });

    // Real-time: notify org members
    emitToWorkspace(workspace._id.toString(), SocketEvents.WORKSPACE_UPDATED, { action: "created", workspaceId: workspace._id });

    // Kafka fan-out for cross-service reactions (search indexing, analytics, etc.)
    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "workspace.created",
      workspaceId: workspace._id,
      tenantId, orgId, userId,
    });

    // Audit
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "workspace.created",
      resourceType: "workspace",
      resourceId: workspace._id,
      actor: { id: userId },
      tenantId,
      category: "workspace",
    });

    eventBus.publish(DomainEvents.WORKSPACE_CREATED, { workspaceId: workspace._id, tenantId, orgId });
    return workspace;
  }

  // ── List workspaces for user ─────────────────────────────────────────────────
  async listWorkspaces({ tenantId, orgId, userId, page = 1, limit = 20 }) {
    const filter = {
      tenantId,
      "members.userId": userId,
      status: { $ne: "deleted" },
    };
    if (orgId) filter.orgId = orgId;

    return this.repository.paginate({ filter, page, limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get by ID (cached) ───────────────────────────────────────────────────────
  async getWorkspaceById(id, tenantId) {
    const workspace = await this.cachedFindById(id, { tenantId });
    if (!workspace || workspace.status === "deleted") throw notFound("Workspace");
    return workspace;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateWorkspace({ id, updates, tenantId, userId }) {
    const workspace = await this.getWorkspaceById(id, tenantId);
    const updated = await this.updateById(id, updates, { tenantId });

    emitToWorkspace(id, SocketEvents.WORKSPACE_UPDATED, { workspaceId: id, updates });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "workspace.updated",
      workspaceId: id,
      tenantId, userId, updates,
    });

    return updated;
  }

  // ── Archive / delete ─────────────────────────────────────────────────────────
  async archiveWorkspace({ id, tenantId, userId }) {
    await this.getWorkspaceById(id, tenantId);
    const updated = await this.updateById(id, { status: "archived", archivedAt: new Date() }, { tenantId });
    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, { type: "workspace.archived", workspaceId: id, tenantId, userId });
    return updated;
  }

  // ── Members ──────────────────────────────────────────────────────────────────
  async addMember({ id, targetUserId, role = "member", tenantId, actorId }) {
    const workspace = await this.getWorkspaceById(id, tenantId);

    if (workspace.members.some(m => m.userId.toString() === targetUserId)) {
      throw conflict("User is already a member");
    }

    const updated = await this.updateById(id, {
      $push: { members: { userId: targetUserId, role, joinedAt: new Date() } },
      $inc: { memberCount: 1 },
    }, { tenantId });

    emitToWorkspace(id, SocketEvents.MEMBER_JOINED, { workspaceId: id, userId: targetUserId, role });
    emitToUser(targetUserId, SocketEvents.WORKSPACE_UPDATED, { action: "member_added", workspaceId: id });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, { type: "workspace.member_added", workspaceId: id, userId: targetUserId, role, tenantId });
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      to: null, // notification worker resolves email from userId
      userId: targetUserId,
      templateName: "workspaceInvite",
      templateData: { workspaceName: workspace.name, role },
    });

    return updated;
  }

  async removeMember({ id, targetUserId, tenantId, actorId }) {
    const workspace = await this.getWorkspaceById(id, tenantId);

    if (workspace.owner?.toString() === targetUserId) {
      throw forbidden("Cannot remove the workspace owner");
    }

    const updated = await this.updateById(id, {
      $pull: { members: { userId: targetUserId } },
      $inc: { memberCount: -1 },
    }, { tenantId });

    emitToUser(targetUserId, SocketEvents.WORKSPACE_UPDATED, { action: "member_removed", workspaceId: id });
    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, { type: "workspace.member_removed", workspaceId: id, userId: targetUserId, tenantId });

    return updated;
  }

  async updateMemberRole({ id, targetUserId, role, tenantId }) {
    await this.getWorkspaceById(id, tenantId);
    return this.updateById(id, {
      $set: { "members.$[m].role": role },
    }, { tenantId, arrayFilters: [{ "m.userId": targetUserId }] });
  }

  async getMembers({ id, tenantId, page = 1, limit = 50 }) {
    const workspace = await this.getWorkspaceById(id, tenantId);
    // Paginate members sub-array manually
    const start = (page - 1) * limit;
    const members = workspace.members.slice(start, start + limit);
    return { data: members, total: workspace.memberCount || workspace.members.length, page, limit };
  }
}

export const workspaceService = new WorkspaceService();
