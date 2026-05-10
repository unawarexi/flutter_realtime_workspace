// ============================================================================
// TeamSpot — Sentry Error Tracking
// ============================================================================

import * as Sentry from "@sentry/node";
import { env, isProduction } from "../config/env.config.js";
import { createLogger } from "./logger.js";

const log = createLogger("Sentry");

let initialized = false;

// ============================================================================
// INITIALIZATION
// ============================================================================

export function initializeSentry() {
  if (!env.SENTRY_DSN) {
    log.warn("Sentry DSN not configured — error tracking disabled");
    return;
  }

  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.NODE_ENV,
    tracesSampleRate: isProduction() ? 0.1 : 1.0,
    profilesSampleRate: isProduction() ? 0.1 : 0,
    integrations: [
      Sentry.httpIntegration(),
      Sentry.expressIntegration(),
      Sentry.mongooseIntegration(),
    ],
    beforeSend(event) {
      // Scrub sensitive data
      if (event.request?.headers) {
        delete event.request.headers.authorization;
        delete event.request.headers.cookie;
      }
      return event;
    },
  });

  initialized = true;
  log.info("Sentry initialized", { environment: env.NODE_ENV });
}

// ============================================================================
// EXPRESS INTEGRATION
// ============================================================================

export function setupSentryExpress(app) {
  if (!initialized) return;
  Sentry.setupExpressErrorHandler(app);
}

// ============================================================================
// CAPTURE HELPERS
// ============================================================================

export function captureException(error, context = {}) {
  if (!initialized) return;

  Sentry.withScope((scope) => {
    if (context.userId) scope.setUser({ id: context.userId });
    if (context.tenantId) scope.setTag("tenantId", context.tenantId);
    if (context.action) scope.setTag("action", context.action);
    if (context.extra) scope.setExtras(context.extra);
    Sentry.captureException(error);
  });
}

export function captureMessage(message, level = "info", context = {}) {
  if (!initialized) return;

  Sentry.withScope((scope) => {
    if (context.userId) scope.setUser({ id: context.userId });
    if (context.tenantId) scope.setTag("tenantId", context.tenantId);
    if (context.extra) scope.setExtras(context.extra);
    Sentry.captureMessage(message, level);
  });
}

export default { initializeSentry, setupSentryExpress, captureException, captureMessage };
