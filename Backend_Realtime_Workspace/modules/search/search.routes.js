// ============================================================================
// TeamSpot — Search Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.get("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, { results: {} }, "Global search"); }));
router.get("/:resource", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Resource search"); }));

export default router;
