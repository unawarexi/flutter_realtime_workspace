import { query, param, body } from "express-validator";

export const createAuditLogSchema = [
  body("action").trim().notEmpty().withMessage("Action is required").isLength({ max: 100 }),
  body("category").isIn(["auth", "iam", "data", "admin", "ai", "billing", "system"]),
  body("target").optional().isObject(),
  body("changes").optional().isObject(),
  body("status").optional().isIn(["success", "failure"]),
];

export const getAuditLogsSchema = [
  query("action").optional().isString(),
  query("category").optional().isIn(["auth", "iam", "data", "admin", "ai", "billing", "system"]),
  query("userId").optional().isString(),
  query("startDate").optional().isISO8601().toDate(),
  query("endDate").optional().isISO8601().toDate(),
  query("limit").optional().isInt({ min: 1, max: 100 }),
  query("page").optional().isInt({ min: 1 }),
];
