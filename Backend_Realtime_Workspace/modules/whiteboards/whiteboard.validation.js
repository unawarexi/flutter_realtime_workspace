import { body, param } from "express-validator";

export const createWhiteboardSchema = [
  body("name").trim().notEmpty().withMessage("Whiteboard name is required").isLength({ max: 100 }),
  body("description").optional().isString(),
  body("projectId").optional().isMongoId(),
  body("workspaceId").optional().isMongoId(),
];

export const updateWhiteboardSchema = [
  param("id").isMongoId().withMessage("Invalid whiteboard ID"),
  body("name").optional().trim().notEmpty(),
  body("state").optional().isObject(),
];
