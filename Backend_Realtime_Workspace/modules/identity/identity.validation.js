import { body, param } from "express-validator";

export const createRoleSchema = [
  body("name").trim().notEmpty().withMessage("Role name is required"),
  body("slug").trim().notEmpty().withMessage("Role slug is required"),
  body("description").optional().isString(),
  body("permissions").isArray().withMessage("Permissions must be an array"),
  body("permissions.*.resource").isString().notEmpty(),
  body("permissions.*.actions").isArray(),
  body("hierarchy").optional().isInt(),
];

export const updateRoleSchema = [
  param("id").isMongoId().withMessage("Invalid role ID"),
  body("name").optional().trim().notEmpty(),
  body("description").optional().isString(),
  body("permissions").optional().isArray(),
  body("hierarchy").optional().isInt(),
];

export const createPolicySchema = [
  body("name").trim().notEmpty().withMessage("Policy name is required"),
  body("description").optional().isString(),
  body("effect").isIn(["allow", "deny"]),
  body("conditions").isArray(),
  body("resource").isString().notEmpty(),
  body("actions").isArray(),
  body("priority").optional().isInt(),
];

export const updatePolicySchema = [
  param("id").isMongoId().withMessage("Invalid policy ID"),
  body("name").optional().trim().notEmpty(),
  body("description").optional().isString(),
  body("effect").optional().isIn(["allow", "deny"]),
  body("conditions").optional().isArray(),
  body("enabled").optional().isBoolean(),
  body("priority").optional().isInt(),
];
