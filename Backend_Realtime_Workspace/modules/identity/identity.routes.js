// ============================================================================
// TeamSpot — Identity Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { identityController } from "./identity.controller.js";
import { 
  createRoleSchema, 
  updateRoleSchema, 
  createPolicySchema, 
  updatePolicySchema 
} from "./identity.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Roles
router.get(
  "/roles", 
  asyncHandler(identityController.getRoles)
);

router.post(
  "/roles", 
  validate(createRoleSchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.createRole)
);

router.put(
  "/roles/:id", 
  validate(updateRoleSchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.updateRole)
);

router.delete(
  "/roles/:id", 
  requireRole(Roles.ORG_OWNER), 
  asyncHandler(identityController.deleteRole)
);

// Policies
router.get(
  "/policies", 
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.getPolicies)
);

router.post(
  "/policies", 
  validate(createPolicySchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.createPolicy)
);

router.put(
  "/policies/:id", 
  validate(updatePolicySchema),
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.updatePolicy)
);

// User permissions
router.get(
  "/users/:userId/permissions", 
  asyncHandler(identityController.getUserPermissions)
);

router.put(
  "/users/:userId/role", 
  requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), 
  asyncHandler(identityController.updateUserRole)
);

export default router;
