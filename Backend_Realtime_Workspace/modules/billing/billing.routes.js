// ============================================================================
// TeamSpot — Billing Routes
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

router.get("/subscription", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Subscription details"); }));
router.post("/subscription", requireRole(Roles.ORG_OWNER), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Subscription created"); }));
router.put("/subscription", requireRole(Roles.ORG_OWNER), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Subscription updated"); }));
router.get("/invoices", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Invoices listed"); }));
router.get("/invoices/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Invoice details"); }));
router.get("/usage", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Usage stats"); }));

export default router;
