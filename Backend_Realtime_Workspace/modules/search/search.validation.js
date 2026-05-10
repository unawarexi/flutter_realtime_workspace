import { query, param } from "express-validator";

export const globalSearchSchema = [
  query("q").trim().notEmpty().withMessage("Search query 'q' is required").isLength({ min: 2, max: 100 }),
  query("limit").optional().isInt({ min: 1, max: 100 }),
  query("page").optional().isInt({ min: 1 }),
];

export const resourceSearchSchema = [
  param("resource").isIn(["users", "projects", "tasks", "issues", "tickets", "documents", "channels", "messages"]),
  query("q").trim().notEmpty().withMessage("Search query 'q' is required").isLength({ min: 2, max: 100 }),
  query("limit").optional().isInt({ min: 1, max: 100 }),
  query("page").optional().isInt({ min: 1 }),
];
