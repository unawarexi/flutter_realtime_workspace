// ============================================================================
// TeamSpot — Chat Controller
// Direct message HTTP handlers
// ============================================================================

import { ChatService } from "./chat.service.js";
import { success, created } from "../../core/utils/api-response.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const chatService = new ChatService();

// POST /communication/messages
export const sendMessage = asyncHandler(async (req, res) => {
  const { recipientId, content, type, attachments } = req.body;
  const msg = await chatService.sendMessage({
    senderId: req.user.uid,
    recipientId,
    content,
    type,
    attachments,
    tenantId: req.tenant?.tenantId,
  });
  return created(res, msg, "Message sent");
});

// GET /communication/messages?partnerId=&page=&limit=
export const getMessages = asyncHandler(async (req, res) => {
  const { partnerId, page = 1, limit = 50 } = req.query;
  const result = await chatService.getMessages({
    userId: req.user.uid,
    partnerId,
    tenantId: req.tenant?.tenantId,
    page: Number(page),
    limit: Number(limit),
  });
  return success(res, result.messages, undefined, result.pagination);
});

// DELETE /communication/messages/:id
export const deleteMessage = asyncHandler(async (req, res) => {
  await chatService.deleteMessage({
    messageId: req.params.id,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, null, "Message deleted");
});

// GET /communication/messages/search?q=&page=&limit=
export const searchMessages = asyncHandler(async (req, res) => {
  const { q, page = 1, limit = 20 } = req.query;
  const result = await chatService.searchMessages({
    userId: req.user.uid,
    query: q || "",
    tenantId: req.tenant?.tenantId,
    page: Number(page),
    limit: Number(limit),
  });
  return success(res, result.messages, undefined, result.pagination);
});
