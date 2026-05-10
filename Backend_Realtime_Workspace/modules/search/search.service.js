// ============================================================================
// TeamSpot — Search Module Service
// Delegates to infrastructure/search; logs queries to Kafka analytics
// ============================================================================

import mongoose from "mongoose";
import { searchService as infraSearch } from "../../infrastructure/search/search.service.js";
import { badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";

// Resources available for search
const RESOURCE_MODELS = {
  projects:  "Project",
  tasks:     "Task",
  issues:    "Issue",
  tickets:   "Ticket",
  channels:  "Channel",
  users:     "UserInfo",
};

// Register all searchable models with infrastructure layer
function registerModels() {
  for (const [resource, modelName] of Object.entries(RESOURCE_MODELS)) {
    try {
      const model = mongoose.model(modelName);
      infraSearch.register(resource, model);
    } catch (_) { /* model not yet registered — will be registered when loaded */ }
  }
}

class SearchModuleService {
  constructor() {
    this.name = "SearchService";
  }

  // ── Global Search ─────────────────────────────────────────────────────────────
  async globalSearch({ query, tenantId, resources, page = 1, limit = 10, userId }) {
    if (!query?.trim()) throw badRequest("Search query is required");

    // Lazy model registration
    registerModels();

    const resourceFilter = resources
      ? resources.split(",").map(r => r.trim()).filter(r => RESOURCE_MODELS[r])
      : null;

    const results = await infraSearch.search(query.trim(), { tenantId, resources: resourceFilter, limit: +limit, page: +page });

    // Cache recent queries per user for suggestions
    const redis = getRedisClient();
    await redis.lpush(`search:recent:${tenantId}:${userId}`, query.trim());
    await redis.ltrim(`search:recent:${tenantId}:${userId}`, 0, 9); // keep last 10
    await redis.expire(`search:recent:${tenantId}:${userId}`, 7 * 24 * 3600);

    // Track analytics
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "search.performed", query: query.trim(), resources: resourceFilter,
      resultCount: Object.values(results).reduce((s, arr) => s + arr.length, 0),
      userId, tenantId,
    });

    return { query, results, page: +page, limit: +limit };
  }

  // ── Resource-scoped Search ────────────────────────────────────────────────────
  async resourceSearch({ resource, query, tenantId, page = 1, limit = 20, filters }) {
    if (!query?.trim()) throw badRequest("Search query is required");
    if (!RESOURCE_MODELS[resource]) throw badRequest(`Invalid resource: ${resource}`);

    registerModels();
    return infraSearch.searchResource(resource, query.trim(), { tenantId, limit: +limit, page: +page, filters });
  }

  // ── Suggestions / Autocomplete ────────────────────────────────────────────────
  async getSuggestions({ query, tenantId, limit = 5 }) {
    if (!query?.trim()) return [];
    registerModels();

    const results = await infraSearch.search(query.trim(), { tenantId, limit: +limit, page: 1 });

    // Build flat suggestion list: { id, type, label }
    const suggestions = [];
    for (const [type, docs] of Object.entries(results)) {
      for (const doc of docs) {
        suggestions.push({
          id: doc._id,
          type,
          label: doc.title || doc.name || doc.fullName || doc.email || doc.subject || String(doc._id),
        });
      }
    }
    return suggestions.slice(0, +limit);
  }

  // ── Recent Searches ───────────────────────────────────────────────────────────
  async getRecentSearches({ tenantId, userId }) {
    const redis = getRedisClient();
    const items = await redis.lrange(`search:recent:${tenantId}:${userId}`, 0, 9);
    return items;
  }
}

export const searchModuleService = new SearchModuleService();
