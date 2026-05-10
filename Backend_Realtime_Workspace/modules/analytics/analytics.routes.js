// ============================================================================
// TeamSpot — Analytics Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { analyticsController } from "./analytics.controller.js";
import { getAnalyticsSchema, generateReportSchema } from "./analytics.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);
router.use(requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN, Roles.MANAGER));

router.get(
  "/dashboard", 
  validate(getAnalyticsSchema),
  asyncHandler(analyticsController.getDashboardStats)
);

router.get(
  "/reports/generate", 
  validate(generateReportSchema),
  asyncHandler(analyticsController.generateReport)
);

export default router;
