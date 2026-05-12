// ============================================================================
// TeamSpot — Whiteboard Controller
// ============================================================================
import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, paginated, noContent } from "../../core/utils/api-response.js";
import { whiteboardService } from "./whiteboard.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
});

export const createWhiteboard = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const board = await whiteboardService.createWhiteboard(req.body, tenantId, userId);
  return created(res, board, "Whiteboard created");
});

export const listWhiteboards = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { workspaceId, projectId, page = 1, limit = 20, sort = "-createdAt" } = req.query;
  const filter = { deletedAt: null };
  if (workspaceId) filter.workspaceId = workspaceId;
  if (projectId) filter.projectId = projectId;
  const result = await whiteboardService.paginate(filter, {
    tenantId,
    page: Number(page),
    limit: Number(limit),
    sort,
  });
  return paginated(res, result, "Whiteboards retrieved");
});

export const getWhiteboard = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const board = await whiteboardService.getWhiteboardById(req.params.id, tenantId);
  return success(res, board, "Whiteboard retrieved");
});

export const updateState = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const board = await whiteboardService.updateState(req.params.id, req.body.state, tenantId, userId);
  return success(res, board, "Whiteboard state updated");
});

export const broadcastCursor = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await whiteboardService.broadcastCursor(req.params.id, req.body.cursor, tenantId, userId);
  return success(res, null, "Cursor broadcast");
});

export const addCollaborator = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const board = await whiteboardService.addCollaborator(
    req.params.id, req.params.userId, tenantId, userId
  );
  return success(res, board, "Collaborator added");
});

export const removeCollaborator = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const board = await whiteboardService.removeCollaborator(
    req.params.id, req.params.userId, tenantId, userId
  );
  return success(res, board, "Collaborator removed");
});

export const updateThumbnail = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const board = await whiteboardService.updateThumbnail(
    req.params.id, req.body.thumbnailUrl, tenantId
  );
  return success(res, board, "Thumbnail updated");
});

export const deleteWhiteboard = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await whiteboardService.deleteWhiteboard(req.params.id, tenantId, userId);
  return noContent(res);
});

export const whiteboardController = {
  createWhiteboard, listWhiteboards, getWhiteboard, updateState,
  broadcastCursor, addCollaborator, removeCollaborator,
  updateThumbnail, deleteWhiteboard,
};
