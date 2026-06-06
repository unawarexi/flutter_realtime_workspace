// ============================================================================
// TeamSpot — Team Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { teamController } from "./team.controller.js";
import { 
  createTeamSchema, 
  updateTeamSchema, 
  inviteTeamMemberSchema 
} from "./team.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware); // Needs tenant context

router.post(
  "/",
  validate(createTeamSchema),
  asyncHandler(teamController.createTeam)
);

router.get(
  "/",
  asyncHandler(teamController.getUserTeams)
);

router.get(
  "/:id",
  asyncHandler(teamController.getTeamById)
);

router.put(
  "/:id",
  validate(updateTeamSchema),
  asyncHandler(teamController.updateTeam)
);

router.delete(
  "/:id",
  asyncHandler(teamController.deleteTeam)
);

router.post(
  "/:id/invite",
  validate(inviteTeamMemberSchema),
  asyncHandler(teamController.inviteMember)
);

export default router;
