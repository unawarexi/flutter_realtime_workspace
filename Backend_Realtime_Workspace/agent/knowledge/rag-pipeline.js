// ============================================================================
// TeamSpot — RAG Pipeline
// Ingest → Chunk → Embed → Index → Retrieve
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { chunkDocument } from "./chunking.js";
import { generateEmbeddings } from "./embeddings.js";
const log = createLogger("RAGPipeline");

export class RAGPipeline {
  constructor(vectorStore) {
    this.vectorStore = vectorStore;
  }

  /** Ingest a document into the vector store */
  async ingest({ content, metadata, chunkingStrategy = "recursive" }) {
    log.info("Ingesting document", { title: metadata?.title, strategy: chunkingStrategy });

    // 1. Chunk
    const chunks = chunkDocument(content, { strategy: chunkingStrategy, chunkSize: 1000, overlap: 200 });
    log.debug("Chunked document", { chunkCount: chunks.length });

    // 2. Embed
    const embeddings = await generateEmbeddings(chunks.map((c) => c.text));
    log.debug("Generated embeddings", { count: embeddings.length });

    // 3. Store
    const documents = chunks.map((chunk, i) => ({
      content: chunk.text,
      embedding: embeddings[i],
      metadata: { ...metadata, chunkIndex: i, chunkTotal: chunks.length, ...chunk.metadata },
    }));

    if (this.vectorStore) {
      await this.vectorStore.addDocuments(documents);
      log.info("Documents indexed", { count: documents.length });
    }

    return { chunksCreated: chunks.length, documentsIndexed: documents.length };
  }

  /** Query the vector store with ACL filtering */
  async query({ query, userId, tenantId, workspaceId, limit = 5 }) {
    const queryEmbedding = (await generateEmbeddings([query]))[0];
    const filter = { tenantId };
    if (workspaceId) filter.workspaceId = workspaceId;

    const results = this.vectorStore
      ? await this.vectorStore.similaritySearch(queryEmbedding, { filter, limit })
      : [];

    log.debug("RAG query completed", { query: query.slice(0, 50), results: results.length });
    return results;
  }
}

export default RAGPipeline;
