import { body, param } from "express-validator";

export const createWorkflowSchema = [
  body("name").trim().notEmpty().withMessage("Workflow name is required").isLength({ max: 200 }),
  body("description").optional().isString(),
  body("trigger").isObject().withMessage("Trigger configuration is required"),
  body("trigger.type").isIn(["event", "schedule", "webhook", "manual"]),
  body("conditions").optional().isArray(),
  body("actions").isArray().withMessage("At least one action is required"),
  body("actions.*.type").isString().notEmpty(),
  body("actions.*.config").isObject(),
];

export const updateWorkflowSchema = [
  param("id").isMongoId().withMessage("Invalid workflow ID"),
  body("name").optional().trim().notEmpty().isLength({ max: 200 }),
  body("description").optional().isString(),
  body("trigger").optional().isObject(),
  body("conditions").optional().isArray(),
  body("actions").optional().isArray(),
  body("enabled").optional().isBoolean(),
  body("status").optional().isIn(["active", "paused", "error", "deleted"]),
];

export const toggleWorkflowSchema = [
  param("id").isMongoId().withMessage("Invalid workflow ID"),
  body("enabled").isBoolean().withMessage("Enabled must be a boolean"),
];
