// ============================================================================
// TeamSpot — Workflow Routes
// ============================================================================

import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { workflowController } from "./workflow.controller.js";
import { 
  createWorkflowSchema, 
  updateWorkflowSchema,
  toggleWorkflowSchema
} from "./workflow.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Workflow CRUD
router.post(
  '/', 
  validate(createWorkflowSchema),
  asyncHandler(workflowController.createWorkflow)
);

router.get('/', asyncHandler(workflowController.getWorkflows));
router.get('/:id', asyncHandler(workflowController.getWorkflowById));

router.put(
  '/:id', 
  validate(updateWorkflowSchema),
  asyncHandler(workflowController.updateWorkflow)
);

router.delete('/:id', asyncHandler(workflowController.deleteWorkflow));

// Status & Testing
router.patch(
  '/:id/toggle', 
  validate(toggleWorkflowSchema),
  asyncHandler(workflowController.toggleWorkflow)
);

router.post(
  '/:id/test', 
  asyncHandler(workflowController.testWorkflow)
);

export default router;
