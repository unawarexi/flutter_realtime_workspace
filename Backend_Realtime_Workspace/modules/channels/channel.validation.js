import { body, param } from "express-validator";

export const createChannelSchema = [
  body("name").trim().notEmpty().withMessage("Channel name is required").isLength({ max: 80 }),
  body("description").optional().isString(),
  body("workspaceId").isMongoId().withMessage("Valid Workspace ID is required"),
  body("type").optional().isIn(["public", "private", "direct", "group_dm"]),
  body("topic").optional().isString(),
];

export const updateChannelSchema = [
  param("id").isMongoId().withMessage("Invalid channel ID"),
  body("name").optional().trim().notEmpty().isLength({ max: 80 }),
  body("description").optional().isString(),
  body("topic").optional().isString(),
  body("status").optional().isIn(["active", "archived", "deleted"]),
];

export const addMemberSchema = [
  param("id").isMongoId().withMessage("Invalid channel ID"),
  body("userId").isMongoId().withMessage("Valid user ID is required"),
  body("role").optional().isIn(["admin", "moderator", "member"]),
];

export const sendMessageSchema = [
  param("id").isMongoId().withMessage("Invalid channel ID"),
  body("content").trim().notEmpty().withMessage("Message content is required"),
  body("threadId").optional().isMongoId(),
];
