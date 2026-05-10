import { asyncHandler } from "../../core/base/base.controller.js";
import { identityService } from "./identity.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  orgId:    req.user?.orgId || null,
});

// ── Roles ────────────────────────────────────────────────────────────────────
export const createRole = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const role = await identityService.createRole({ ...req.body, tenantId, userId, orgId });
  return created(res, role, "Role created");
});

export const listRoles = asyncHandler(async (req, res) => {
  const { tenantId, orgId } = ctx(req);
  const result = await identityService.listRoles({ tenantId, orgId, ...req.query });
  return paginated(res, result, "Roles retrieved");
});

export const updateRole = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const role = await identityService.updateRole({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, role, "Role updated");
});

export const deleteRole = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await identityService.deleteRole({ id: req.params.id, tenantId, userId });
  return noContent(res);
});

// ── Policies ─────────────────────────────────────────────────────────────────
export const createPolicy = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const policy = await identityService.createPolicy({ ...req.body, tenantId, userId, orgId });
  return created(res, policy, "Policy created");
});

export const listPolicies = asyncHandler(async (req, res) => {
  const { tenantId, orgId } = ctx(req);
  const result = await identityService.listPolicies({ tenantId, orgId, ...req.query });
  return paginated(res, result, "Policies retrieved");
});

export const updatePolicy = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const policy = await identityService.updatePolicy({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, policy, "Policy updated");
});

export const deletePolicy = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await identityService.deletePolicy({ id: req.params.id, tenantId, userId });
  return noContent(res);
});

export const identityController = {
  createRole, listRoles, updateRole, deleteRole,
  createPolicy, listPolicies, updatePolicy, deletePolicy,
};
