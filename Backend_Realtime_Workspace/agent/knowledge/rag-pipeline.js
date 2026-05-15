// ============================================================================
// TeamSpot — RAG Pipeline
// Ingest → Chunk → Embed → Index (Qdrant) → Retrieve
// ============================================================================

import { randomUUID } from "crypto";
import { createLogger } from "../../observability/logger.js";
import { chunkDocument } from "./chunking.js";
import { generateEmbeddings } from "./embeddings.js";
import { upsertPoints, vectorSearch, initQdrant } from "./qdrant-store.js";

const log = createLogger("RAGPipeline");

export class RAGPipeline {
  constructor() {
    // No external vectorStore dependency — Qdrant is the store.
  }

  /**
   * Ingest a document: chunk → embed → upsert into Qdrant.
   * @param {{ content: string, metadata: object, chunkingStrategy?: string }} opts
   */
  async ingest({ content, metadata, chunkingStrategy = "recursive" }) {
    log.info("Ingesting document", { title: metadata?.title, strategy: chunkingStrategy });

    await initQdrant();

    // 1. Chunk
    const chunks = chunkDocument(content, { strategy: chunkingStrategy, chunkSize: 1000, overlap: 200 });
    log.debug("Chunked document", { chunkCount: chunks.length });

    // 2. Embed all chunks in one batch
    const embeddings = await generateEmbeddings(chunks.map((c) => c.text));
    log.debug("Generated embeddings", { count: embeddings.length });

    // 3. Build Qdrant points with ACL payload
    const points = chunks.map((chunk, i) => ({
      id:      randomUUID(),
      vector:  embeddings[i],
      payload: {
        content:     chunk.text,
        tenantId:    metadata?.tenantId    ?? "global",
        workspaceId: metadata?.workspaceId ?? null,
        metadata: {
          ...metadata,
          chunkIndex: i,
          chunkTotal: chunks.length,
          ...chunk.metadata,
        },
      },
    }));

    // 4. Upsert into Qdrant
    await upsertPoints(points);
    log.info("Documents indexed in Qdrant", { count: points.length });

    return { chunksCreated: chunks.length, documentsIndexed: points.length };
  }

  /**
   * Query Qdrant with ACL filtering.
   * @param {{ query: string, tenantId: string, workspaceId?: string, limit?: number }} opts
   */
  async query({ query, tenantId, workspaceId, limit = 5 }) {
    const [queryEmbedding] = await generateEmbeddings([query]);

    const must = [{ key: "tenantId", match: { value: tenantId } }];
    if (workspaceId) must.push({ key: "workspaceId", match: { value: workspaceId } });

    const results = await vectorSearch(queryEmbedding, { must }, limit);

    log.debug("RAG query completed", { query: query.slice(0, 50), results: results.length });
    return results;
  }
}

export default RAGPipeline;
