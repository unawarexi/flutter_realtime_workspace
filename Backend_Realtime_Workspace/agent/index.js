// ============================================================================
// TeamSpot — Agent Bootstrap
// Initializes all AI agent subsystems
// ============================================================================

import { createLogger } from "../observability/logger.js";

const log = createLogger("Agent");

let isInitialized = false;

export async function initAgent() {
  if (isInitialized) return;

  log.info("Initializing AI agent subsystems...");

  // Runtime, memory, knowledge, governance layers are lazy-loaded
  // by the agent executor when first request arrives

  isInitialized = true;
  log.success("AI agent subsystem ready");
}

export { AgentExecutor } from "./runtime/agent-executor.js";
export { ToolRegistry } from "./runtime/tool-registry.js";
export { streamResponse } from "./runtime/streaming.js";
export { ConversationMemory } from "./memory/conversation-memory.js";
export { RAGPipeline } from "./knowledge/rag-pipeline.js";
export { PromptGuard } from "./governance/prompt-guard.js";

export default { initAgent };
