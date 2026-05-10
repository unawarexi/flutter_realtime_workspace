// ============================================================================
// TeamSpot — Ticket Service (support tickets, SLA, assignments, responses)
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Ticket from "./models/ticket.model.js";
import { notFound, badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";

class TicketRepository extends BaseRepository {
  constructor() { super(Ticket, { tenantScoped: true }); }
}

const SLA_RULES = {
  critical: { responseHours: 1,  resolutionHours: 24 },
  high:     { responseHours: 4,  resolutionHours: 48 },
  medium:   { responseHours: 24, resolutionHours: 168 }, // 7 days
  low:      { responseHours: 48, resolutionHours: 336 }, // 14 days
};

class TicketService extends BaseService {
  constructor() {
    super(new TicketRepository(), {
      name: "TicketService",
      cachePrefix: "ticket",
      cacheTTL: CacheTTL.TASK_LIST || 30,
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────
  async createTicket({ tenantId, orgId, userId, subject, description, priority = "medium",
    category, channel = "web", tags, files = [],
  }) {
    const count = await this.repository.count({ orgId }, { tenantId });
    const ticketNumber = `TKT-${String(count + 1).padStart(5, "0")}`;

    const slaRule = SLA_RULES[priority] || SLA_RULES.medium;
    const now = Date.now();

    const ticket = await this.repository.create({
      tenantId, orgId, ticketNumber, subject, description,
      priority, category, channel, tags,
      reporter: userId, status: "open",
      sla: {
        responseDeadline:   new Date(now + slaRule.responseHours   * 3_600_000),
        resolutionDeadline: new Date(now + slaRule.resolutionHours * 3_600_000),
      },
    }, { tenantId });

    // Notify reporter via email
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email", _meta: { userId },
      templateName: "ticketCreated",
      templateData: { ticketNumber, subject, priority },
    });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "ticket.created", ticketId: ticket._id, priority, category, tenantId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "ticket.created", resourceType: "ticket",
      resourceId: ticket._id, actor: { id: userId }, tenantId,
    });

    return ticket;
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  async listTickets({ tenantId, orgId, status, priority, assignedTo, userId, page = 1, limit = 20 }) {
    const filter = {};
    if (orgId)      filter.orgId      = orgId;
    if (status)     filter.status     = status;
    if (priority)   filter.priority   = priority;
    if (assignedTo) filter.assignedTo = assignedTo === "me" ? userId : assignedTo;
    return this.repository.paginate({ filter, page: +page, limit: +limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get ──────────────────────────────────────────────────────────────────────
  async getTicketById(id, tenantId) {
    const ticket = await this.cachedFindById(id, { tenantId });
    if (!ticket) throw notFound("Ticket");
    return ticket;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateTicket({ id, updates, tenantId, userId }) {
    const ticket = await this.getTicketById(id, tenantId);
    if (updates.status && updates.status !== ticket.status) {
      if (updates.status === "resolved") updates.resolvedAt = new Date();
      if (updates.status === "closed")   updates.closedAt   = new Date();
    }

    const updated = await this.updateById(id, updates, { tenantId });
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "ticket.updated", ticketId: id, userId, tenantId,
      ...(updates.status ? { statusChange: { from: ticket.status, to: updates.status } } : {}),
    });
    return updated;
  }

  // ── Assign ───────────────────────────────────────────────────────────────────
  async assignTicket({ id, assignedTo, tenantId, assignedBy }) {
    const updated = await this.updateById(id, { assignedTo, status: "in_progress" }, { tenantId });

    emitToUser(String(assignedTo), SocketEvents.NOTIFICATION, {
      type: "ticket.assigned", ticketId: id,
    });
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email", _meta: { userId: String(assignedTo) },
      templateName: "ticketAssigned",
      templateData: { ticketId: id },
    });
    return updated;
  }

  // ── Comment ──────────────────────────────────────────────────────────────────
  async addComment({ id, content, internal = false, tenantId, userId }) {
    if (!content?.trim()) throw badRequest("Comment is required");

    const ticket = await this.getTicketById(id, tenantId);
    const isFirstResponse = !ticket.firstResponseAt && String(userId) !== String(ticket.reporter);

    const updates = { $push: { comments: { userId, content: content.trim(), internal, createdAt: new Date() } } };
    if (isFirstResponse) updates.firstResponseAt = new Date();

    const updated = await this.updateById(id, updates, { tenantId });

    // Notify reporter (unless internal note)
    if (!internal) {
      emitToUser(String(ticket.reporter), SocketEvents.NOTIFICATION, { type: "ticket.reply", ticketId: id });
      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email", _meta: { userId: String(ticket.reporter) },
        templateName: "ticketReply",
        templateData: { ticketNumber: ticket.ticketNumber, subject: ticket.subject, reply: content.trim() },
      });
    }
    return updated;
  }

  // ── Attachment ───────────────────────────────────────────────────────────────
  async addAttachment({ id, file, tenantId }) {
    const result = await uploadBuffer(file.buffer, {
      folder: `teamspot/${tenantId}/tickets/${id}`, resource_type: "auto",
    });
    const attachment = { url: result.secure_url, publicId: result.public_id, filename: file.originalname, mimeType: file.mimetype, bytes: result.bytes };
    await this.updateById(id, { $push: { attachments: attachment } }, { tenantId });
    return attachment;
  }
}

export const ticketService = new TicketService();
