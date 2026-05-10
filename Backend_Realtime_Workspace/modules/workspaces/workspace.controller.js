// ============================================================================
// TeamSpot — Workspace Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, noContent } from "../../core/utils/api-response.js";
import { workspaceService } from "./workspace.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  orgId:    req.user?.orgId || req.body?.orgId || req.query?.orgId || null,
});

export const createWorkspace = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const result = await workspaceService.createWorkspace({ ...req.body, tenantId, orgId, userId });
  created(res, result, "Workspace created");
});

export const getWorkspaces = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const { page, limit } = req.query;
  const result = await workspaceService.listWorkspaces({ tenantId, orgId, userId, page: +page || 1, limit: +limit || 20 });
  success(res, result, "Workspaces retrieved");
});

export const getWorkspaceById = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await workspaceService.getWorkspaceById(req.params.id, tenantId);
  success(res, result, "Workspace retrieved");
});

export const updateWorkspace = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await workspaceService.updateWorkspace({ id: req.params.id, updates: req.body, tenantId, userId });
  success(res, result, "Workspace updated");
});

export const archiveWorkspace = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await workspaceService.archiveWorkspace({ id: req.params.id, tenantId, userId });
  success(res, result, "Workspace archived");
});

export const deleteWorkspace = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  await workspaceService.deleteById(req.params.id, { tenantId });
  noContent(res);
});

export const addMember = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { userId: targetUserId, role } = req.body;
  const result = await workspaceService.addMember({ id: req.params.id, targetUserId, role, tenantId, actorId: userId });
  success(res, result, "Member added");
});

export const removeMember = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await workspaceService.removeMember({ id: req.params.id, targetUserId: req.params.userId, tenantId, actorId: userId });
  success(res, result, "Member removed");
});

export const updateMemberRole = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await workspaceService.updateMemberRole({ id: req.params.id, targetUserId: req.params.userId, role: req.body.role, tenantId });
  success(res, result, "Member role updated");
});

export const getMembers = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const { page, limit } = req.query;
  const result = await workspaceService.getMembers({ id: req.params.id, tenantId, page: +page || 1, limit: +limit || 50 });
  success(res, result, "Members retrieved");
});

// Legacy compat for routes using workspaceController.method
export const workspaceController = {
  createWorkspace, getWorkspaces, getWorkspaceById,
  updateWorkspace, deleteWorkspace, addMember,
  removeMember, getMembers, updateMemberRole, archiveWorkspace,
};
