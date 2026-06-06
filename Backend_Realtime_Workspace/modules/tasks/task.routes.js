// ============================================================================
// TeamSpot — Task Routes
// ============================================================================

import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { taskController } from "./task.controller.js";
import { 
  createTaskSchema, 
  updateTaskSchema, 
  addCommentSchema,
  updateChecklistSchema
} from "./task.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Task CRUD
router.post(
  '/', 
  upload.array('attachments', 5), 
  multerErrorHandler, 
  validate(createTaskSchema),
  asyncHandler(taskController.createTask)
);

router.get('/', asyncHandler(taskController.getTasks));
router.get('/:id', asyncHandler(taskController.getTaskById));

router.put(
  '/:id', 
  validate(updateTaskSchema),
  asyncHandler(taskController.updateTask)
);

router.delete('/:id', asyncHandler(taskController.deleteTask));

// Features
router.post(
  '/:id/comments', 
  validate(addCommentSchema),
  asyncHandler(taskController.addComment)
);

router.put(
  '/:id/checklist', 
  validate(updateChecklistSchema),
  asyncHandler(taskController.updateChecklist)
);

// Attachments
router.post(
  '/:id/attachments', 
  upload.single('attachment'), 
  multerErrorHandler, 
  asyncHandler(taskController.uploadAttachment)
);

export default router;
