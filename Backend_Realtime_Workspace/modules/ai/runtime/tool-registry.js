// ============================================================================
// TeamSpot — AI Tool Registry
// Available tools for AI agents to use
// ============================================================================

import { createLogger } from "../../observability/logger.js";

const log = createLogger("AIToolRegistry");

const tools = new Map();

/**
 * Register a tool that agents can use.
 * @param {Object} tool
 * @param {string} tool.name — unique tool identifier
 * @param {string} tool.description — what the tool does (for LLM)
 * @param {Object} tool.parameters — JSON schema of parameters
 * @param {Function} tool.execute — async (args, context) => result
 * @param {string[]} tool.requiredPermissions — permissions needed to use
 */
export function registerTool(tool) {
  tools.set(tool.name, tool);
  log.debug(`Tool registered: ${tool.name}`);
}

export function getToolByName(name) {
  return tools.get(name);
}

export function getAvailableTools(userPermissions = []) {
  const available = [];
  for (const [, tool] of tools) {
    const hasPermission = !tool.requiredPermissions ||
      tool.requiredPermissions.every((p) => userPermissions.includes(p));
    if (hasPermission) {
      available.push({
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters,
      });
    }
  }
  return available;
}

// ── Built-in Tools ──────────────────────────────────────────────────────────

registerTool({
  name: "search_workspace",
  description: "Search across projects, tasks, documents, and channels in the workspace",
  parameters: { type: "object", properties: { query: { type: "string" }, resource: { type: "string", enum: ["all", "projects", "tasks", "documents", "channels"] } } },
  execute: async (args, context) => {
    // TODO: Wire to search service
    return { results: [], query: args.query };
  },
});

registerTool({
  name: "create_task",
  description: "Create a new task in a project",
  parameters: { type: "object", properties: { title: { type: "string" }, description: { type: "string" }, projectId: { type: "string" }, assigneeId: { type: "string" }, priority: { type: "string" } } },
  requiredPermissions: ["create:task"],
  execute: async (args, context) => {
    // TODO: Wire to task service
    return { created: true, task: args };
  },
});

registerTool({
  name: "summarize_meeting",
  description: "Summarize a meeting's chat transcript and key decisions",
  parameters: { type: "object", properties: { meetingId: { type: "string" } } },
  requiredPermissions: ["read:meeting"],
  execute: async (args, context) => {
    // TODO: Wire to meeting + AI service
    return { summary: "Meeting summary placeholder" };
  },
});

registerTool({
  name: "query_knowledge_base",
  description: "Query the organization's knowledge base using RAG",
  parameters: { type: "object", properties: { query: { type: "string" }, filters: { type: "object" } } },
  execute: async (args, context) => {
    // TODO: Wire to RAG retriever
    return { documents: [], query: args.query };
  },
});

export default { registerTool, getToolByName, getAvailableTools };
