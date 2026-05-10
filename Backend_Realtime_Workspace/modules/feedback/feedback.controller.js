import { asyncHandler } from "../../core/base/base.controller.js";
import { feedbackService } from "./feedback.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
});

export const createFeedback = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const feedback = await feedbackService.createFeedback({ ...req.body, tenantId, userId, files: req.files || [] });
  return created(res, feedback, "Feedback submitted");
});

export const listFeedback = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await feedbackService.listFeedback({ ...req.query, tenantId });
  return paginated(res, result, "Feedback retrieved");
});

export const getFeedback = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const fb = await feedbackService.getFeedbackById(req.params.id, tenantId);
  return success(res, fb, "Feedback retrieved");
});

export const updateStatus = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const fb = await feedbackService.updateStatus({ id: req.params.id, status: req.body.status, tenantId });
  return success(res, fb, "Status updated");
});

export const respondToFeedback = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const fb = await feedbackService.respondToFeedback({ id: req.params.id, content: req.body.content, tenantId, responderId: userId });
  return success(res, fb, "Response submitted");
});

export const deleteFeedback = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  await feedbackService.deleteById(req.params.id, { tenantId });
  return noContent(res);
});

export const feedbackController = { createFeedback, listFeedback, getFeedback, updateStatus, respondToFeedback, deleteFeedback };
