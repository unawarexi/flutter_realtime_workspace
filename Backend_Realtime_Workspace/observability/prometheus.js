// ============================================================================
// TeamSpot — Prometheus Metrics
// Custom metrics collection with prom-client
// ============================================================================

import client from "prom-client";
import { createLogger } from "./logger.js";

const log = createLogger("Prometheus");

// ============================================================================
// REGISTRY
// ============================================================================

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: "teamspot_" });

// ============================================================================
// CUSTOM METRICS
// ============================================================================

// HTTP request metrics
const httpRequestDuration = new client.Histogram({
  name: "teamspot_http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5, 10],
  registers: [register],
});

const httpRequestTotal = new client.Counter({
  name: "teamspot_http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
  registers: [register],
});

// WebSocket metrics
const wsConnectionsGauge = new client.Gauge({
  name: "teamspot_websocket_connections",
  help: "Current number of WebSocket connections",
  registers: [register],
});

const wsEventsTotal = new client.Counter({
  name: "teamspot_websocket_events_total",
  help: "Total WebSocket events processed",
  labelNames: ["event"],
  registers: [register],
});

// Database metrics
const dbQueryDuration = new client.Histogram({
  name: "teamspot_db_query_duration_seconds",
  help: "Duration of database queries in seconds",
  labelNames: ["operation", "collection"],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1],
  registers: [register],
});

// Queue metrics
const queueJobsTotal = new client.Counter({
  name: "teamspot_queue_jobs_total",
  help: "Total queue jobs processed",
  labelNames: ["queue", "status"],
  registers: [register],
});

// Error metrics
const errorTotal = new client.Counter({
  name: "teamspot_errors_total",
  help: "Total errors by type and code",
  labelNames: ["type", "code"],
  registers: [register],
});

// AI metrics
const aiRequestDuration = new client.Histogram({
  name: "teamspot_ai_request_duration_seconds",
  help: "Duration of AI inference requests",
  labelNames: ["model", "type"],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 30],
  registers: [register],
});

// ============================================================================
// MIDDLEWARE
// ============================================================================

export function metricsMiddleware(req, res, next) {
  const start = process.hrtime.bigint();

  res.on("finish", () => {
    const durationNs = Number(process.hrtime.bigint() - start);
    const durationSeconds = durationNs / 1e9;

    const route = req.route?.path || req.path || "unknown";
    const labels = {
      method: req.method,
      route,
      status_code: res.statusCode,
    };

    httpRequestDuration.observe(labels, durationSeconds);
    httpRequestTotal.inc(labels);
  });

  next();
}

// ============================================================================
// METRICS ENDPOINT
// ============================================================================

export async function metricsEndpoint(_req, res) {
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
}

// ============================================================================
// METRIC EXPORTS
// ============================================================================

export const metrics = {
  httpRequestDuration,
  httpRequestTotal,
  wsConnectionsGauge,
  wsEventsTotal,
  dbQueryDuration,
  queueJobsTotal,
  errorTotal,
  aiRequestDuration,
};

export const errorMetrics = { total: errorTotal };

export default { metricsMiddleware, metricsEndpoint, metrics, errorMetrics };
