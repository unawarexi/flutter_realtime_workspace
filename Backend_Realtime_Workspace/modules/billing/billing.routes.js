// ============================================================================
// TeamSpot — Billing Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { requireRole } from "../../core/auth/permission.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { Roles } from "../../config/constants.js";

import { billingController } from "./billing.controller.js";
import { updateSubscriptionSchema } from "./billing.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Subscription
router.get("/subscription", asyncHandler(billingController.getSubscription));

router.put(
  "/subscription", 
  requireRole(Roles.ORG_OWNER), 
  validate(updateSubscriptionSchema),
  asyncHandler(billingController.updateSubscription)
);

// Invoices
router.get("/invoices", asyncHandler(billingController.getInvoices));
router.get("/invoices/:id", asyncHandler(billingController.getInvoiceById));

// Usage
router.get("/usage", asyncHandler(billingController.getUsageStats));

export default router;
