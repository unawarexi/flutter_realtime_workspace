// ============================================================================
// TeamSpot — Project Routes
// ============================================================================

import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { projectController } from "./project.controller.js";
import { 
  createProjectSchema, 
  updateProjectSchema, 
  updateCollaboratorsSchema,
  timelineEventSchema
} from "./project.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Project CRUD
router.post(
  '/', 
  upload.array('attachments', 10), 
  multerErrorHandler, 
  validate(createProjectSchema),
  asyncHandler(projectController.createProject)
);

router.get('/', asyncHandler(projectController.getProjects));
router.get('/generate-key', asyncHandler(projectController.generateProjectKey));
router.get('/:id', asyncHandler(projectController.getProjectById));

router.put(
  '/:id', 
  validate(updateProjectSchema),
  asyncHandler(projectController.updateProject)
);

router.delete('/:id', asyncHandler(projectController.deleteProject));

// Actions
router.patch('/:id/star', asyncHandler(projectController.toggleProjectStar));
router.patch('/:id/archive', asyncHandler(projectController.toggleProjectArchive));

// Collaborators
router.patch(
  '/:id/collaborators', 
  validate(updateCollaboratorsSchema),
  asyncHandler(projectController.updateProjectCollaborators)
);

// Timeline
router.post(
  '/:id/timeline', 
  validate(timelineEventSchema),
  asyncHandler(projectController.addTimelineEvent)
);

// Attachments
router.post(
  '/:id/attachments', 
  upload.single('attachment'), 
  multerErrorHandler, 
  asyncHandler(projectController.uploadAttachment)
);

router.delete('/:id/attachments/:attachmentId', asyncHandler(projectController.deleteAttachment));

export default router;
