// ============================================================================
// TeamSpot — Schedule Controller
// ============================================================================
import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, paginated, noContent } from "../../core/utils/api-response.js";
import { scheduleService } from "./schedule.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
});

export const createEvent = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await scheduleService.createEvent(req.body, tenantId, userId);
  return created(res, result, result.conflicts ? "Event created (conflicts detected)" : "Event created");
});

export const listEvents = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { workspaceId, teamId, type, status, page = 1, limit = 50, sort = "startTime" } = req.query;
  const filter = {};
  if (workspaceId) filter.workspaceId = workspaceId;
  if (teamId) filter.teamId = teamId;
  if (type) filter.type = type;
  if (status) filter.status = status;
  // Default: only show events where user is creator or attendee
  filter.$or = [{ createdBy: userId }, { "attendees.userId": userId }];
  const result = await scheduleService.paginate(filter, {
    tenantId,
    page: Number(page),
    limit: Number(limit),
    sort,
  });
  return paginated(res, result, "Events retrieved");
});

export const getEvent = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const event = await scheduleService.getEventById(req.params.id, tenantId);
  return success(res, event, "Event retrieved");
});

export const updateEvent = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const event = await scheduleService.updateEvent(req.params.id, req.body, tenantId, userId);
  return success(res, event, "Event updated");
});

export const cancelEvent = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await scheduleService.cancelEvent(req.params.id, tenantId, userId, req.body.reason);
  return success(res, null, "Event cancelled");
});

export const deleteEvent = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await scheduleService.deleteEvent(req.params.id, tenantId, userId);
  return noContent(res);
});

export const getCalendarView = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { startDate, endDate } = req.query;
  const events = await scheduleService.getCalendarView(userId, startDate, endDate, tenantId);
  return success(res, events, "Calendar view retrieved");
});

export const checkAvailability = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { startTime, endTime, excludeId } = req.query;
  const result = await scheduleService.checkAvailability(userId, startTime, endTime, tenantId, excludeId);
  return success(res, result, "Availability checked");
});

export const rsvp = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const event = await scheduleService.rsvp(req.params.id, tenantId, userId, req.body.status);
  return success(res, event, "RSVP recorded");
});

export const addAttendees = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const event = await scheduleService.addAttendees(
    req.params.id, req.body.userIds, tenantId, userId
  );
  return success(res, event, "Attendees added");
});

export const scheduleController = {
  createEvent, listEvents, getEvent, updateEvent, cancelEvent,
  deleteEvent, getCalendarView, checkAvailability, rsvp, addAttendees,
};
