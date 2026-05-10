import { body, param } from "express-validator";

export const createFeedbackSchema = [
  body("type").isIn(["bug", "feature", "improvement", "praise", "complaint", "survey"]),
  body("title").trim().notEmpty().withMessage("Title is required").isLength({ max: 200 }),
  body("description").optional().isString(),
  body("rating").optional().isInt({ min: 1, max: 5 }),
  body("category").optional().isString(),
  body("priority").optional().isIn(["low", "medium", "high"]),
];

export const updateFeedbackSchema = [
  param("id").isMongoId().withMessage("Invalid feedback ID"),
  body("status").optional().isIn(["new", "acknowledged", "in_progress", "resolved", "closed"]),
  body("priority").optional().isIn(["low", "medium", "high"]),
  body("category").optional().isString(),
];

export const respondFeedbackSchema = [
  param("id").isMongoId().withMessage("Invalid feedback ID"),
  body("content").trim().notEmpty().withMessage("Response content is required"),
];
