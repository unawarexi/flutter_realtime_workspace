// ============================================================================
// TeamSpot — AI Worker
// Processes embedding generation, RAG indexing, agent tasks via RabbitMQ
// ============================================================================

import { createLogger } from "../observability/logger.js";
import { generateEmbeddings } from "../agent/knowledge/embeddings.js";

const log = createLogger("AIWorker");

export async function processAITask(job) {
  const { data } = job;

  try {
    switch (data.type) {
      case "embedding":
        await handleEmbedding(data);
        break;

      case "rag_ingest":
        await handleRAGIngest(data);
        break;

      case "agent_task":
        await handleAgentTask(data);
        break;

      case "summarize":
        await handleSummarize(data);
        break;

      default:
        log.warn("Unknown AI task type", { type: data.type });
    }
  } catch (err) {
    log.error("AI task failed", { error: err.message, type: data.type });
    throw err;
  }
}

async function handleEmbedding({ sourceType, sourceId, content, tenantId, acl }) {
  log.info("Generating embedding", { sourceType, sourceId });
  const { RAGPipeline } = await import("../agent/knowledge/rag-pipeline.js");
  const pipeline = new RAGPipeline();

  const embeddings = await generateEmbeddings([content]);
  log.info("Embedding generated", { sourceType, sourceId, dims: embeddings[0]?.length });

  // Ingest into vector DB with ACL
  await pipeline.ingest({
    content,
    metadata: {
      sourceType,
      sourceId,
      tenantId,
      visibility: acl?.visibility || "workspace",
    },
  });
  log.info("Embedding stored in vector DB", { sourceId });
}

async function handleRAGIngest({ documentId, content, metadata, tenantId, strategy }) {
  log.info("RAG ingestion", { documentId });
  const { RAGPipeline } = await import("../agent/knowledge/rag-pipeline.js");
  const pipeline = new RAGPipeline();

  await pipeline.ingest({
    content,
    metadata: { ...metadata, documentId, tenantId },
    strategy: strategy || "recursive",
  });

  // Update document indexed status if using Mongoose model
  try {
    const { default: mongoose } = await import("mongoose");
    const Document = mongoose.model("Document");
    await Document.findByIdAndUpdate(documentId, { "metadata.indexed": true, "metadata.indexedAt": new Date() });
  } catch (_) { /* model may not be loaded */ }

  log.info("RAG ingestion complete", { documentId });
}

async function handleAgentTask({ agentType, input, userId, tenantId, workspaceId, conversationId }) {
  log.info("Agent task execution", { agentType, userId });
  const { AgentExecutor } = await import("../agent/runtime/agent-executor.js");
  const executor = new AgentExecutor();
  const result = await executor.execute({ input, userId, tenantId, workspaceId, conversationId });
  log.info("Agent task complete", { agentType, outputLength: result?.output?.length });
  return result;
}

async function handleSummarize({ content, type, userId, tenantId }) {
  log.info("Content summarization", { contentType: type, userId });
  const { ModelFallback } = await import("../agent/runtime/fallback.js");
  const model = await new ModelFallback().getModel();
  const prompt = `Summarize the following ${type || "content"} concisely:\n\n${content}`;
  const response = await model.invoke(prompt);
  const summary = typeof response === "string" ? response : response.content;
  log.info("Summarization complete", { inputLength: content.length, outputLength: summary.length });
  return { summary };
}

export default { processAITask };
