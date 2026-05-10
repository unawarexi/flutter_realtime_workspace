import { asyncHandler } from "../../core/base/base.controller.js";
import { adminService } from "./admin.service.js";
import { success, paginated } from "../../core/utils/api-response.js";

const adminId = (req) => req.user?._id?.toString() || req.user?.id;

export const listTenants = asyncHandler(async (req, res) => {
  const result = await adminService.listTenants(req.query);
  return paginated(res, result, "Tenants retrieved");
});

export const updateTenantStatus = asyncHandler(async (req, res) => {
  const org = await adminService.updateTenantStatus({
    id: req.params.id, adminUserId: adminId(req),
    status: req.body.status, reason: req.body.reason,
  });
  return success(res, org, "Tenant status updated");
});

export const getSystemStats = asyncHandler(async (req, res) => {
  const stats = await adminService.getSystemStats();
  return success(res, stats, "System stats retrieved");
});

export const listUsers = asyncHandler(async (req, res) => {
  const result = await adminService.listUsers({ tenantId: req.params.tenantId, ...req.query });
  return paginated(res, result, "Users retrieved");
});

export const suspendUser = asyncHandler(async (req, res) => {
  const user = await adminService.suspendUser({
    userId: req.params.userId, adminUserId: adminId(req),
    tenantId: req.params.tenantId, reason: req.body.reason,
  });
  return success(res, user, "User suspended");
});

export const impersonateUser = asyncHandler(async (req, res) => {
  const result = await adminService.impersonateUser({
    adminUserId: adminId(req), targetUserId: req.body.userId,
  });
  return success(res, result, "Impersonation token issued");
});

export const setFeatureFlag = asyncHandler(async (req, res) => {
  const result = await adminService.setFeatureFlag({
    tenantId: req.params.tenantId, adminUserId: adminId(req),
    flag: req.body.flag, enabled: req.body.enabled,
  });
  return success(res, result, "Feature flag updated");
});

export const getFeatureFlags = asyncHandler(async (req, res) => {
  const flags = await adminService.getFeatureFlags(req.params.tenantId);
  return success(res, flags, "Feature flags retrieved");
});

export const adminController = {
  listTenants, updateTenantStatus, getSystemStats,
  listUsers, suspendUser, impersonateUser,
  setFeatureFlag, getFeatureFlags,
};
