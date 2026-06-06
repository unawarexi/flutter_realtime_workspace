// ============================================================================
// TeamSpot — Audit Routes
// ============================================================================

import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { auditController } from "./audit.controller.js";
import { getAuditLogsSchema } from "./audit.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);
router.use(requireRole(Roles.ORG_OWNER, Roles.ORG_ADMIN, Roles.SUPER_ADMIN));

router.get(
  '/', 
  validate(getAuditLogsSchema),
  asyncHandler(auditController.getAuditLogs)
);

router.get(
  '/export', 
  validate(getAuditLogsSchema),
  asyncHandler(auditController.exportAuditLogs)
);

router.get(
  '/:id', 
  asyncHandler(auditController.getAuditLogById)
);

export default router;
