import BaseController from "../../core/base/base.controller.js";
import { meetingService } from "./meeting.service.js";

class MeetingController extends BaseController {
  
  createMeeting = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    // User info is loaded via auth middleware into req.user
    const meeting = await meetingService.createMeeting(req.body, tenantId, req.user);
    return BaseController.sendCreated(res, meeting, "Meeting scheduled successfully");
  };

  getMeetings = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const { status, date } = req.query;
    
    const filter = {
      $or: [
        { "organizer.userId": userId },
        { "participants.userId": userId }
      ]
    };

    if (status) filter.status = status;
    if (date) {
        const start = new Date(date);
        start.setHours(0,0,0,0);
        const end = new Date(date);
        end.setHours(23,59,59,999);
        filter.meetingDate = { $gte: start, $lte: end };
    }
    
    const pagination = BaseController.getPagination(req);
    const result = await meetingService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort || { meetingDate: 1 })
    });

    return BaseController.sendPaginated(res, result, "Meetings retrieved");
  };

  getMeetingById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const meeting = await meetingService.getMeetingById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, meeting, "Meeting retrieved");
  };

  updateMeeting = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const meeting = await meetingService.updateMeeting(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, meeting, "Meeting updated");
  };

  deleteMeeting = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await meetingService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Meeting deleted");
  };

  rsvp = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const meeting = await meetingService.rsvp(req.params.id, userId, req.body.status, tenantId);
    return BaseController.sendSuccess(res, meeting, "RSVP updated");
  };

  joinMeeting = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const result = await meetingService.joinMeeting(req.params.id, req.user, tenantId);
    return BaseController.sendSuccess(res, result, "Joined meeting");
  };
}

export const meetingController = new MeetingController();
