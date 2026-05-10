// ============================================================================
// TeamSpot — Audit Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { Roles } from "../../config/constants.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);
router.use(requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN, Roles.SUPER_ADMIN));

router.get("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Audit logs listed"); }));
router.get("/export", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Audit export ready"); }));
router.get("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Audit log details"); }));

export default router;
