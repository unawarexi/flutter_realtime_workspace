// ============================================================================
// TeamSpot — Search Service
// Search interface abstraction (MongoDB text search, Elasticsearch-ready)
// ============================================================================

import { createLogger } from "../../observability/logger.js";

const log = createLogger("Search");

/**
 * Search interface — currently backed by MongoDB text search.
 * When Elasticsearch/OpenSearch is added, swap the implementation here.
 */
export class SearchService {
  constructor() {
    this.backends = new Map(); // resource → model mapping
  }

  /**
   * Register a searchable model
   * @param {string} resource — e.g. "projects", "tasks", "channels"
   * @param {import('mongoose').Model} model
   * @param {Object} options
   * @param {string[]} options.searchFields — fields to search
   */
  register(resource, model, options = {}) {
    this.backends.set(resource, { model, ...options });
    log.debug(`Registered searchable: ${resource}`, { fields: options.searchFields });
  }

  /**
   * Global search across all registered models
   */
  async search(query, { tenantId, resources, limit = 20, page = 1 } = {}) {
    const results = {};
    const targets = resources
      ? [...this.backends.entries()].filter(([r]) => resources.includes(r))
      : [...this.backends.entries()];

    await Promise.all(
      targets.map(async ([resource, { model, searchFields }]) => {
        try {
          const filter = {
            $text: { $search: query },
            ...(tenantId && { tenantId }),
          };

          const docs = await model
            .find(filter, { score: { $meta: "textScore" } })
            .sort({ score: { $meta: "textScore" } })
            .skip((page - 1) * limit)
            .limit(limit)
            .lean();

          if (docs.length > 0) {
            results[resource] = docs;
          }
        } catch (err) {
          log.error(`Search failed for ${resource}`, { error: err });
          results[resource] = [];
        }
      })
    );

    return results;
  }

  /**
   * Search within a single resource
   */
  async searchResource(resource, query, { tenantId, limit = 20, page = 1, filters = {} } = {}) {
    const backend = this.backends.get(resource);
    if (!backend) throw new Error(`Resource '${resource}' not registered for search`);

    const filter = {
      $text: { $search: query },
      ...(tenantId && { tenantId }),
      ...filters,
    };

    const [data, total] = await Promise.all([
      backend.model
        .find(filter, { score: { $meta: "textScore" } })
        .sort({ score: { $meta: "textScore" } })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      backend.model.countDocuments(filter),
    ]);

    return { data, total, page, limit };
  }
}

export const searchService = new SearchService();
export default searchService;
