// ============================================================================
// TeamSpot — Organization Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { organizationController } from "./organization.controller.js";
import { 
  createOrganizationSchema, 
  updateOrganizationSchema, 
  updateSettingsSchema, 
  inviteMemberSchema 
} from "./organization.validation.js";

const router = express.Router();

router.use(authenticate);

// Organizations create doesn't need tenantMiddleware because it creates the tenant
router.post(
  "/",
  validate(createOrganizationSchema),
  asyncHandler(organizationController.createOrganization)
);

// All subsequent routes require the user to be within a tenant context (or we pass ID)
router.use(tenantMiddleware);

router.get(
  "/",
  asyncHandler(organizationController.getOrganizations)
);

router.get(
  "/:id",
  asyncHandler(organizationController.getOrganizationById)
);

router.put(
  "/:id",
  validate(updateOrganizationSchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN),
  asyncHandler(organizationController.updateOrganization)
);

// Members
router.post(
  "/:id/invite",
  validate(inviteMemberSchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN),
  asyncHandler(organizationController.inviteMember)
);

router.get(
  "/:id/members",
  asyncHandler(organizationController.getMembers)
);

router.delete(
  "/:id/members/:memberId",
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN),
  asyncHandler(organizationController.removeMember)
);

// Settings
router.get(
  "/:id/settings",
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN),
  asyncHandler(organizationController.getOrganizationById) // settings are embedded in org doc
);

router.put(
  "/:id/settings",
  validate(updateSettingsSchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN),
  asyncHandler(organizationController.updateSettings)
);

export default router;
