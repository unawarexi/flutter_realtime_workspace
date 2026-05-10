import { body, param } from "express-validator";

export const createIssueSchema = [
  body("title").trim().notEmpty().withMessage("Issue title is required").isLength({ max: 200 }),
  body("description").optional().isString().isLength({ max: 5000 }),
  body("projectId").isMongoId().withMessage("Valid Project ID is required"),
  body("assignedTo").optional().isMongoId(),
  body("type").optional().isIn(["bug", "feature", "improvement", "task", "epic", "story"]),
  body("priority").optional().isIn(["lowest", "low", "medium", "high", "critical"]),
  body("severity").optional().isIn(["trivial", "minor", "major", "blocker"]),
  body("environment").optional().isString(),
  body("stepsToReproduce").optional().isString(),
  body("expectedBehavior").optional().isString(),
  body("actualBehavior").optional().isString(),
];

export const updateIssueSchema = [
  param("id").isMongoId().withMessage("Invalid issue ID"),
  body("title").optional().trim().notEmpty().isLength({ max: 200 }),
  body("description").optional().isString(),
  body("assignedTo").optional().isMongoId(),
  body("status").optional().isIn(["open", "in_progress", "resolved", "closed", "reopened", "wont_fix"]),
  body("type").optional().isIn(["bug", "feature", "improvement", "task", "epic", "story"]),
  body("priority").optional().isIn(["lowest", "low", "medium", "high", "critical"]),
  body("severity").optional().isIn(["trivial", "minor", "major", "blocker"]),
];

export const linkIssueSchema = [
  param("id").isMongoId().withMessage("Invalid issue ID"),
  body("targetIssueId").isMongoId().withMessage("Target issue ID required"),
  body("relation").isIn(["blocks", "blocked_by", "duplicates", "related_to"]),
];
