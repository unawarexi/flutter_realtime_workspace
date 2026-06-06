import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { feedbackController } from "./feedback.controller.js";
import { 
  createFeedbackSchema, 
  updateFeedbackSchema,
  respondFeedbackSchema
} from "./feedback.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Feedback CRUD
router.post(
  '/', 
  upload.array('attachments', 3), 
  multerErrorHandler, 
  validate(createFeedbackSchema),
  asyncHandler(feedbackController.createFeedback)
);

router.get('/', asyncHandler(feedbackController.getFeedbacks));
router.get('/:id', asyncHandler(feedbackController.getFeedbackById));

router.put(
  '/:id', 
  validate(updateFeedbackSchema),
  asyncHandler(feedbackController.updateFeedback)
);

router.delete('/:id', asyncHandler(feedbackController.deleteFeedback));

// Respond
router.post(
  '/:id/respond', 
  validate(respondFeedbackSchema),
  asyncHandler(feedbackController.respondToFeedback)
);

export default router;
