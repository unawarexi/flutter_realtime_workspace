// ============================================================================
// TeamSpot — Chat Service
// Direct messages (1-1) — not channel messages (those are in channels module)
// ============================================================================

import mongoose from "mongoose";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { AppError } from "../../core/errors/app-error.js";
import { createLogger } from "../../observability/logger.js";
import { parsePagination, paginationMeta } from "../../core/utils/pagination.js";

const log = createLogger("ChatService");

// Inline schema for direct messages
const directMessageSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  senderId: { type: String, required: true },
  recipientId: { type: String, required: true },
  content: { type: String, required: true, maxlength: 10000 },
  type: { type: String, enum: ["text", "voice", "file", "image"], default: "text" },
  attachments: [{
    url: String,
    name: String,
    size: Number,
    mimeType: String,
  }],
  read: { type: Boolean, default: false },
  readAt: { type: Date },
  deletedAt: { type: Date },
}, { timestamps: true });

directMessageSchema.index({ tenantId: 1, senderId: 1, recipientId: 1, createdAt: -1 });

const DirectMessage = mongoose.models.DirectMessage || mongoose.model("DirectMessage", directMessageSchema);

export class ChatService {
  async sendMessage({ senderId, recipientId, content, type, attachments, tenantId }) {
    if (!recipientId) throw AppError.badRequest("recipientId is required");
    if (!content && (!attachments || attachments.length === 0)) {
      throw AppError.badRequest("content or attachments are required");
    }

    const msg = await DirectMessage.create({
      tenantId,
      senderId,
      recipientId,
      content: content || "",
      type: type || "text",
      attachments: attachments || [],
    });

    // Fan-out via Kafka for analytics
    await publishEvent("teamspot.analytics.events", senderId, {
      event: "direct_message.sent",
      tenantId,
      senderId,
      recipientId,
      messageId: msg._id.toString(),
      timestamp: new Date().toISOString(),
    }).catch((e) => log.warn("Kafka publish failed", { error: e.message }));

    log.info("Direct message sent", { senderId, recipientId, tenantId });
    return msg;
  }

  async getMessages({ userId, partnerId, tenantId, page = 1, limit = 50 }) {
    if (!partnerId) throw AppError.badRequest("partnerId is required");
    const filter = {
      tenantId,
      deletedAt: { $exists: false },
      $or: [
        { senderId: userId, recipientId: partnerId },
        { senderId: partnerId, recipientId: userId },
      ],
    };
    const total = await DirectMessage.countDocuments(filter);
    const { skip, limit: lim } = parsePagination({ page, limit });
    const messages = await DirectMessage.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(lim)
      .lean();

    // Mark unread messages as read
    await DirectMessage.updateMany(
      { tenantId, recipientId: userId, senderId: partnerId, read: false },
      { read: true, readAt: new Date() }
    );

    return { messages: messages.reverse(), pagination: paginationMeta(page, lim, total) };
  }

  async deleteMessage({ messageId, userId, tenantId }) {
    const msg = await DirectMessage.findOne({ _id: messageId, tenantId });
    if (!msg) throw AppError.notFound("Message");
    if (msg.senderId !== userId) throw AppError.forbidden("You can only delete your own messages");
    await msg.updateOne({ deletedAt: new Date() });
    log.info("Direct message deleted", { messageId, userId });
  }

  async searchMessages({ userId, query, tenantId, page = 1, limit = 20 }) {
    const filter = {
      tenantId,
      deletedAt: { $exists: false },
      content: { $regex: query, $options: "i" },
      $or: [{ senderId: userId }, { recipientId: userId }],
    };
    const total = await DirectMessage.countDocuments(filter);
    const { skip, limit: lim } = parsePagination({ page, limit });
    const messages = await DirectMessage.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(lim)
      .lean();
    return { messages, pagination: paginationMeta(page, lim, total) };
  }
}

export default ChatService;
