// ============================================================================
// TeamSpot — Base Service
// Common service patterns: cache-aside, event emission, error wrapping
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { eventBus } from "../events/event-bus.js";
import { getCache, setCache, deleteCache } from "../../infrastructure/redis/redis.service.js";
import { publishToQueue, publishDelayed } from "../../infrastructure/rabbitmq/rabbitmq.service.js";

export class BaseService {
  /**
   * @param {import('./base.repository.js').BaseRepository} repository
   * @param {Object} [options]
   * @param {string} [options.name] — service name for logging
   * @param {string} [options.cachePrefix] — prefix for cache keys
   * @param {number} [options.cacheTTL] — default cache TTL in seconds
   */
  constructor(repository, options = {}) {
    this.repository = repository;
    this.name = options.name || "BaseService";
    this.cachePrefix = options.cachePrefix || "";
    this.cacheTTL = options.cacheTTL || 300;
    this.log = createLogger(this.name);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CACHE-ASIDE PATTERN
  // ──────────────────────────────────────────────────────────────────────────

  _cacheKey(suffix) {
    return `${this.cachePrefix}:${suffix}`;
  }

  async cachedFindById(id, { tenantId, ttl, ...opts } = {}) {
    const key = this._cacheKey(`id:${id}`);
    try {
      const cached = await getCache(key);
      if (cached) return cached;
    } catch {
      // Cache miss or error — fall through to DB
    }

    const result = await this.repository.findById(id, { tenantId, ...opts });
    if (result) {
      try { await setCache(key, result, ttl || this.cacheTTL); } catch {}
    }
    return result;
  }

  async invalidateCache(id) {
    try { await deleteCache(this._cacheKey(`id:${id}`)); } catch {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EVENT EMISSION
  // ──────────────────────────────────────────────────────────────────────────

  emit(eventName, payload) {
    eventBus.publish(eventName, {
      ...payload,
      source: this.name,
      timestamp: Date.now(),
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TASK QUEUE (RABBITMQ)
  // ──────────────────────────────────────────────────────────────────────────

  async enqueueJob(queueName, payload, options = {}) {
    const { delayMs, ...publishOpts } = options;
    try {
      if (delayMs) {
        await publishDelayed(queueName, payload, delayMs);
      } else {
        await publishToQueue(queueName, payload, publishOpts);
      }
      this.log.debug(`Enqueued job to ${queueName}`);
    } catch (error) {
      this.log.error(`Failed to enqueue job to ${queueName}`, { error: error.message });
      throw error;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STANDARD CRUD (delegates to repository)
  // ──────────────────────────────────────────────────────────────────────────

  async create(data, context = {}) {
    return this.repository.create(data, context);
  }

  async findById(id, context = {}) {
    return this.repository.findById(id, context);
  }

  async findMany(filter, context = {}) {
    return this.repository.findMany(filter, context);
  }

  async paginate(filter, context = {}) {
    return this.repository.paginate(filter, context);
  }

  async updateById(id, updates, context = {}) {
    const result = await this.repository.updateById(id, updates, context);
    await this.invalidateCache(id);
    return result;
  }

  async deleteById(id, context = {}) {
    const result = await this.repository.deleteById(id, context);
    await this.invalidateCache(id);
    return result;
  }

  async count(filter, context = {}) {
    return this.repository.count(filter, context);
  }

  async exists(filter, context = {}) {
    return this.repository.exists(filter, context);
  }
}

export default BaseService;
