// ============================================================================
// TeamSpot — Main Entry Point
// Enterprise Workspace Collaboration Platform Backend
// ============================================================================

import express from "express";
import http from "http";
import compression from "compression";

// Configuration
import { env, validateEnv } from "./config/env.config.js";
import { HttpStatus } from "./config/constants.js";
import { connectDB, disconnectDB } from "./config/mongo.config.js";
import { createLogger } from "./observability/logger.js";

// Observability
import { initializeSentry, setupSentryExpress } from "./observability/sentry.js";
import { metricsMiddleware, metricsEndpoint } from "./observability/prometheus.js";
import { healthCheckEndpoint, livenessProbe, readinessProbe, registerHealthChecker } from "./observability/grafana.js";
import { tracingMiddleware } from "./observability/tracing.js";

// Middleware
import {
  securityHeaders,
  corsConfig,
  configureTrustProxy,
  xssProtection,
} from "./middlewares/security.middleware.js";
import { requestId, requestLogger } from "./middlewares/request-logger.middleware.js";
import { globalErrorHandler } from "./core/errors/error-handler.js";
import { apiLimiter } from "./middlewares/ratelimit.middleware.js";
import { tenantMiddleware } from "./core/auth/tenant.middleware.js";

// Infrastructure
import { initRedis, disconnectRedis, healthCheck as redisHealthCheck } from "./infrastructure/redis/redis.service.js";
import { initKafka, disconnectKafka, healthCheck as kafkaHealthCheck } from "./infrastructure/kafka/kafka.service.js";
import { initRabbitMQ, disconnectRabbitMQ, healthCheck as rabbitHealthCheck } from "./infrastructure/rabbitmq/rabbitmq.service.js";
import { initWebSocket, disconnectWebSocket } from "./infrastructure/websocket/websocket.service.js";
import { initCloudinary } from "./infrastructure/storage/cloudinary.service.js";
import { verifyMailer } from "./infrastructure/mailer/mailer.service.js";
import { initLiveKit } from "./infrastructure/livekit/livekit.service.js";

// Module Registry
import { registerModules } from "./modules/module-registry.js";

// Workers
import { initWorkers } from "./workers/index.js";

const log = createLogger("Server");

// ============================================================================
// EXPRESS APPLICATION SETUP
// ============================================================================

const app = express();
const server = http.createServer(app);

// ============================================================================
// PRE-ROUTE MIDDLEWARE
// ============================================================================

// Trust proxy (nginx / load balancer)
configureTrustProxy(app);

// Sentry must be initialized before other middleware
initializeSentry();

// Security
app.use(securityHeaders());
app.use(corsConfig());
app.use(xssProtection);

// Body parsing
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Compression
app.use(compression());

// Request tracking & tracing
app.use(requestId);
app.use(tracingMiddleware);

// Prometheus metrics collection
app.use(metricsMiddleware);

// Request logging (skip in tests)
if (env.NODE_ENV !== "test") {
  app.use(requestLogger);
}

// Global rate limiter
app.use(apiLimiter);

// Tenant context extraction (applied globally, non-blocking)
app.use(tenantMiddleware);

// ============================================================================
// HEALTH & OBSERVABILITY ENDPOINTS
// ============================================================================

app.get("/health", livenessProbe);
app.get("/health/ready", readinessProbe);
app.get("/health/detailed", healthCheckEndpoint);
app.get("/metrics", metricsEndpoint);

// ============================================================================
// API ROUTES — Auto-discovered from modules/
// ============================================================================

const API = `/api/${env.API_VERSION}`;

// Modules are registered asynchronously during startup
// (see startServer below)

// API info endpoint
app.get(API, (_req, res) => {
  res.status(HttpStatus.OK).json({
    name: "TeamSpot API",
    version: "1.0.0",
    description: "Enterprise Workspace Collaboration Platform",
    apiVersion: env.API_VERSION,
    health: "/health",
    metrics: "/metrics",
  });
});

// ============================================================================
// SERVER STARTUP
// ============================================================================

async function startServer() {
  try {
    validateEnv();

    // ── Database ──
    await connectDB();
    registerHealthChecker("mongodb", async () => {
      const mongoose = await import("mongoose");
      return {
        readyState: mongoose.default.connection.readyState,
        host: mongoose.default.connection.host,
      };
    });

    // ── Redis ──
    try {
      await initRedis();
      registerHealthChecker("redis", redisHealthCheck);
      log.info("Redis connected");
    } catch (err) {
      log.warn("Redis connection failed — running without cache", { error: err.message });
    }

    // ── Kafka ──
    if (env.KAFKA_BROKERS) {
      try {
        await initKafka();
        registerHealthChecker("kafka", kafkaHealthCheck);
        log.info("Kafka connected");
      } catch (err) {
        log.warn("Kafka connection failed — running without event streaming", { error: err.message });
      }
    }

    // ── WebSocket ──
    initWebSocket(server);
    log.info("WebSocket initialized");

    // ── RabbitMQ ──
    try {
      await initRabbitMQ();
      registerHealthChecker("rabbitmq", rabbitHealthCheck);
      log.info("RabbitMQ connected");
    } catch (err) {
      log.warn("RabbitMQ connection failed — email queuing disabled", { error: err.message });
    }

    // ── Background Workers ──
    await initWorkers();

    // ── LiveKit ──
    initLiveKit();

    // ── Cloudinary ──
    initCloudinary();

    // ── Register all module routes ──
    const registeredModules = await registerModules(app, API);

    // Error handlers must be registered AFTER all routes
    // (Express processes middleware in order)
    setupSentryExpress(app);

    app.use((_req, res) => {
      res.status(HttpStatus.NOT_FOUND).json({
        success: false,
        message: "Route not found",
      });
    });

    app.use(globalErrorHandler);

    // ── SMTP verification (non-blocking) ──
    verifyMailer().catch((err) => log.warn("SMTP verification failed", { error: err.message }));

    // ── Start HTTP server ──
    const PORT = env.PORT;

    server.listen(PORT, () => {
      log.info("═".repeat(56));
      log.info("  TEAMSPOT BACKEND SERVER");
      log.info("═".repeat(56));
      log.info(`  Environment : ${env.NODE_ENV}`);
      log.info(`  Port        : ${PORT}`);
      log.info(`  API         : ${API}`);
      log.info(`  Modules     : ${registeredModules.length} registered`);
      log.info(`  Health      : http://localhost:${PORT}/health`);
      log.info(`  Metrics     : http://localhost:${PORT}/metrics`);
      log.info("═".repeat(56));
    });
  } catch (error) {
    log.error("Failed to start server", { error });
    process.exit(1);
  }
}

// ============================================================================
// GRACEFUL SHUTDOWN
// ============================================================================

async function gracefulShutdown(signal) {
  log.info(`${signal} received — shutting down...`);

  server.close(() => log.info("HTTP server closed"));

  try { await disconnectDB(); log.info("Database disconnected"); } catch {}
  try { await disconnectRedis(); log.info("Redis disconnected"); } catch {}
  try { await disconnectKafka(); log.info("Kafka disconnected"); } catch {}
  try { await disconnectRabbitMQ(); log.info("RabbitMQ disconnected"); } catch {}
  try { await disconnectWebSocket(); log.info("WebSocket disconnected"); } catch {}

  log.info("Graceful shutdown completed");
  process.exit(0);
}

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

process.on("uncaughtException", (error) => {
  const sep = "═".repeat(60);
  log.error(`\n${sep}\nUNCAUGHT EXCEPTION — server will exit\nMessage : ${error.message}\nStack   :\n${error.stack ?? error}\n${sep}`);
  gracefulShutdown("uncaughtException");
});

process.on("unhandledRejection", (reason, promise) => {
  const sep = "═".repeat(60);
  const msg   = reason instanceof Error ? reason.message : String(reason);
  const stack = reason instanceof Error ? (reason.stack ?? "(no stack)") : "(no stack)";
  log.error(`\n${sep}\nUNHANDLED PROMISE REJECTION\nPromise : ${String(promise)}\nReason  : ${msg}\nStack   :\n${stack}\n${sep}`);
  // Do NOT crash — log and continue so one bad async call doesn't bring down the server
});

// ============================================================================
// START
// ============================================================================

startServer();

export { app, server };
