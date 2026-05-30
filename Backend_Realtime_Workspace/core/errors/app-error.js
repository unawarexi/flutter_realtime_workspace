// ============================================================================
// TeamSpot — AppError Class & Factory Functions
// ============================================================================

import { HttpStatus, ErrorCodes } from "../../config/constants.js";

export class AppError extends Error {
  constructor(message, statusCode = 500, code = ErrorCodes.INTERNAL_ERROR, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.status = `${statusCode}`.startsWith("4") ? "fail" : "error";
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export function badRequest(message, details) {
  return new AppError(message, HttpStatus.BAD_REQUEST, ErrorCodes.VALIDATION_ERROR, details);
}

export function unauthorized(message = "Unauthorized") {
  return new AppError(message, HttpStatus.UNAUTHORIZED, ErrorCodes.UNAUTHORIZED);
}

export function forbidden(message = "Forbidden") {
  return new AppError(message, HttpStatus.FORBIDDEN, ErrorCodes.FORBIDDEN);
}

export function notFound(resource = "Resource") {
  return new AppError(`${resource} not found`, HttpStatus.NOT_FOUND, ErrorCodes.RESOURCE_NOT_FOUND);
}

export function conflict(message) {
  return new AppError(message, HttpStatus.CONFLICT, ErrorCodes.RESOURCE_ALREADY_EXISTS);
}

export function internalError(message = "Internal server error") {
  return new AppError(message, HttpStatus.INTERNAL_SERVER_ERROR, ErrorCodes.INTERNAL_ERROR);
}

export function tooManyRequests(message = "Too many requests") {
  return new AppError(message, HttpStatus.TOO_MANY_REQUESTS, ErrorCodes.RATE_LIMIT_EXCEEDED);
}

export function emailNotVerified(email) {
  const err = new AppError(
    "Please verify your email before logging in",
    HttpStatus.FORBIDDEN,
    ErrorCodes.EMAIL_NOT_VERIFIED,
  );
  err.email = email; // carry email so Flutter can redirect to verify screen
  return err;
}

export default {
  AppError, badRequest, unauthorized, forbidden,
  notFound, conflict, internalError, tooManyRequests,
};
