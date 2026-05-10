// ============================================================================
// TeamSpot — Storage Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created } from "../../core/utils/api-response.js";
import { storageService } from "./storage.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
});

export const uploadFile = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { folder, attachedToType, attachedToId } = req.body;
  const attachTo = attachedToType && attachedToId ? { type: attachedToType, id: attachedToId } : undefined;
  const result = await storageService.uploadFile({ tenantId, userId, file: req.file, folder, attachTo });
  created(res, result, "File uploaded");
});

export const uploadMultiple = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { folder } = req.body;
  const result = await storageService.uploadMultiple({ tenantId, userId, files: req.files, folder });
  created(res, result, "Files uploaded");
});

export const listAssets = asyncHandler(async (req, res) => {
  const { tenantId, userId: _uid } = ctx(req);
  const { folder, resourceType, attachedToType, attachedToId, mine, page, limit } = req.query;
  const userId = mine === "true" ? _uid : undefined;
  const result = await storageService.listAssets({ tenantId, userId, folder, resourceType, attachedToType, attachedToId, page: +page || 1, limit: +limit || 20 });
  success(res, result, "Assets retrieved");
});

export const getAsset = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await storageService.getAsset({ id: req.params.id, tenantId });
  success(res, result, "Asset retrieved");
});

export const deleteAsset = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await storageService.deleteAsset({ id: req.params.id, tenantId, userId });
  success(res, result);
});

export const attachAsset = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { attachedToType, attachedToId } = req.body;
  const result = await storageService.attachAsset({ id: req.params.id, tenantId, attachedToType, attachedToId });
  success(res, result);
});
