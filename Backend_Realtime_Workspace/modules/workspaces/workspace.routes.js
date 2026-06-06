// ============================================================================
// TeamSpot — Workspace Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { workspaceController } from "./workspace.controller.js";
import { 
  createWorkspaceSchema, 
  updateWorkspaceSchema, 
  addWorkspaceMemberSchema 
} from "./workspace.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware); // Needs tenant context

router.post(
  "/",
  validate(createWorkspaceSchema),
  asyncHandler(workspaceController.createWorkspace)
);

router.get(
  "/",
  asyncHandler(workspaceController.getWorkspaces)
);

router.get(
  "/:id",
  asyncHandler(workspaceController.getWorkspaceById)
);

router.put(
  "/:id",
  validate(updateWorkspaceSchema),
  asyncHandler(workspaceController.updateWorkspace)
);

router.delete(
  "/:id",
  asyncHandler(workspaceController.deleteWorkspace)
);

// Members
router.post(
  "/:id/members",
  validate(addWorkspaceMemberSchema),
  asyncHandler(workspaceController.addMember)
);

router.get(
  "/:id/members",
  asyncHandler(workspaceController.getMembers)
);

router.delete(
  "/:id/members/:userId",
  asyncHandler(workspaceController.removeMember)
);

export default router;
