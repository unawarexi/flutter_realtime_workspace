// ============================================================================
// TeamSpot — Channel Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, noContent } from "../../core/utils/api-response.js";
import { channelService } from "./channel.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  orgId:    req.user?.orgId || null,
});

export const createChannel = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const result = await channelService.createChannel({ ...req.body, tenantId, orgId, userId });
  created(res, result, "Channel created");
});

export const getChannels = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { workspaceId, type, page, limit } = req.query;
  const result = await channelService.listChannels({ workspaceId, tenantId, userId, type, page: +page || 1, limit: +limit || 50 });
  success(res, result, "Channels retrieved");
});

export const getChannelById = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await channelService.getChannelById(req.params.id, tenantId);
  success(res, result, "Channel retrieved");
});

export const updateChannel = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.updateChannel({ id: req.params.id, updates: req.body, tenantId, userId });
  success(res, result, "Channel updated");
});

export const archiveChannel = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await channelService.archiveChannel({ id: req.params.id, tenantId });
  success(res, result, "Channel archived");
});

export const deleteChannel = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  await channelService.deleteById(req.params.id, { tenantId });
  noContent(res);
});

export const joinChannel = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.joinChannel({ id: req.params.id, userId, tenantId });
  success(res, result, "Joined channel");
});

export const addMember = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { userId: targetUserId, role } = req.body;
  const result = await channelService.addMember({ id: req.params.id, targetUserId, role, tenantId });
  success(res, result, "Member added");
});

export const removeMember = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await channelService.removeMember({ id: req.params.id, targetUserId: req.params.userId, tenantId });
  success(res, result, "Member removed");
});

export const getMessages = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { threadId, before, after, page, limit } = req.query;
  const result = await channelService.getMessages({ channelId: req.params.id, tenantId, threadId, before, after, page: +page || 1, limit: +limit || 50 });
  success(res, result, "Messages retrieved");
});

export const sendMessage = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { content, threadId, mentions } = req.body;
  const result = await channelService.sendMessage({
    channelId: req.params.id,
    senderId: userId,
    content, threadId, tenantId,
    files: req.files || [],
    mentions: mentions || [],
  });
  created(res, result, "Message sent");
});

export const editMessage = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.editMessage({ messageId: req.params.messageId, channelId: req.params.id, senderId: userId, content: req.body.content, tenantId });
  success(res, result, "Message edited");
});

export const deleteMessage = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.deleteMessage({ messageId: req.params.messageId, channelId: req.params.id, userId, tenantId });
  success(res, result);
});

export const addReaction = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.addReaction({ messageId: req.params.messageId, channelId: req.params.id, userId, emoji: req.body.emoji, tenantId });
  success(res, result, "Reaction added");
});

export const setTyping = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const result = await channelService.setTyping({ channelId: req.params.id, userId, isTyping: req.body.isTyping });
  success(res, result);
});

export const markRead = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await channelService.markRead({ channelId: req.params.id, userId, tenantId });
  success(res, result, "Marked as read");
});

export const channelController = {
  createChannel, getChannels, getChannelById, updateChannel,
  archiveChannel, deleteChannel, joinChannel,
  addMember, removeMember,
  getMessages, sendMessage, editMessage, deleteMessage,
  addReaction, setTyping, markRead,
};
