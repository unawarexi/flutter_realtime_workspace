// ============================================================================
// TeamSpot — Workspace Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.post("/", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Workspace module ready");
}));

router.get("/", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, [], "Workspaces listed");
}));

router.get("/:id", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Workspace details");
}));

router.put("/:id", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Workspace updated");
}));

router.delete("/:id", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Workspace deleted");
}));

router.post("/:id/members", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Member added");
}));

router.get("/:id/members", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, [], "Members listed");
}));

export default router;
