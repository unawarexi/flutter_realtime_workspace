// ============================================================================
// TeamSpot — Retry Utilities
// Exponential backoff + full jitter + circuit breaker for all async operations
// ============================================================================

import { createLogger } from "../../observability/logger.js";

const log = createLogger("Retry");

// ── Full-Jitter Helper ───────────────────────────────────────────────────────
// "Full jitter" (AWS recommendation): pick uniformly in [0, cap]
// Prevents thundering-herd when many clients retry simultaneously.
function jitteredDelay(attempt, baseMs, maxMs) {
  const exponential = Math.min(baseMs * Math.pow(2, attempt - 1), maxMs);
  return Math.random() * exponential; // uniform [0, cap]
}

// ── withRetry ────────────────────────────────────────────────────────────────
/**
 * Retry an async operation with exponential backoff + full jitter.
 *
 * @param {Function} fn          — Async function to attempt
 * @param {Object}  [opts]
 * @param {number}  [opts.maxAttempts=3]
 * @param {number}  [opts.backoffMs=100]   — Base delay in ms
 * @param {number}  [opts.maxBackoffMs=5000] — Hard cap on delay
 * @param {boolean} [opts.jitter=true]     — Enable full jitter (recommended)
 * @param {string}  [opts.label="op"]
 * @param {Function} [opts.onRetry]        — Called as onRetry(attempt, err)
 * @param {Function} [opts.shouldRetry]    — Return false to stop retrying early
 * @returns {Promise<*>}
 */
export async function withRetry(fn, opts = {}) {
  const {
    maxAttempts = 3,
    backoffMs = 100,
    maxBackoffMs = 5000,
    jitter = true,
    label = "op",
    onRetry = null,
    shouldRetry = null,
  } = opts;

  let lastErr;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (attempt === maxAttempts) break;
      if (shouldRetry && !shouldRetry(err, attempt)) break;

      const delay = jitter
        ? jitteredDelay(attempt, backoffMs, maxBackoffMs)
        : Math.min(backoffMs * Math.pow(2, attempt - 1), maxBackoffMs);

      log.warn(`${label} attempt ${attempt}/${maxAttempts} failed — retrying in ${Math.round(delay)}ms`, {
        error: err.message,
      });
      if (onRetry) onRetry(attempt, err);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  throw lastErr;
}

// ── retryWithBackoff ─────────────────────────────────────────────────────────
// Legacy alias kept for backward compat — uses exponential+jitter internally.
/**
 * @param {Function} fn
 * @param {Object}  [opts]
 * @param {number}  [opts.maxRetries=5]
 * @param {number}  [opts.baseDelay=1000]
 * @param {number}  [opts.maxDelay=15000]
 * @param {string}  [opts.label="operation"]
 */
export async function retryWithBackoff(fn, opts = {}) {
  const { maxRetries = 5, baseDelay = 1000, maxDelay = 15000, label = "operation" } = opts;
  return withRetry(fn, {
    maxAttempts: maxRetries,
    backoffMs: baseDelay,
    maxBackoffMs: maxDelay,
    jitter: true,
    label,
  });
}

// ── createRetryStrategy ──────────────────────────────────────────────────────
/**
 * Create a Redis ioredis-compatible retryStrategy function.
 * Uses exponential backoff with full jitter.
 *
 * @param {Object} [opts]
 * @param {number} [opts.maxRetries=10]
 * @param {number} [opts.baseDelay=200]
 * @param {number} [opts.maxDelay=5000]
 * @param {string} [opts.label]
 */
export function createRetryStrategy(opts = {}) {
  const { maxRetries = 10, baseDelay = 200, maxDelay = 5000, label } = opts;

  return function retryStrategy(times) {
    if (times > maxRetries) {
      if (label) log.error(`${label} max retries reached, giving up`);
      return null;
    }
    const delay = jitteredDelay(times, baseDelay, maxDelay);
    if (label) log.warn(`${label} retry #${times} in ${Math.round(delay)}ms`);
    return delay;
  };
}

export default { withRetry, retryWithBackoff, createRetryStrategy };
