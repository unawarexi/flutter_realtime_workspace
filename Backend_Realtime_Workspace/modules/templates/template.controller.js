// ============================================================================
// TeamSpot — Template Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created } from "../../core/utils/api-response.js";
import { templateService } from "./template.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
  orgId: req.user?.orgId || null,
});

export const createTemplate = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const result = await templateService.createTemplate({ tenantId, orgId, userId, ...req.body });
  created(res, result, "Template created");
});

export const listTemplates = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { type, status, category, page, limit } = req.query;
  const result = await templateService.listTemplates({ tenantId, type, status, category, page: +page || 1, limit: +limit || 20 });
  success(res, result, "Templates retrieved");
});

export const getTemplate = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await templateService.getTemplate({ id: req.params.id, tenantId });
  success(res, result, "Template retrieved");
});

export const updateTemplate = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await templateService.updateTemplate({ id: req.params.id, tenantId, userId, updates: req.body });
  success(res, result, "Template updated");
});

export const deleteTemplate = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await templateService.deleteTemplate({ id: req.params.id, tenantId });
  success(res, result);
});

export const previewTemplate = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await templateService.previewTemplate({ id: req.params.id, tenantId, sampleData: req.body });
  success(res, result, "Preview generated");
});
