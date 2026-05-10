// ============================================================================
// TeamSpot — Template Validation
// ============================================================================

import { body, query, param } from "express-validator";

export const validateCreateTemplate = [
  body("name").trim().notEmpty().withMessage("Template name is required"),
  body("slug").trim().notEmpty().matches(/^[a-z0-9-_]+$/).withMessage("Slug must be lowercase alphanumeric with hyphens"),
  body("type").isIn(["email", "pdf", "notification", "invoice"]).withMessage("Invalid template type"),
  body("body").notEmpty().withMessage("Template body is required"),
  body("subject").if(body("type").equals("email")).notEmpty().withMessage("Subject is required for email templates"),
  body("variables").optional().isArray(),
  body("variables.*.name").optional().trim().notEmpty(),
  body("category").optional().trim(),
  body("status").optional().isIn(["active", "draft"]),
];

export const validateUpdateTemplate = [
  param("id").isMongoId().withMessage("Invalid template ID"),
  body("name").optional().trim().notEmpty(),
  body("body").optional().notEmpty(),
  body("subject").optional().trim(),
  body("variables").optional().isArray(),
  body("status").optional().isIn(["active", "draft", "archived"]),
  body("category").optional().trim(),
];

export const validateListTemplates = [
  query("type").optional().isIn(["email", "pdf", "notification", "invoice"]),
  query("status").optional().isIn(["active", "draft", "archived"]),
  query("page").optional().isInt({ min: 1 }),
  query("limit").optional().isInt({ min: 1, max: 100 }),
];
