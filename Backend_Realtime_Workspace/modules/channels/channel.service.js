import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Channel, { Message } from "./models/channel.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";

class ChannelRepository extends BaseRepository {
  constructor() {
    super(Channel, { tenantScoped: true });
  }
}

class MessageRepository extends BaseRepository {
  constructor() {
    super(Message, { tenantScoped: true });
  }
}

class ChannelService extends BaseService {
  constructor() {
    super(new ChannelRepository(), {
      name: "ChannelService",
      cachePrefix: "channel",
      cacheTTL: 1800,
    });
    this.messageRepository = new MessageRepository();
  }

  async createChannel(data, tenantId, orgId, userId) {
    const slug = data.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const existing = await this.repository.findOne({ workspaceId: data.workspaceId, slug }, { tenantId });
    
    if (existing) {
      throw new AppError(HttpStatus.CONFLICT, "Channel with this name already exists in this workspace", "E5005");
    }

    const newChannel = await this.repository.create({
      ...data,
      slug,
      tenantId,
      orgId,
      createdBy: userId,
      members: [{ userId, role: "admin" }]
    }, { tenantId });

    this.emit("channel.created", { channelId: newChannel._id, tenantId, orgId });
    return newChannel;
  }

  async getChannelById(id, tenantId) {
    const channel = await this.cachedFindById(id, { tenantId });
    if (!channel) throw new AppError(HttpStatus.NOT_FOUND, "Channel not found", "E3012");
    return channel;
  }

  async updateChannel(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("channel.updated", { channelId: id, tenantId });
    return updated;
  }

  async addMember(id, userId, role, tenantId) {
    const updated = await this.updateById(id, {
      $addToSet: { members: { userId, role: role || "member", joinedAt: new Date() } },
      $inc: { memberCount: 1 }
    }, { tenantId });
    this.emit("channel.member_added", { channelId: id, tenantId, userId });
    return updated;
  }

  async removeMember(id, userId, tenantId) {
    const updated = await this.updateById(id, {
      $pull: { members: { userId } },
      $inc: { memberCount: -1 }
    }, { tenantId });
    this.emit("channel.member_removed", { channelId: id, tenantId, userId });
    return updated;
  }

  // --- Messages ---
  async sendMessage(channelId, senderId, content, threadId, tenantId, files = []) {
    // Basic channel existence check
    await this.getChannelById(channelId, tenantId);

    const messageData = {
      channelId,
      tenantId,
      senderId,
      content,
      threadId,
      attachments: []
    };

    if (files && files.length > 0) {
      for (const file of files) {
        const uploadResult = await uploadBuffer(file.buffer, {
          folder: `teamspot/channels/${channelId}`,
          resourceType: "auto"
        });
        messageData.attachments.push({
          url: uploadResult.url,
          publicId: uploadResult.publicId,
          filename: file.originalname,
          mimeType: file.mimetype,
          bytes: uploadResult.bytes
        });
      }
    }

    const newMessage = await this.messageRepository.create(messageData, { tenantId });

    // Update channel stats
    await this.updateById(channelId, {
      $inc: { messageCount: 1 },
      lastMessageAt: new Date()
    }, { tenantId });

    // Emit event for real-time delivery via socket.io/livekit data channel
    this.emit("message.created", { channelId, messageId: newMessage._id, tenantId });

    return newMessage;
  }

  async getMessages(channelId, filter, pagination, tenantId) {
    const query = { channelId, ...filter };
    return this.messageRepository.paginate(query, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: pagination.sort || { createdAt: -1 }
    });
  }
}

export const channelService = new ChannelService();
