// ============================================================================
// TeamSpot — Document Controller
// ============================================================================
import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, paginated, noContent } from "../../core/utils/api-response.js";
import { documentService } from "./document.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
  orgId: req.user?.orgId || req.user?.organizationId || null,
});

export const uploadDocument = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const doc = await documentService.uploadDocument(req.body, req.file, tenantId, orgId, userId);
  return created(res, doc, "Document uploaded");
});

export const listDocuments = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { workspaceId, projectId, type, page = 1, limit = 20, sort = "-createdAt" } = req.query;
  const filter = { status: "active" };
  if (workspaceId) filter.workspaceId = workspaceId;
  if (projectId) filter.projectId = projectId;
  if (type) filter.type = type;
  const result = await documentService.paginate(filter, {
    tenantId,
    page: Number(page),
    limit: Number(limit),
    sort,
  });
  return paginated(res, result, "Documents retrieved");
});

export const getDocument = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const doc = await documentService.getDocumentById(req.params.id, tenantId);
  return success(res, doc, "Document retrieved");
});

export const updateDocument = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const doc = await documentService.updateDocument(req.params.id, req.body, tenantId, userId);
  return success(res, doc, "Document updated");
});

export const uploadNewVersion = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  if (!req.file) return success(res, null, "No file provided");
  const doc = await documentService.uploadNewVersion(req.params.id, req.file, tenantId, userId);
  return created(res, doc, "New version uploaded");
});

export const deleteDocument = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await documentService.deleteDocument(req.params.id, tenantId, userId);
  return noContent(res);
});

export const shareDocument = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { targetUserId, permission } = req.body;
  const result = await documentService.shareDocument(
    req.params.id, targetUserId, permission, tenantId, userId
  );
  return success(res, result, "Document shared");
});

export const markIndexed = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { embeddingIds, chunkCount } = req.body;
  const doc = await documentService.markIndexed(req.params.id, tenantId, embeddingIds, chunkCount);
  return success(res, doc, "Document marked as indexed");
});

export const documentController = {
  uploadDocument, listDocuments, getDocument, updateDocument,
  uploadNewVersion, deleteDocument, shareDocument, markIndexed,
};
