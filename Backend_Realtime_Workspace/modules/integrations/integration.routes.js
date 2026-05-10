// ============================================================================
// TeamSpot — Integration Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";
import {
  validateCreateIntegration,
  validateUpdateIntegration,
  validateListIntegrations,
} from "./integration.validation.js";
import {
  createIntegration,
  listIntegrations,
  getIntegration,
  updateIntegration,
  deleteIntegration,
  testIntegration,
  receiveWebhook,
} from "./integration.controller.js";

const router = express.Router();

// Inbound webhook — must come before auth middleware
router.post("/webhooks/:integrationId", receiveWebhook);

router.use(authenticate);
router.use(tenantMiddleware);

router.post("/",    validate(validateCreateIntegration), createIntegration);
router.get("/",     validate(validateListIntegrations),  listIntegrations);
router.get("/:id",  getIntegration);
router.put("/:id",  validate(validateUpdateIntegration), updateIntegration);
router.delete("/:id", deleteIntegration);
router.post("/:id/test", testIntegration);

export default router;
