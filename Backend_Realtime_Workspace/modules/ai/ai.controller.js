// ============================================================================
// TeamSpot — AI Controller
// HTTP handlers delegating to ai.service.js and agent/ subsystem
// ============================================================================

import { AIService } from "./ai.service.js";
import { success, created, paginated, error } from "../../core/utils/api-response.js";
import { AppError } from "../../core/errors/app-error.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("AIController");
const aiService = new AIService();

// POST /ai/chat
export const chat = asyncHandler(async (req, res) => {
  const { input, workspaceId, conversationId, agentType, context } = req.body;
  if (!input || typeof input !== "string" || input.trim() === "") {
    throw AppError.badRequest("input is required and must be a non-empty string");
  }

  const stream = req.query.stream === "true";
  const payload = {
    input: input.trim(),
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
    workspaceId,
    conversationId,
    agentType,
    context,
    permissions: req.user.permissionsLevel,
  };

  if (stream) {
    // SSE streaming response
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no");
    payload.stream = true;
    payload.res = res;
    await aiService.handleChat(payload);
    // stream ends inside service
    return;
  }

  const result = await aiService.handleChat(payload);
  return success(res, result, "AI response generated");
});

// GET /ai/conversations
export const getConversations = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, workspaceId, agentType } = req.query;
  const result = await aiService.listConversations({
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
    workspaceId,
    agentType,
    page: Number(page),
    limit: Number(limit),
  });
  return paginated(res, result.conversations, result.pagination);
});

// GET /ai/conversations/:id
export const getConversation = asyncHandler(async (req, res) => {
  const conversation = await aiService.getConversation({
    id: req.params.id,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  if (!conversation) throw AppError.notFound("Conversation");
  return success(res, conversation);
});

// DELETE /ai/conversations/:id
export const deleteConversation = asyncHandler(async (req, res) => {
  await aiService.deleteConversation({
    id: req.params.id,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, null, "Conversation deleted");
});

// POST /ai/rag/query
export const ragQuery = asyncHandler(async (req, res) => {
  const { query, workspaceId, limit = 10, filters } = req.body;
  if (!query) throw AppError.badRequest("query is required");
  const results = await aiService.ragQuery({
    query,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
    workspaceId,
    limit: Number(limit),
    filters,
  });
  return success(res, results);
});

// POST /ai/rag/ingest
export const ragIngest = asyncHandler(async (req, res) => {
  const { content, metadata, strategy } = req.body;
  if (!content) throw AppError.badRequest("content is required");
  const result = await aiService.ragIngest({
    content,
    metadata: { ...metadata, userId: req.user.uid, tenantId: req.tenant?.tenantId },
    strategy,
  });
  return created(res, result, "Document ingested into RAG pipeline");
});

// GET /ai/rag/status
export const ragStatus = asyncHandler(async (req, res) => {
  const status = await aiService.ragStatus({ tenantId: req.tenant?.tenantId });
  return success(res, status);
});

// GET /ai/tools
export const listTools = asyncHandler(async (req, res) => {
  const tools = await aiService.listTools({ permissions: req.user.permissionsLevel });
  return success(res, tools);
});

// POST /ai/tools/:name/execute
export const executeTool = asyncHandler(async (req, res) => {
  const { name } = req.params;
  const { args } = req.body;
  const result = await aiService.executeTool({
    name,
    args,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
    permissions: req.user.permissionsLevel,
  });
  return success(res, result, `Tool "${name}" executed`);
});

// POST /ai/summarize
export const summarize = asyncHandler(async (req, res) => {
  const { content, type, maxLength } = req.body;
  if (!content) throw AppError.badRequest("content is required");
  const result = await aiService.summarize({
    content,
    type,
    maxLength,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, result);
});
