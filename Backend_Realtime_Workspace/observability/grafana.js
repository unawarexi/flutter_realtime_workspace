// ============================================================================
// TeamSpot — Health & Readiness Probes
// Liveness, readiness, and detailed health check endpoints
// ============================================================================

import { env } from "../config/env.config.js";
import { createLogger } from "./logger.js";

const log = createLogger("Health");

const startTime = Date.now();

// ============================================================================
// SERVICE HEALTH CHECKERS (registered dynamically)
// ============================================================================

const healthCheckers = new Map();

export function registerHealthChecker(name, checker) {
  healthCheckers.set(name, checker);
}

// ============================================================================
// LIVENESS PROBE — is the process alive?
// ============================================================================

export function livenessProbe(_req, res) {
  res.status(200).json({
    status: "alive",
    uptime: Math.floor((Date.now() - startTime) / 1000),
    timestamp: new Date().toISOString(),
  });
}

// ============================================================================
// READINESS PROBE — is the app ready to accept traffic?
// ============================================================================

export async function readinessProbe(_req, res) {
  try {
    const results = {};
    let allHealthy = true;

    for (const [name, checker] of healthCheckers) {
      try {
        const result = await Promise.race([
          checker(),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error("Health check timeout")), 3000)
          ),
        ]);
        results[name] = { status: "healthy", ...result };
      } catch (err) {
        results[name] = { status: "unhealthy", error: err.message };
        allHealthy = false;
      }
    }

    const statusCode = allHealthy ? 200 : 503;
    res.status(statusCode).json({
      status: allHealthy ? "ready" : "degraded",
      services: results,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(503).json({
      status: "not_ready",
      error: err.message,
      timestamp: new Date().toISOString(),
    });
  }
}

// ============================================================================
// DETAILED HEALTH CHECK
// ============================================================================

export async function healthCheckEndpoint(_req, res) {
  const memUsage = process.memoryUsage();

  try {
    const services = {};

    for (const [name, checker] of healthCheckers) {
      try {
        services[name] = await checker();
      } catch (err) {
        services[name] = { status: "error", error: err.message };
      }
    }

    res.status(200).json({
      status: "ok",
      version: env.API_VERSION,
      environment: env.NODE_ENV,
      uptime: Math.floor((Date.now() - startTime) / 1000),
      memory: {
        heapUsedMB: Math.round(memUsage.heapUsed / 1024 / 1024),
        heapTotalMB: Math.round(memUsage.heapTotal / 1024 / 1024),
        rssMB: Math.round(memUsage.rss / 1024 / 1024),
        externalMB: Math.round(memUsage.external / 1024 / 1024),
      },
      services,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(503).json({
      status: "error",
      error: err.message,
      timestamp: new Date().toISOString(),
    });
  }
}

export default {
  livenessProbe,
  readinessProbe,
  healthCheckEndpoint,
  registerHealthChecker,
};
