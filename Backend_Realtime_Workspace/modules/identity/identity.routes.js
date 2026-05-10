// TeamSpot — Identity Routes
import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { Roles } from "../../config/constants.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Roles
router.get("/roles", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Roles listed"); }));
router.post("/roles", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Role created"); }));
router.put("/roles/:id", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Role updated"); }));
router.delete("/roles/:id", requireRole(Roles.ORG_OWNER), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Role deleted"); }));

// Policies
router.get("/policies", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, [], "Policies listed"); }));
router.post("/policies", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Policy created"); }));
router.put("/policies/:id", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "Policy updated"); }));

// User permissions
router.get("/users/:userId/permissions", asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "User permissions"); }));
router.put("/users/:userId/role", requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN), asyncHandler(async (req, res) => { const { success } = await import("../../core/utils/api-response.js"); success(res, null, "User role updated"); }));

export default router;
