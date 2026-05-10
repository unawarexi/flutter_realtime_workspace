import BaseController from "../../core/base/base.controller.js";
import { feedbackService } from "./feedback.service.js";

class FeedbackController extends BaseController {
  
  createFeedback = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const feedback = await feedbackService.createFeedback(req.body, tenantId, userId, files);
    return BaseController.sendCreated(res, feedback, "Feedback submitted successfully");
  };

  getFeedbacks = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { type, status, priority, category } = req.query;
    
    const filter = {};
    if (type) filter.type = type;
    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (category) filter.category = category;
    
    const pagination = BaseController.getPagination(req);
    const result = await feedbackService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Feedback retrieved");
  };

  getFeedbackById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const feedback = await feedbackService.getFeedbackById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, feedback, "Feedback retrieved");
  };

  updateFeedback = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const feedback = await feedbackService.updateFeedback(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, feedback, "Feedback updated");
  };

  deleteFeedback = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await feedbackService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Feedback deleted");
  };

  respondToFeedback = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const feedback = await feedbackService.respondToFeedback(req.params.id, req.body.content, tenantId, userId);
    return BaseController.sendSuccess(res, feedback, "Response submitted");
  };
}

export const feedbackController = new FeedbackController();
