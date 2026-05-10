// ============================================================================
// TeamSpot — Issue Routes
// ============================================================================

import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { issueController } from "./issues.controller.js";
import { 
  createIssueSchema, 
  updateIssueSchema, 
  linkIssueSchema 
} from "./issue.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Issue CRUD
router.post(
  '/', 
  upload.array('attachments', 5), 
  multerErrorHandler, 
  validate(createIssueSchema),
  asyncHandler(issueController.createIssue)
);

router.get('/', asyncHandler(issueController.getIssues));
router.get('/:id', asyncHandler(issueController.getIssueById));

router.put(
  '/:id', 
  validate(updateIssueSchema),
  asyncHandler(issueController.updateIssue)
);

router.delete('/:id', asyncHandler(issueController.deleteIssue));

// Features
router.post(
  '/:id/comments', 
  asyncHandler(issueController.addComment)
);

router.post(
  '/:id/link', 
  validate(linkIssueSchema),
  asyncHandler(issueController.linkIssue)
);

// Attachments
router.post(
  '/:id/attachments', 
  upload.single('attachment'), 
  multerErrorHandler, 
  asyncHandler(issueController.uploadAttachment)
);

export default router;
