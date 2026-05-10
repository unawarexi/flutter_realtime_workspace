// ============================================================================
// TeamSpot — Channel Service (full infrastructure integration)
// Real-time messaging via WebSocket, Kafka fan-out, Redis typing indicators
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Channel, { Message } from "./models/channel.model.js";
import { notFound, conflict, forbidden } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToChannel, emitToUser, emitToWorkspace } from "../../infrastructure/websocket/websocket.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("ChannelService");

class ChannelRepository extends BaseRepository {
  constructor() { super(Channel, { tenantScoped: true }); }
}

class MessageRepository extends BaseRepository {
  constructor() { super(Message, { tenantScoped: true }); }
}

class ChannelService extends BaseService {
  constructor() {
    super(new ChannelRepository(), {
      name: "ChannelService",
      cachePrefix: "channel",
      cacheTTL: CacheTTL.CHANNEL_LIST || 60,
    });
    this.messageRepository = new MessageRepository();
  }

  // Create Channel
  async createChannel({ name, type = "public", description, topic, workspaceId, settings, tenantId, orgId, userId }) {
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/, "");
    const existing = await this.repository.findOne({ tenantId, workspaceId, slug });
    if (existing) throw conflict("A channel with this name already exists in this workspace");

    const channel = await this.repository.create({
      name, slug, type, description, topic, workspaceId,
      settings: settings || {},
      tenantId, orgId,
      createdBy: userId,
      members: [{ userId, role: "admin", joinedAt: new Date() }],
      memberCount: 1,
    });

    emitToWorkspace(workspaceId, SocketEvents.PROJECT_CREATED, { entity: "channel", channelId: channel._id, name });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "channel.created",
      channelId: channel._id,
      workspaceId, tenantId, orgId, userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "channel.created", resourceType: "channel",
      resourceId: channel._id, actor: { id: userId }, tenantId,
    });

    eventBus.publish(DomainEvents.CHANNEL_CREATED, { channelId: channel._id, workspaceId, tenantId });
    return channel;
  }

  // List channels in workspace
  async listChannels({ workspaceId, tenantId, userId, type, page = 1, limit = 50 }) {
    const filter = {
      tenantId, workspaceId,
      status: { $ne: "deleted" },
      $or: [{ type: "public" }, { "members.userId": userId }],
    };
    if (type) filter.type = type;
    return this.repository.paginate({ filter, page, limit, sort: { name: 1 } }, { tenantId });
  }

  // Get by ID
  async getChannelById(id, tenantId) {
    const channel = await this.cachedFindById(id, { tenantId });
    if (!channel || channel.status === "deleted") throw notFound("Channel");
    return channel;
  }

  // Update
  async updateChannel({ id, updates, tenantId }) {
    await this.getChannelById(id, tenantId);
    const updated = await this.updateById(id, updates, { tenantId });
    emitToChannel(id, SocketEvents.WORKSPACE_UPDATED, { channelId: id, updates });
    return updated;
  }

  // Archive
  async archiveChannel({ id, tenantId }) {
    await this.getChannelById(id, tenantId);
    return this.updateById(id, { status: "archived", archivedAt: new Date() }, { tenantId });
  }

  // Add member
  async addMember({ id, targetUserId, role = "member", tenantId }) {
    const channel = await this.getChannelById(id, tenantId);
    if (channel.members.some(m => m.userId.toString() === targetUserId)) throw conflict("User is already a member");
    const updated = await this.updateById(id, {
      $push: { members: { userId: targetUserId, role, joinedAt: new Date() } },
      $inc: { memberCount: 1 },
    }, { tenantId });
    emitToChannel(id, SocketEvents.MEMBER_JOINED, { channelId: id, userId: targetUserId });
    emitToUser(targetUserId, SocketEvents.WORKSPACE_UPDATED, { action: "channel_added", channelId: id });
    return updated;
  }

  // Remove member
  async removeMember({ id, targetUserId, tenantId }) {
    await this.getChannelById(id, tenantId);
    const updated = await this.updateById(id, {
      $pull: { members: { userId: targetUserId } },
      $inc: { memberCount: -1 },
    }, { tenantId });
    emitToUser(targetUserId, SocketEvents.WORKSPACE_UPDATED, { action: "channel_removed", channelId: id });
    return updated;
  }

  // Join public channel
  async joinChannel({ id, userId, tenantId }) {
    const channel = await this.getChannelById(id, tenantId);
    if (channel.type === "private") throw forbidden("This is a private channel");
    return this.addMember({ id, targetUserId: userId, role: "member", tenantId });
  }

  // Send message
  async sendMessage({ channelId, senderId, content, threadId, tenantId, files = [], mentions = [] }) {
    await this.getChannelById(channelId, tenantId);

    const attachments = [];
    for (const file of files) {
      if (file?.buffer) {
        const up = await uploadBuffer(file.buffer, { folder: `teamspot/${tenantId}/channels/${channelId}`, resourceType: "auto" });
        attachments.push({ url: up.url, publicId: up.publicId, filename: file.originalname, mimeType: file.mimetype, bytes: up.bytes || 0 });
      }
    }

    const message = await this.messageRepository.create({
      channelId, senderId, content, threadId, attachments, mentions, tenantId,
    });

    await this.updateById(channelId, { $inc: { messageCount: 1 }, lastMessageAt: new Date() }, { tenantId });

    const r = await getRedisClient();
    await r.del(`typing:channel:${channelId}:${senderId}`);

    emitToChannel(channelId, SocketEvents.CHANNEL_MESSAGE, {
      channelId, messageId: message._id, senderId, content, attachments, threadId, createdAt: message.createdAt,
    });

    await publishEvent(KafkaTopics.CHANNEL_MESSAGES, tenantId, {
      type: "message.sent",
      messageId: message._id,
      channelId, senderId, tenantId,
      hasMentions: mentions.length > 0,
    });

    for (const mentionedUserId of mentions) {
      await publishToQueue(RabbitQueues.NOTIFICATION, {
        channel: "push", userId: mentionedUserId,
        title: "You were mentioned",
        body: (content || "").substring(0, 80),
        data: { type: "mention", channelId, messageId: message._id.toString() },
      });
    }

    eventBus.publish(DomainEvents.MESSAGE_SENT, { messageId: message._id, channelId, senderId, tenantId });
    return message;
  }

  // Get messages
  async getMessages({ channelId, tenantId, threadId, before, after, page = 1, limit = 50 }) {
    await this.getChannelById(channelId, tenantId);
    const filter = { channelId, tenantId, deleted: { $ne: true } };
    if (threadId) filter.threadId = threadId;
    if (before)   filter.createdAt = { ...filter.createdAt, $lt: new Date(before) };
    if (after)    filter.createdAt = { ...filter.createdAt, $gt: new Date(after) };
    return this.messageRepository.paginate({ filter, page, limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // Edit message
  async editMessage({ messageId, channelId, senderId, content, tenantId }) {
    const msg = await this.messageRepository.findById(messageId, { tenantId });
    if (!msg) throw notFound("Message");
    if (msg.senderId.toString() !== senderId) throw forbidden("Cannot edit another user\'s message");
    const updated = await this.messageRepository.updateById(messageId, {
      content, edited: true, editedAt: new Date(),
    }, { tenantId });
    emitToChannel(channelId, SocketEvents.CHANNEL_MESSAGE, { type: "edited", messageId, channelId, content });
    return updated;
  }

  // Delete message
  async deleteMessage({ messageId, channelId, userId, tenantId }) {
    const msg = await this.messageRepository.findById(messageId, { tenantId });
    if (!msg) throw notFound("Message");
    if (msg.senderId.toString() !== userId) throw forbidden("Cannot delete another user\'s message");
    await this.messageRepository.updateById(messageId, { deleted: true, deletedAt: new Date() }, { tenantId });
    await this.updateById(channelId, { $inc: { messageCount: -1 } }, { tenantId });
    emitToChannel(channelId, SocketEvents.CHANNEL_MESSAGE, { type: "deleted", messageId, channelId });
    return { message: "Message deleted" };
  }

  // Add reaction
  async addReaction({ messageId, channelId, userId, emoji, tenantId }) {
    const msg = await this.messageRepository.findById(messageId, { tenantId });
    if (!msg) throw notFound("Message");
    const reactionIdx = (msg.reactions || []).findIndex(r => r.emoji === emoji);
    let update;
    if (reactionIdx > -1) {
      const alreadyReacted = (msg.reactions[reactionIdx].users || []).map(String).includes(String(userId));
      update = alreadyReacted
        ? { $pull: { [`reactions.${reactionIdx}.users`]: userId } }
        : { $push: { [`reactions.${reactionIdx}.users`]: userId } };
    } else {
      update = { $push: { reactions: { emoji, users: [userId] } } };
    }
    const updated = await this.messageRepository.updateById(messageId, update, { tenantId });
    emitToChannel(channelId, SocketEvents.CHANNEL_MESSAGE, { type: "reaction", messageId, emoji, userId });
    return updated;
  }

  // Typing indicator
  async setTyping({ channelId, userId, isTyping }) {
    const r = await getRedisClient();
    const key = `typing:channel:${channelId}:${userId}`;
    if (isTyping) { await r.set(key, "1", "EX", 8); } else { await r.del(key); }
    emitToChannel(channelId, SocketEvents.CHANNEL_TYPING, { channelId, userId, isTyping });
    return { ok: true };
  }

  // Mark read
  async markRead({ channelId, userId, tenantId }) {
    return this.updateById(channelId, {
      $set: { "members.$[m].lastRead": new Date() },
    }, { tenantId, arrayFilters: [{ "m.userId": userId }] });
  }
}

export const channelService = new ChannelService();
