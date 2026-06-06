// ============================================================================
// TeamSpot — Admin Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { adminController } from "./admin.controller.js";
import { 
  getTenantsSchema, 
  updateTenantStatusSchema,
  impersonateUserSchema
} from "./admin.validation.js";

const router = express.Router();

router.use(authenticate);
// Admin routes are super-admin only, cross-tenant
router.use(requireRole(Roles.SUPER_ADMIN));

router.get("/tenants", validate(getTenantsSchema), asyncHandler(adminController.getTenants));
router.put("/tenants/:id/status", validate(updateTenantStatusSchema), asyncHandler(adminController.updateTenantStatus));

router.get("/stats", asyncHandler(adminController.getSystemStats));

router.post("/impersonate", validate(impersonateUserSchema), asyncHandler(adminController.impersonateUser));

export default router;
