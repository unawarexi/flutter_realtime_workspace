// TeamSpot — Feedback Routes
import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.post("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Feedback module ready"); }));
router.get("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Feedback listed"); }));
router.get("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Feedback details"); }));
router.put("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Feedback updated"); }));
router.post("/:id/respond", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Response added"); }));

export default router;
