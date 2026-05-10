import { asyncHandler } from "../../core/base/base.controller.js";
import { organizationService } from "./organization.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
});

export const createOrganization = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const org = await organizationService.createOrganization(req.body, userId);
  return created(res, org, "Organization created");
});

export const listOrganizations = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const { page = 1, limit = 20 } = req.query;
  const result = await organizationService.repository.paginate(
    { filter: { owner: userId }, page: +page, limit: +limit, sort: { createdAt: -1 } }, {}
  );
  return paginated(res, result, "Organizations retrieved");
});

export const getOrganization = asyncHandler(async (req, res) => {
  const org = await organizationService.getOrganizationById(req.params.id);
  return success(res, org, "Organization retrieved");
});

export const updateOrganization = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const org = await organizationService.updateOrganization(req.params.id, req.body, userId);
  return success(res, org, "Organization updated");
});

export const updateSettings = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const org = await organizationService.updateSettings(req.params.id, req.body, userId);
  return success(res, org, "Settings updated");
});

export const updateSSO = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const org = await organizationService.updateSSO(req.params.id, req.body, userId);
  return success(res, org, "SSO configuration updated");
});

export const inviteMember = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await organizationService.inviteMember({
    orgId: req.params.id, tenantId, invitedBy: userId, ...req.body,
  });
  return success(res, result, "Invitation sent");
});

export const acceptInvite = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const result = await organizationService.acceptInvite(req.params.token, userId, req.user.email);
  return success(res, result, "Invite accepted");
});

export const organizationController = {
  createOrganization, listOrganizations, getOrganization, updateOrganization,
  updateSettings, updateSSO, inviteMember, acceptInvite,
};
