// ============================================================================
// TeamSpot — Redis Service
// Singleton ioredis client with pub/sub, caching, and health checks
// ============================================================================

import Redis from "ioredis";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";
import { createRetryStrategy } from "../../core/utils/retry.js";

const log = createLogger("Redis");

let client = null;
let subscriber = null;
let isConnected = false;

// ============================================================================
// CONNECTION
// ============================================================================

function createRedisClient(name = "main") {
  const commonOptions = {
    // null = don't reject pending commands with MaxRetriesPerRequestError;
    // we handle availability via retryStrategy instead.
    maxRetriesPerRequest: null,
    retryStrategy: createRetryStrategy({
      maxRetries: 3,
      baseDelay: 500,
      maxDelay: 2000,
      label: `Redis [${name}]`,
    }),
    lazyConnect: true,
    enableReadyCheck: true,
    // Suppress automatic reconnect after we explicitly disconnect
    autoResubscribe: false,
    autoResendUnfulfilledCommands: false,
  };

  const redis = env.REDIS_URL
    ? new Redis(env.REDIS_URL, commonOptions)
    : new Redis({
        host: env.REDIS_HOST,
        port: env.REDIS_PORT,
        password: env.REDIS_PASSWORD || undefined,
        db: env.REDIS_DB,
        ...commonOptions,
      });

  redis.on("connect", () => log.info(`Redis [${name}] connected`));
  redis.on("ready", () => log.success(`Redis [${name}] ready`));
  // Swallow errors here — they are already logged; unhandled 'error' events
  // on EventEmitters crash the process, so this listener must exist.
  redis.on("error", (err) => log.error(`Redis [${name}] error`, {}));
  redis.on("close", () => {
    log.warn(`Redis [${name}] connection closed`);
    if (name === "main") isConnected = false;
  });

  return redis;
}

export async function initRedis() {
  if (client) return client;

  client = createRedisClient("main");
  subscriber = createRedisClient("subscriber");

  try {
    await Promise.all([client.connect(), subscriber.connect()]);
    isConnected = true;
    log.success("Redis initialized (main + subscriber)");
    return client;
  } catch (err) {
    // Destroy both clients immediately so ioredis stops all background
    // reconnection attempts (which would otherwise generate unhandled
    // MaxRetriesPerRequestError rejections that crash the server).
    client.disconnect();
    subscriber.disconnect();
    client = null;
    subscriber = null;
    throw err;
  }
}

// ============================================================================
// GETTERS
// ============================================================================

export function getRedisClient() {
  return client; // null when Redis is unavailable — callers must guard
}

export function getRedisSubscriber() {
  return subscriber; // null when Redis is unavailable — callers must guard
}

export function getIsConnected() {
  return isConnected;
}

// ============================================================================
// CACHE HELPERS
// ============================================================================

export async function getCache(key) {
  if (!client) return null;
  const data = await client.get(key);
  return data ? JSON.parse(data) : null;
}

export async function setCache(key, value, ttlSeconds) {
  if (!client) return;
  const serialized = JSON.stringify(value);
  if (ttlSeconds) {
    await client.set(key, serialized, "EX", ttlSeconds);
  } else {
    await client.set(key, serialized);
  }
}

export async function deleteCache(key) {
  if (!client) return;
  await client.del(key);
}

export async function deleteCachePattern(pattern) {
  if (!client) return;
  const keys = await client.keys(pattern);
  if (keys.length > 0) {
    await client.del(...keys);
  }
}

// ============================================================================
// RATE LIMIT HELPER — Sliding Window (Redis Sorted Set)
// ============================================================================
// Uses a sorted set where each member is a unique request timestamp token and
// its score is the Unix timestamp in ms.  On every call we:
//   1. Remove entries older than the window  → ZREMRANGEBYSCORE
//   2. Add the current request               → ZADD
//   3. Count remaining entries               → ZCARD
//   4. Reset the key TTL                     → PEXPIRE
// This gives a true sliding window (no 2× burst at boundary like fixed-window).
// O(log n) per call where n = requests in current window.

export async function checkRateLimit(identifier, limit, windowMs) {
  const key = `ratelimit:${identifier}`;
  const now = Date.now();
  const windowStart = now - windowMs;
  // Unique member: timestamp + random suffix prevents collisions in the same ms
  const member = `${now}:${Math.random().toString(36).slice(2, 8)}`;

  const pipeline = client.pipeline();
  pipeline.zremrangebyscore(key, 0, windowStart); // evict expired
  pipeline.zadd(key, now, member);                // record this request
  pipeline.zcard(key);                            // count in window
  pipeline.pexpire(key, windowMs);                // auto-cleanup

  const results = await pipeline.exec();
  const current = results[2][1]; // zcard result

  return {
    allowed: current <= limit,
    remaining: Math.max(0, limit - current),
    current,
  };
}

// ============================================================================
// HEALTH CHECK
// ============================================================================

export async function healthCheck() {
  if (!client) return { connected: false };
  const start = Date.now();
  await client.ping();
  const latencyMs = Date.now() - start;

  const info = await client.info("memory");
  const memoryMatch = info.match(/used_memory_human:(\S+)/);

  return {
    connected: isConnected,
    latencyMs,
    memoryUsedMB: memoryMatch?.[1] || "unknown",
  };
}

// ============================================================================
// DISCONNECT
// ============================================================================

export async function disconnectRedis() {
  if (client) await client.quit();
  if (subscriber) await subscriber.quit();
  isConnected = false;
  log.info("Redis disconnected");
}

export default {
  initRedis, getRedisClient, getRedisSubscriber, getIsConnected,
  getCache, setCache, deleteCache, deleteCachePattern,
  checkRateLimit, healthCheck, disconnectRedis,
};
