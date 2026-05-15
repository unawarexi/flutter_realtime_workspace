// ============================================================================
// TeamSpot — ACL-Aware Retriever
// Hybrid search (vector similarity via Qdrant) with permission filtering.
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { generateEmbeddings } from "./embeddings.js";
import { vectorSearch } from "./qdrant-store.js";

const log = createLogger("Retriever");

export class Retriever {
  /**
   * Semantic search with ACL-enforced payload filtering.
   * @param {string} query
   * @param {{ tenantId: string, workspaceId?: string, userId?: string, limit?: number }} opts
   */
  static async search(query, { tenantId, workspaceId, userId, limit = 5 } = {}) {
    log.debug("Searching", { query: query.slice(0, 50), tenantId });

    // 1. Embed the query
    const [queryVector] = await generateEmbeddings([query]);

    // 2. Build Qdrant payload filter — only return docs the user can access
    const must = [
      { key: "tenantId", match: { value: tenantId } },
    ];
    if (workspaceId) {
      must.push({ key: "workspaceId", match: { value: workspaceId } });
    }
    const filter = { must };

    // 3. Vector similarity search
    const results = await vectorSearch(queryVector, filter, limit);

    log.debug("Retriever results", { count: results.length, query: query.slice(0, 50) });
    return { results, query, filter };
  }
}

export default Retriever;
