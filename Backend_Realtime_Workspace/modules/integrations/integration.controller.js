// ============================================================================
// TeamSpot — Integration Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created } from "../../core/utils/api-response.js";
import { integrationService } from "./integration.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  orgId:    req.user?.orgId || null,
});

export const createIntegration = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const result = await integrationService.createIntegration({ tenantId, orgId, userId, ...req.body });
  created(res, result, "Integration connected");
});

export const listIntegrations = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { type, page, limit } = req.query;
  const result = await integrationService.listIntegrations({ tenantId, type, page: +page || 1, limit: +limit || 20 });
  success(res, result, "Integrations retrieved");
});

export const getIntegration = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await integrationService.getIntegration({ id: req.params.id, tenantId });
  success(res, result, "Integration retrieved");
});

export const updateIntegration = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await integrationService.updateIntegration({ id: req.params.id, tenantId, updates: req.body });
  success(res, result, "Integration updated");
});

export const deleteIntegration = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await integrationService.deleteIntegration({ id: req.params.id, tenantId });
  success(res, result);
});

export const testIntegration = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await integrationService.testIntegration({ id: req.params.id, tenantId });
  success(res, result);
});

// Inbound webhook — unauthenticated (verified by signature)
export const receiveWebhook = asyncHandler(async (req, res) => {
  const { integrationId } = req.params;
  const tenantId = req.query.tenantId; // passed in webhook URL
  const result = await integrationService.handleWebhook({
    integrationId,
    tenantId,
    headers: req.headers,
    body: req.body,
  });
  success(res, result);
});
