// ============================================================================
// TeamSpot — OpenTelemetry Distributed Tracing
// Trace context propagation for Kafka, HTTP, and WebSocket flows
// ============================================================================

import { createLogger } from "./logger.js";
import { randomUUID } from "crypto";

const log = createLogger("Tracing");

// ============================================================================
// TRACE CONTEXT — lightweight tracing without full OTel SDK dependency
// Provides correlation IDs across async boundaries (Kafka, WS, HTTP)
// ============================================================================

export function createTraceContext(parentTraceId = null) {
  return {
    traceId: parentTraceId || randomUUID(),
    spanId: randomUUID().slice(0, 16),
    startTime: Date.now(),
  };
}

export function endTrace(traceContext) {
  const duration = Date.now() - traceContext.startTime;
  return { ...traceContext, duration, endTime: Date.now() };
}

// ============================================================================
// MIDDLEWARE — inject trace context into every request
// ============================================================================

export function tracingMiddleware(req, _res, next) {
  const incomingTraceId = req.headers["x-trace-id"] || req.headers["traceparent"];
  const trace = createTraceContext(incomingTraceId);

  req.traceId = trace.traceId;
  req.spanId = trace.spanId;
  req.traceContext = trace;

  next();
}

// ============================================================================
// EVENT TRACE HEADERS — attach to Kafka/RabbitMQ messages
// ============================================================================

export function traceHeaders(traceContext) {
  return {
    "x-trace-id": traceContext.traceId,
    "x-span-id": traceContext.spanId,
    "x-trace-start": traceContext.startTime.toString(),
  };
}

export function extractTraceFromHeaders(headers) {
  return {
    traceId: headers["x-trace-id"] || randomUUID(),
    spanId: headers["x-span-id"] || randomUUID().slice(0, 16),
    startTime: parseInt(headers["x-trace-start"], 10) || Date.now(),
  };
}

export default {
  createTraceContext,
  endTrace,
  tracingMiddleware,
  traceHeaders,
  extractTraceFromHeaders,
};
