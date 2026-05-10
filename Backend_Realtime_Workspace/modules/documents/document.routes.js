// ============================================================================
// TeamSpot — Document Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { upload, multerErrorHandler } from "../../infrastructure/storage/cloudinary.service.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.post("/upload", upload.single("file"), multerErrorHandler, asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document module ready"); }));
router.get("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Documents listed"); }));
router.get("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document details"); }));
router.put("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document updated"); }));
router.delete("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document deleted"); }));
router.post("/:id/share", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document shared"); }));
router.post("/:id/reindex", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Document reindexed"); }));
router.get("/:id/versions", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Document versions"); }));

export default router;
