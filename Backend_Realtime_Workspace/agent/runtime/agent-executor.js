// ============================================================================
// TeamSpot — Agent Executor (LangGraph)
// LangGraph StateGraph for durable, resumable multi-step AI workloads.
// Fast-path (single LangChain invoke) available for trivial requests.
// ============================================================================

import { StateGraph, MessagesAnnotation, END, START } from "@langchain/langgraph";
import { ToolNode } from "@langchain/langgraph/prebuilt";
import { HumanMessage, SystemMessage, AIMessage } from "@langchain/core/messages";
import { ToolRegistry } from "./tool-registry.js";
import { streamGraphResponse } from "./streaming.js";
import { ModelFallback } from "./fallback.js";
import { ConversationMemory } from "../memory/conversation-memory.js";
import { PromptGuard } from "../governance/prompt-guard.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("AgentExecutor");

// ============================================================================
// SYSTEM PROMPT
// ============================================================================

const SYSTEM_PROMPT = `You are TeamSpot AI — an intelligent workspace assistant.
You help users manage projects, tasks, issues, meetings, and team collaboration.
You have access to workspace tools and knowledge through RAG retrieval.

RULES:
- Always respect user permissions — never expose data the user cannot access.
- When creating or modifying resources, confirm the action before proceeding.
- Cite sources when retrieving information from documents.
- Be concise but thorough. Use markdown formatting.
- If unsure, say so rather than guessing.`;

// ============================================================================
// LANGGRAPH EXECUTOR
// ============================================================================

export class AgentExecutor {
  constructor(options = {}) {
    this.toolRegistry = options.toolRegistry || new ToolRegistry();
    this.memory       = options.memory       || new ConversationMemory();
    this.guard        = options.guard        || new PromptGuard();
    this.maxIterations = options.maxIterations || 10;
    this.model = null;
  }

  /** Lazy-initialize the LLM via fallback chain */
  async _getModel() {
    if (!this.model) {
      this.model = await new ModelFallback().getModel();
      log.info("Model initialized", { model: this.model?.constructor?.name });
    }
    return this.model;
  }

  /**
   * Build a LangGraph ReAct StateGraph:
   *   START → call_model → (tool_calls?) → execute_tools → call_model → … → END
   *
   * The graph is compiled fresh per request so tool sets can vary by permissions.
   * For warm paths with static tool sets, callers may cache the compiled graph.
   *
   * @param {Object} model   — Bound LLM
   * @param {Array}  tools   — LangChain Tool instances (permission-filtered)
   * @param {Object} [checkpointer] — LangGraph checkpointer for durable mode
   */
  _buildGraph(model, tools, checkpointer = undefined) {
    const toolNode = tools.length > 0 ? new ToolNode(tools) : null;
    const modelWithTools = tools.length > 0 ? model.bindTools(tools) : model;

    const callModel = async (state) => {
      const response = await modelWithTools.invoke(state.messages);
      return { messages: [response] };
    };

    const shouldUseTool = (state) => {
      const last = state.messages[state.messages.length - 1];
      return last?.tool_calls?.length > 0 ? "execute_tools" : END;
    };

    const builder = new StateGraph(MessagesAnnotation)
      .addNode("call_model", callModel)
      .addEdge(START, "call_model")
      .addConditionalEdges("call_model", shouldUseTool, {
        execute_tools: "execute_tools",
        [END]: END,
      });

    if (toolNode) {
      builder.addNode("execute_tools", toolNode).addEdge("execute_tools", "call_model");
    } else {
      // No tools — always END after call_model
      builder.addNode("execute_tools", callModel).addEdge("execute_tools", "call_model");
    }

    return builder.compile({
      checkpointer,
      recursionLimit: this.maxIterations,
    });
  }

  /**
   * Execute an agent turn.
   *
   * @param {Object}  p
   * @param {string}  p.input          — User message
   * @param {string}  p.userId         — Auth user ID
   * @param {string}  p.tenantId       — Tenant scope
   * @param {string}  p.workspaceId    — Workspace scope
   * @param {Object}  p.permissions    — Permission map {canCreateTasks, …}
   * @param {string}  [p.conversationId] — Memory key (defaults to userId)
   * @param {boolean} [p.stream=false] — Enable SSE streaming
   * @param {Object}  [p.res]          — Express response object (SSE)
   * @param {boolean} [p.durable=true] — true = LangGraph; false = fast LangChain invoke
   */
  async execute({
    input,
    userId,
    tenantId,
    workspaceId,
    permissions = {},
    conversationId,
    stream = false,
    res,
    durable = true,
  }) {
    // ── 1. Prompt injection guard ─────────────────────────────────────────
    const guardResult = await this.guard.check(input);
    if (guardResult.blocked) {
      log.warn("Prompt blocked by guard", { userId, reason: guardResult.reason });
      return { content: "I can\'t process that request. Please rephrase.", blocked: true };
    }

    // ── 2. Load conversation history ──────────────────────────────────────
    const history = await this.memory.getHistory(conversationId || userId, { limit: 20 });

    // ── 3. Build messages ─────────────────────────────────────────────────
    const messages = [
      new SystemMessage(SYSTEM_PROMPT),
      ...history.map((m) =>
        m.role === "user" ? new HumanMessage(m.content) : new AIMessage(m.content)
      ),
      new HumanMessage(input),
    ];

    // ── 4. Permission-filtered tools ──────────────────────────────────────
    const tools = this.toolRegistry.getTools({ userId, tenantId, workspaceId, permissions });

    try {
      const model = await this._getModel();
      let response;

      if (durable) {
        // ── LangGraph path (durable, multi-step, resumable) ───────────────
        log.info("Executing via LangGraph", { userId, toolCount: tools.length });
        const graph = this._buildGraph(model, tools);

        if (stream && res) {
          response = await streamGraphResponse(graph, { messages }, res);
        } else {
          const result = await graph.invoke({ messages });
          const last = result.messages[result.messages.length - 1];
          response = { content: last.content, toolCalls: last.tool_calls || [] };
        }
      } else {
        // ── Fast path — single LangChain invoke ───────────────────────────
        log.info("Executing via fast-path", { userId });
        const m = tools.length > 0 ? model.bindTools(tools) : model;
        const result = await m.invoke(messages);
        response = { content: result.content, toolCalls: result.tool_calls || [] };
      }

      // ── 5. Persist to memory ──────────────────────────────────────────
      const memKey = conversationId || userId;
      await this.memory.addMessage(memKey, { role: "user", content: input });
      await this.memory.addMessage(memKey, { role: "assistant", content: response.content || "" });

      return response;
    } catch (err) {
      log.error("Agent execution failed", { error: err.message, userId });
      return {
        content: "I encountered an error processing your request. Please try again.",
        error: err.message,
      };
    }
  }

  /**
   * Run a durable background workflow with LangGraph checkpointing.
   * Designed for long-running tasks triggered from workers (ai.worker.js).
   * The workflow is resumable — if interrupted, re-invoke with the same workflowId.
   *
   * @param {Object} p
   * @param {string} p.workflowId  — Unique ID used as LangGraph thread_id
   * @param {string} p.input       — Task description or user intent
   * @param {string} p.userId
   * @param {string} p.tenantId
   * @param {Object} [p.permissions]
   */
  async runDurableWorkflow({ workflowId, input, userId, tenantId, permissions = {} }) {
    const { MemorySaver } = await import("@langchain/langgraph");
    const checkpointer = new MemorySaver();

    const model = await this._getModel();
    const tools = this.toolRegistry.getTools({ userId, tenantId, permissions });
    const graph = this._buildGraph(model, tools, checkpointer);

    log.info("Starting durable workflow", { workflowId, userId });

    const config = { configurable: { thread_id: workflowId } };
    const result = await graph.invoke(
      { messages: [new SystemMessage(SYSTEM_PROMPT), new HumanMessage(input)] },
      config
    );

    const last = result.messages[result.messages.length - 1];
    log.info("Durable workflow complete", { workflowId, outputLen: last?.content?.length });
    return { content: last?.content, workflowId };
  }
}

export default AgentExecutor;
