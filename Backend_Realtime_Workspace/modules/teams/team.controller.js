// ============================================================================
// TeamSpot — Team Controller
// ============================================================================
import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, paginated, noContent } from "../../core/utils/api-response.js";
import { teamService } from "./team.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
});

export const createTeam = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const team = await teamService.createTeam(req.body, tenantId, userId);
  return created(res, team, "Team created");
});

export const listTeams = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { page = 1, limit = 20, sort = "-createdAt" } = req.query;
  const filter = { "members.userId": userId, "members.status": "active" };
  const result = await teamService.paginate(filter, {
    tenantId,
    page: Number(page),
    limit: Number(limit),
    sort,
  });
  return paginated(res, result, "Teams retrieved");
});

export const getTeam = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const team = await teamService.getTeamById(req.params.id, tenantId);
  return success(res, team, "Team retrieved");
});

export const updateTeam = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const team = await teamService.updateTeam(req.params.id, req.body, tenantId, userId);
  return success(res, team, "Team updated");
});

export const deleteTeam = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await teamService.deleteTeam(req.params.id, tenantId, userId);
  return noContent(res);
});

export const inviteMember = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { email, role, message } = req.body;
  const team = await teamService.inviteMember(req.params.id, email, role, message, tenantId, userId);
  return success(res, team, "Invite sent");
});

export const acceptInvite = asyncHandler(async (req, res) => {
  const { userId } = ctx(req);
  const userEmail = req.user?.email;
  const result = await teamService.acceptInvite(req.params.token, userId, userEmail);
  return success(res, result, "Invite accepted — welcome to the team");
});

export const removeMember = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await teamService.removeMember(req.params.id, req.params.memberId, tenantId, userId);
  return noContent(res);
});

export const leaveTeam = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await teamService.leaveTeam(req.params.id, userId, tenantId);
  return success(res, null, "You have left the team");
});

export const updateMemberRole = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await teamService.updateMemberRole(
    req.params.id,
    req.params.memberId,
    req.body.role,
    tenantId,
    userId
  );
  return success(res, null, "Member role updated");
});

export const getTeamMembers = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const members = await teamService.getTeamMembers(req.params.id, tenantId);
  return success(res, members, "Members retrieved");
});

export const teamController = {
  createTeam, listTeams, getTeam, updateTeam, deleteTeam,
  inviteMember, acceptInvite, removeMember, leaveTeam,
  updateMemberRole, getTeamMembers,
};
