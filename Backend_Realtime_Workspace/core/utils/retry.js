// ============================================================================
// TeamSpot — Retry Utilities
// Reusable retry strategies for service connections and Redis clients
// ============================================================================

import { createLogger } from "../../observability/logger.js";

const log = createLogger("Retry");

/**
 * Retry an async operation with linear backoff.
 * @param {Function} fn — Async function to attempt
 * @param {Object} [opts]
 * @param {number} [opts.maxRetries=5]
 * @param {number} [opts.baseDelay=2000] — Base delay in ms
 * @param {string} [opts.label="operation"]
 * @returns {Promise<*>}
 */
export async function retryWithBackoff(fn, opts = {}) {
  const { maxRetries = 5, baseDelay = 2000, label = "operation" } = opts;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) throw err;
      const delay = baseDelay * attempt;
      log.warn(`${label} attempt ${attempt}/${maxRetries} failed, retrying in ${delay}ms`, { error: err.message });
      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

/**
 * Create a Redis-compatible retryStrategy function.
 * @param {Object} [opts]
 * @param {number} [opts.maxRetries=10]
 * @param {number} [opts.baseDelay=200]
 * @param {number} [opts.maxDelay=5000]
 * @param {string} [opts.label]
 * @returns {function(number): number|null}
 */
export function createRetryStrategy(opts = {}) {
  const { maxRetries = 10, baseDelay = 200, maxDelay = 5000, label } = opts;

  return function retryStrategy(times) {
    if (times > maxRetries) {
      if (label) log.error(`${label} max retries reached, giving up`);
      return null;
    }
    const delay = Math.min(times * baseDelay, maxDelay);
    if (label) log.warn(`${label} retry #${times} in ${delay}ms`);
    return delay;
  };
}

export default { retryWithBackoff, createRetryStrategy };
