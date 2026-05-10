// ============================================================================
// TeamSpot — Storage Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { upload, multerErrorHandler } from "../../infrastructure/storage/cloudinary.service.js";
import {
  uploadFile,
  uploadMultiple,
  listAssets,
  getAsset,
  deleteAsset,
  attachAsset,
} from "./storage.controller.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

router.post("/upload",          upload.single("file"),    multerErrorHandler, uploadFile);
router.post("/upload/multiple", upload.array("files", 10), multerErrorHandler, uploadMultiple);
router.get("/",                 listAssets);
router.get("/:id",              getAsset);
router.delete("/:id",          deleteAsset);
router.patch("/:id/attach",    attachAsset);

export default router;
