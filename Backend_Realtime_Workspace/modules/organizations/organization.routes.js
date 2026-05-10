// ============================================================================
// TeamSpot — Organization Routes
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

// CRUD
router.post("/", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, { message: "Organization module ready" }, "Not yet implemented");
}));

router.get("/", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, [], "Organizations listed");
}));

router.get("/:id", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Organization details");
}));

router.put("/:id", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Organization updated");
}));

// Members
router.post("/:id/invite", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Member invited");
}));

router.get("/:id/members", asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, [], "Members listed");
}));

router.delete("/:id/members/:memberId", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Member removed");
}));

// Settings
router.get("/:id/settings", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Organization settings");
}));

router.put("/:id/settings", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => {
  const { success } = await import("../../core/utils/api-response.js");
  success(res, null, "Settings updated");
}));

export default router;
