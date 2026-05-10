import { asyncHandler } from "../../core/base/base.controller.js";
import { meetingService } from "./meeting.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  userContext: req.user,
});

export const createMeeting = asyncHandler(async (req, res) => {
  const { tenantId, userContext } = ctx(req);
  const meeting = await meetingService.createMeeting({ ...req.body, tenantId, userContext });
  return created(res, meeting, "Meeting scheduled");
});

export const listMeetings = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { workspaceId, status, from, to, page, limit } = req.query;
  const result = await meetingService.listMeetings({ tenantId, userId, workspaceId, status, from, to, page, limit });
  return paginated(res, result, "Meetings retrieved");
});

export const getMeeting = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const meeting = await meetingService.getMeetingById(req.params.id, tenantId);
  return success(res, meeting, "Meeting retrieved");
});

export const updateMeeting = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const meeting = await meetingService.updateMeeting({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, meeting, "Meeting updated");
});

export const cancelMeeting = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const meeting = await meetingService.cancelMeeting({ id: req.params.id, tenantId, userId, reason: req.body.reason });
  return success(res, meeting, "Meeting cancelled");
});

export const rsvp = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const meeting = await meetingService.rsvp({ id: req.params.id, userId, status: req.body.status, tenantId });
  return success(res, meeting, "RSVP recorded");
});

export const joinMeeting = asyncHandler(async (req, res) => {
  const { tenantId, userContext } = ctx(req);
  const result = await meetingService.joinMeeting({ id: req.params.id, tenantId, userContext });
  return success(res, result, "Joined meeting");
});

export const endMeeting = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const meeting = await meetingService.endMeeting({ id: req.params.id, tenantId, userId });
  return success(res, meeting, "Meeting ended");
});

// Compat export
export const meetingController = {
  createMeeting, listMeetings, getMeeting, updateMeeting,
  cancelMeeting, rsvp, joinMeeting, endMeeting,
};
