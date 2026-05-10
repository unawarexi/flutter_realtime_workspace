import { body, param } from "express-validator";

export const uploadDocumentSchema = [
  body("title").trim().notEmpty().withMessage("Title is required").isLength({ max: 200 }),
  body("workspaceId").optional().isMongoId(),
  body("projectId").optional().isMongoId(),
  body("visibility").optional().isIn(["private", "workspace", "organization", "public"]),
];

export const updateDocumentSchema = [
  param("id").isMongoId().withMessage("Invalid document ID"),
  body("title").optional().trim().notEmpty().isLength({ max: 200 }),
  body("visibility").optional().isIn(["private", "workspace", "organization", "public"]),
  body("status").optional().isIn(["active", "archived", "deleted"]),
];

export const shareDocumentSchema = [
  param("id").isMongoId().withMessage("Invalid document ID"),
  body("userId").isMongoId().withMessage("Valid User ID required"),
  body("permission").optional().isIn(["view", "edit"]),
];
