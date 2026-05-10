// ============================================================================
// TeamSpot — Feedback Service (user feedback + in-app responses + NPS)
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Feedback from "./models/feedback.model.js";
import { notFound } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";
import { SocketEvents } from "../../config/constants.js";

class FeedbackRepository extends BaseRepository {
  constructor() { super(Feedback, { tenantScoped: true }); }
}

class FeedbackService extends BaseService {
  constructor() {
    super(new FeedbackRepository(), {
      name: "FeedbackService",
      cachePrefix: "feedback",
      cacheTTL: CacheTTL.PROJECT || 60,
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────
  async createFeedback({ tenantId, userId, type, category, subject, body, rating, files = [] }) {
    const attachments = [];
    for (const file of files) {
      const result = await uploadBuffer(file.buffer, {
        folder: `teamspot/${tenantId}/feedback`, resource_type: "auto",
      });
      attachments.push({ url: result.secure_url, filename: file.originalname });
    }

    const feedback = await this.repository.create({
      tenantId, userId, type, category, subject, body, rating,
      attachments, status: "new",
    }, { tenantId });

    // Queue analytics
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "feedback.submitted", feedbackId: feedback._id, category, rating, tenantId,
    });

    // Notify admins via RabbitMQ notification queue
    await publishToQueue(RabbitQueues.NOTIFICATION, {
      channel: "admin_notification", tenantId,
      templateName: "newFeedback",
      templateData: { subject, category, type },
    });

    return feedback;
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  async listFeedback({ tenantId, type, category, status, page = 1, limit = 20 }) {
    const filter = {};
    if (type)     filter.type     = type;
    if (category) filter.category = category;
    if (status)   filter.status   = status;
    return this.repository.paginate({ filter, page: +page, limit: +limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get ──────────────────────────────────────────────────────────────────────
  async getFeedbackById(id, tenantId) {
    const fb = await this.cachedFindById(id, { tenantId });
    if (!fb) throw notFound("Feedback");
    return fb;
  }

  // ── Update Status ─────────────────────────────────────────────────────────────
  async updateStatus({ id, status, tenantId }) {
    return this.updateById(id, { status }, { tenantId });
  }

  // ── Respond ───────────────────────────────────────────────────────────────────
  async respondToFeedback({ id, content, tenantId, responderId }) {
    const fb = await this.getFeedbackById(id, tenantId);
    const updated = await this.updateById(id, {
      response: { content, respondedBy: responderId, respondedAt: new Date() },
      status: "acknowledged",
    }, { tenantId });

    // Notify submitter
    emitToUser(String(fb.userId), SocketEvents.NOTIFICATION, { type: "feedback.responded", feedbackId: id });
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email", _meta: { userId: String(fb.userId) },
      templateName: "feedbackResponse",
      templateData: { subject: fb.subject, response: content },
    });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "feedback.responded", feedbackId: id, responderId, tenantId,
    });
    return updated;
  }
}

export const feedbackService = new FeedbackService();
