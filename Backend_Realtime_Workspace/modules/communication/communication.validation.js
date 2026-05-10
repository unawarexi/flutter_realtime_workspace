// ============================================================================
// TeamSpot — Communication Validation
// express-validator schemas for communication module
// ============================================================================

import { body, query, param } from "express-validator";

export const validateRoomToken = [
  body("roomName").notEmpty().withMessage("roomName is required"),
];

export const validateInitiateCall = [
  body("calleeId").notEmpty().withMessage("calleeId is required"),
  body("type").optional().isIn(["audio", "video"]).withMessage("type must be audio or video"),
];

export const validateSendMessage = [
  body("recipientId").notEmpty().withMessage("recipientId is required"),
  body("content").optional().isString().isLength({ max: 10000 }),
  body("type").optional().isIn(["text", "voice", "file", "image"]),
];

export const validateGetMessages = [
  query("partnerId").notEmpty().withMessage("partnerId query param is required"),
  query("page").optional().isInt({ min: 1 }),
  query("limit").optional().isInt({ min: 1, max: 100 }),
];
