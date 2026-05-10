// TeamSpot — Storage Routes
import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { upload, multerErrorHandler } from "../../infrastructure/storage/cloudinary.service.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.post("/upload", upload.single("file"), multerErrorHandler, asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "File uploaded"); }));
router.post("/upload/multiple", upload.array("files", 10), multerErrorHandler, asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Files uploaded"); }));
router.get("/", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Assets listed"); }));
router.get("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Asset details"); }));
router.delete("/:id", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Asset deleted"); }));

export default router;
