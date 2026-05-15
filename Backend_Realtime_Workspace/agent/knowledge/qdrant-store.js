// ============================================================================
// TeamSpot — Qdrant Vector Store
// Singleton client + collection bootstrap.
// All RAG ingestion and retrieval go through this module.
// ============================================================================

import { QdrantClient } from "@qdrant/js-client-rest";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";
import { generateEmbeddings } from "./embeddings.js";

const log = createLogger("QdrantStore");

export const COLLECTION = "teamspot_knowledge";

let _client = null;
let _ready   = false;

// ── Client singleton ─────────────────────────────────────────────────────────

export function getQdrantClient() {
  if (!_client) {
    _client = new QdrantClient({
      url:    env.QDRANT_URL,
      apiKey: env.QDRANT_API_KEY || undefined,
    });
  }
  return _client;
}

// ── Collection bootstrap ──────────────────────────────────────────────────────

/**
 * Ensure the teamspot_knowledge collection exists with the correct vector
 * dimension (auto-detected from the active embeddings provider on first run)
 * and payload indexes for ACL filtering.
 * Safe to call multiple times — only runs once per process.
 */
export async function initQdrant() {
  if (_ready) return;

  const client = getQdrantClient();

  const { collections } = await client.getCollections();
  const exists = collections.some((c) => c.name === COLLECTION);

  if (!exists) {
    // Detect vector dimension from the active embeddings provider
    const [sample] = await generateEmbeddings(["warmup"]);
    const vectorSize = sample.length;

    await client.createCollection(COLLECTION, {
      vectors: { size: vectorSize, distance: "Cosine" },
    });

    // Indexes for fast ACL payload filtering
    await client.createPayloadIndex(COLLECTION, {
      field_name: "tenantId",
      field_schema: "keyword",
    });
    await client.createPayloadIndex(COLLECTION, {
      field_name: "workspaceId",
      field_schema: "keyword",
    });

    log.info("Qdrant collection created", { collection: COLLECTION, vectorSize });
  }

  _ready = true;
  log.info("Qdrant ready", { url: env.QDRANT_URL, collection: COLLECTION });
}

// ── Upsert helper ─────────────────────────────────────────────────────────────

/**
 * Upsert pre-built points (id + vector + payload) into the collection.
 * @param {Array<{id: string, vector: number[], payload: object}>} points
 */
export async function upsertPoints(points) {
  await initQdrant();
  const client = getQdrantClient();
  await client.upsert(COLLECTION, { wait: true, points });
}

// ── Search helper ─────────────────────────────────────────────────────────────

/**
 * Vector similarity search with optional ACL payload filter.
 * @param {number[]} queryVector   - Pre-computed query embedding
 * @param {object}  filter         - Qdrant filter object { must: [...] }
 * @param {number}  limit
 * @returns {Array<{content, score, metadata}>}
 */
export async function vectorSearch(queryVector, filter, limit = 5) {
  await initQdrant();
  const client = getQdrantClient();

  const hits = await client.search(COLLECTION, {
    vector:       queryVector,
    limit,
    filter:       filter || undefined,
    with_payload: true,
  });

  return hits.map((hit) => ({
    content:  hit.payload.content,
    score:    hit.score,
    metadata: hit.payload.metadata || {},
  }));
}
