import { body, param } from "express-validator";

export const createProjectSchema = [
  body("name").trim().notEmpty().withMessage("Project name is required").isLength({ max: 100 }),
  body("description").optional().isString().isLength({ max: 1000 }),
  body("template").optional().isString(),
  body("priority").optional().isIn(["low", "medium", "high", "critical"]),
  body("teamId").optional().isMongoId(),
  body("workspaceId").optional().isMongoId(),
  body("startDate").optional().isISO8601().toDate(),
  body("endDate").optional().isISO8601().toDate(),
];

export const updateProjectSchema = [
  param("id").isMongoId().withMessage("Invalid project ID"),
  body("name").optional().trim().notEmpty().isLength({ max: 100 }),
  body("description").optional().isString().isLength({ max: 1000 }),
  body("status").optional().isIn(["active", "archived", "on-hold", "completed", "planning", "review", "cancelled"]),
  body("priority").optional().isIn(["low", "medium", "high", "critical"]),
  body("progress").optional().isFloat({ min: 0, max: 1 }),
  body("startDate").optional().isISO8601().toDate(),
  body("endDate").optional().isISO8601().toDate(),
];

export const updateCollaboratorsSchema = [
  param("id").isMongoId().withMessage("Invalid project ID"),
  body("collaborators").isArray().withMessage("Collaborators must be an array of user IDs"),
  body("collaborators.*").isMongoId(),
];

export const timelineEventSchema = [
  param("id").isMongoId().withMessage("Invalid project ID"),
  body("title").trim().notEmpty().withMessage("Title is required"),
  body("description").optional().isString(),
  body("type").optional().isString(),
];
