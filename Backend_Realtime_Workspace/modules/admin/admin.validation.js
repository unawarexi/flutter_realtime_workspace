import { body, param, query } from "express-validator";

export const getTenantsSchema = [
  query("status").optional().isIn(["active", "suspended", "deleted"]),
  query("limit").optional().isInt({ min: 1, max: 100 }),
  query("page").optional().isInt({ min: 1 }),
];

export const updateTenantStatusSchema = [
  param("id").isMongoId().withMessage("Invalid tenant ID"),
  body("status").isIn(["active", "suspended", "deleted"]).withMessage("Valid status required"),
];

export const impersonateUserSchema = [
  body("userId").isMongoId().withMessage("Invalid user ID to impersonate"),
];
