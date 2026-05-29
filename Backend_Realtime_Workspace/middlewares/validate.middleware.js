// ============================================================================
// TeamSpot — Validation Middleware
// Zod schema validation for request body, query, and params
// ============================================================================

import { validationResult } from "express-validator";
import { HttpStatus, ErrorCodes } from "../config/constants.js";

export function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(HttpStatus.BAD_REQUEST).json({
        success: false,
        error: {
          code: ErrorCodes.VALIDATION_ERROR,
          message: "Validation failed",
          details: result.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
        },
      });
    }
    req.body = result.data;
    next();
  };
}

export function validateQuery(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      return res.status(HttpStatus.BAD_REQUEST).json({
        success: false,
        error: {
          code: ErrorCodes.VALIDATION_ERROR,
          message: "Invalid query parameters",
          details: result.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
        },
      });
    }
    req.query = result.data;
    next();
  };
}

export function validateParams(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.params);
    if (!result.success) {
      return res.status(HttpStatus.BAD_REQUEST).json({
        success: false,
        error: {
          code: ErrorCodes.VALIDATION_ERROR,
          message: "Invalid URL parameters",
          details: result.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
        },
      });
    }
    req.params = result.data;
    next();
  };
}

// Alias: validate(schema) validates req.body — used by Zod-based route files
export const validate = validateBody;

/**
 * checkValidation — express-validator result checker.
 * Place after an express-validator array (body(), param(), etc.) in the route chain.
 * Reads errors collected by express-validator and short-circuits with 400 if any exist.
 */
export const checkValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(HttpStatus.BAD_REQUEST).json({
      success: false,
      error: {
        code: ErrorCodes.VALIDATION_ERROR,
        message: "Validation failed",
        details: errors.array().map((e) => ({ path: e.path ?? e.param, message: e.msg })),
      },
    });
  }
  next();
};
