import { body, param } from "express-validator";

export const createWorkspaceSchema = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Workspace name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("Workspace name must be between 2 and 100 characters"),
  body("slug")
    .trim()
    .notEmpty()
    .withMessage("Slug is required")
    .matches(/^[a-z0-9-]+$/)
    .withMessage("Slug can only contain lowercase letters, numbers, and hyphens"),
  body("description").optional().isString().isLength({ max: 500 }),
  body("icon").optional().isString(),
  body("color").optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage("Invalid color hex"),
];

export const updateWorkspaceSchema = [
  param("id").isMongoId().withMessage("Invalid workspace ID"),
  body("name").optional().trim().isLength({ min: 2, max: 100 }),
  body("description").optional().isString().isLength({ max: 500 }),
  body("icon").optional().isString(),
  body("color").optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage("Invalid color hex"),
  body("status").optional().isIn(["active", "archived", "deleted"]),
];

export const updateWorkspaceSettingsSchema = [
  param("id").isMongoId().withMessage("Invalid workspace ID"),
  body("visibility").optional().isIn(["public", "private", "invite_only"]),
  body("defaultProjectTemplate").optional().isIn(["kanban", "scrum", "blank"]),
  body("allowGuests").optional().isBoolean(),
  body("notificationsEnabled").optional().isBoolean(),
];

export const addWorkspaceMemberSchema = [
  param("id").isMongoId().withMessage("Invalid workspace ID"),
  body("userId").isMongoId().withMessage("Valid User ID is required"),
  body("role").optional().isIn(["workspace_admin", "manager", "member", "guest"]),
];
