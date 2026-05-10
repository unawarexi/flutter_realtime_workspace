// ============================================================================
// TeamSpot — Integration Validation
// ============================================================================

import { body, param, query } from "express-validator";

const INTEGRATION_TYPES = ["github", "gitlab", "slack", "google_drive", "onedrive", "zoom", "jira", "notion", "figma", "custom_webhook"];

export const validateCreateIntegration = [
  body("name").trim().notEmpty().withMessage("Integration name is required"),
  body("type").isIn(INTEGRATION_TYPES).withMessage("Unsupported integration type"),
  body("config").optional().isObject(),
  body("config.webhookUrl").optional().isURL().withMessage("Invalid webhook URL"),
  body("events").optional().isArray(),
];

export const validateUpdateIntegration = [
  param("id").isMongoId().withMessage("Invalid integration ID"),
  body("name").optional().trim().notEmpty(),
  body("enabled").optional().isBoolean(),
  body("events").optional().isArray(),
  body("config").optional().isObject(),
];

export const validateListIntegrations = [
  query("type").optional().isIn(INTEGRATION_TYPES),
  query("page").optional().isInt({ min: 1 }),
  query("limit").optional().isInt({ min: 1, max: 100 }),
];
