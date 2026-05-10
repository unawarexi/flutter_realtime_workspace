// ============================================================================
// TeamSpot — Global Error Handler
// Mongoose-aware error handling with Sentry + Prometheus integration
// ============================================================================

import { HttpStatus, ErrorCodes } from "../../config/constants.js";
import { isDevelopment } from "../../config/env.config.js";
import { captureException } from "../../observability/sentry.js";
import { createLogger } from "../../observability/logger.js";
import { metrics } from "../../observability/prometheus.js";
import { AppError } from "./app-error.js";

const log = createLogger("ErrorHandler");

export function notFoundHandler(req, _res, next) {
  next(new AppError(`Cannot find ${req.method} ${req.originalUrl}`, HttpStatus.NOT_FOUND));
}

export function globalErrorHandler(err, req, res, _next) {
  let statusCode = err.statusCode || HttpStatus.INTERNAL_SERVER_ERROR;
  let message = err.message || "Something went wrong";
  let code = err.code || ErrorCodes.INTERNAL_ERROR;

  // ── Mongoose Error Handling ──
  if (err.name === "ValidationError") {
    statusCode = HttpStatus.BAD_REQUEST;
    code = ErrorCodes.VALIDATION_ERROR;
    message = Object.values(err.errors).map((e) => e.message).join(", ");
  } else if (err.name === "CastError") {
    statusCode = HttpStatus.BAD_REQUEST;
    code = ErrorCodes.INVALID_INPUT;
    message = `Invalid ${err.path}: ${err.value}`;
  } else if (err.code === 11000) {
    // MongoDB duplicate key
    statusCode = HttpStatus.CONFLICT;
    code = ErrorCodes.DUPLICATE_ENTRY;
    const field = Object.keys(err.keyValue || {})[0] || "field";
    message = `A record with this ${field} already exists`;
  } else if (err.name === "MongoServerError") {
    statusCode = HttpStatus.BAD_REQUEST;
    code = ErrorCodes.DATABASE_ERROR;
    message = "Database operation failed";
  }

  // ── Prometheus Error Metric ──
  try {
    metrics.errorTotal.inc({ type: err.name || "Error", code });
  } catch { /* metrics may not be initialized */ }

  // ── Log Error ──
  const requestId = req.requestId;
  const userId = req.user?.uid;
  const tenantId = req.tenantId;

  if (statusCode >= 500) {
    log.error(message, {
      error: err,
      requestId,
      userId,
      tenantId,
      method: req.method,
      url: req.originalUrl,
      statusCode,
    });

    try {
      captureException(err, {
        userId,
        tenantId,
        action: `${req.method} ${req.originalUrl}`,
        extra: { requestId, statusCode, code },
      });
    } catch { /* sentry may not be initialized */ }
  } else {
    log.warn(message, {
      requestId,
      userId,
      tenantId,
      method: req.method,
      url: req.originalUrl,
      statusCode,
      code,
    });
  }

  // ── Response ──
  const response = {
    success: false,
    error: { code, message },
  };

  if (isDevelopment()) {
    response.error.stack = err.stack;
    if (err.details) response.error.details = err.details;
  }

  res.status(statusCode).json(response);
}

export default { notFoundHandler, globalErrorHandler };
