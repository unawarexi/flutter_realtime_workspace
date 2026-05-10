import { body, param } from "express-validator";

export const createTaskSchema = [
  body("title").trim().notEmpty().withMessage("Task title is required").isLength({ max: 200 }),
  body("description").optional().isString().isLength({ max: 2000 }),
  body("projectId").isMongoId().withMessage("Valid Project ID is required"),
  body("assignedTo").optional().isMongoId(),
  body("status").optional().isIn(["backlog", "todo", "in_progress", "in_review", "done", "blocked", "cancelled"]),
  body("priority").optional().isIn(["lowest", "low", "medium", "high", "critical"]),
  body("dueDate").optional().isISO8601().toDate(),
  body("estimatedHours").optional().isFloat({ min: 0 }),
];

export const updateTaskSchema = [
  param("id").isMongoId().withMessage("Invalid task ID"),
  body("title").optional().trim().notEmpty().isLength({ max: 200 }),
  body("description").optional().isString().isLength({ max: 2000 }),
  body("assignedTo").optional().isMongoId(),
  body("status").optional().isIn(["backlog", "todo", "in_progress", "in_review", "done", "blocked", "cancelled"]),
  body("priority").optional().isIn(["lowest", "low", "medium", "high", "critical"]),
  body("dueDate").optional().isISO8601().toDate(),
  body("estimatedHours").optional().isFloat({ min: 0 }),
  body("loggedHours").optional().isFloat({ min: 0 }),
  body("sortOrder").optional().isNumeric(),
];

export const addCommentSchema = [
  param("id").isMongoId().withMessage("Invalid task ID"),
  body("content").trim().notEmpty().withMessage("Comment content is required"),
];

export const updateChecklistSchema = [
  param("id").isMongoId().withMessage("Invalid task ID"),
  body("checklist").isArray(),
  body("checklist.*.title").isString().notEmpty(),
  body("checklist.*.completed").isBoolean(),
];
