// ============================================================================
// TeamSpot — AI Service
// Wires HTTP request context to the agent/ subsystem (AgentExecutor, RAGPipeline)
// ============================================================================

import { AgentExecutor } from "../../agent/runtime/agent-executor.js";
import { RAGPipeline } from "../../agent/knowledge/rag-pipeline.js";
import { ToolRegistry } from "../../agent/runtime/tool-registry.js";
import { Conversation } from "./models/conversation.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { createLogger } from "../../observability/logger.js";
import { parsePagination, paginationMeta } from "../../core/utils/pagination.js";

const log = createLogger("AIService");

export class AIService {
  constructor() {
    this.executor = new AgentExecutor();
    this.ragPipeline = new RAGPipeline();
    this.toolRegistry = new ToolRegistry();
  }

  // -------------------------------------------------------------------------
  // Chat / Agent execution
  // -------------------------------------------------------------------------
  async handleChat({ input, userId, tenantId, workspaceId, conversationId, agentType, context, permissions, stream, res }) {
    log.info("handleChat called", { userId, tenantId, workspaceId, stream });

    // Load or create conversation
    let conversation;
    if (conversationId) {
      conversation = await Conversation.findOne({ _id: conversationId, userId, tenantId });
      if (!conversation) throw AppError.notFound("Conversation");
    } else {
      conversation = await Conversation.create({
        tenantId,
        userId,
        workspaceId,
        agentType: agentType || "workspace",
        title: input.slice(0, 80),
        messages: [],
        context: context || {},
      });
    }

    // Execute agent
    const result = await this.executor.execute({
      input,
      userId,
      tenantId,
      workspaceId,
      conversationId: conversation._id.toString(),
      permissions,
      stream: stream || false,
      res,
    });

    if (stream) return; // SSE — response already written by executor

    // Persist messages
    await Conversation.findByIdAndUpdate(conversation._id, {
      $push: {
        messages: [
          { role: "user", content: input, timestamp: new Date() },
          { role: "assistant", content: result.output || "", timestamp: new Date(), metadata: { model: result.model, tokenUsage: result.tokenUsage } },
        ],
      },
      $inc: {
        "tokenUsage.input": result.tokenUsage?.input || 0,
        "tokenUsage.output": result.tokenUsage?.output || 0,
        "tokenUsage.total": result.tokenUsage?.total || 0,
      },
      model: result.model,
    });

    return {
      conversationId: conversation._id,
      output: result.output,
      model: result.model,
      tokenUsage: result.tokenUsage,
    };
  }

  // -------------------------------------------------------------------------
  // Conversation management
  // -------------------------------------------------------------------------
  async listConversations({ userId, tenantId, workspaceId, agentType, page, limit }) {
    const filter = { userId, tenantId, status: "active" };
    if (workspaceId) filter.workspaceId = workspaceId;
    if (agentType) filter.agentType = agentType;

    const total = await Conversation.countDocuments(filter);
    const { skip, limit: lim } = parsePagination({ page, limit });
    const conversations = await Conversation.find(filter)
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(lim)
      .select("-messages")
      .lean();

    return { conversations, pagination: paginationMeta(page, lim, total) };
  }

  async getConversation({ id, userId, tenantId }) {
    return Conversation.findOne({ _id: id, userId, tenantId }).lean();
  }

  async deleteConversation({ id, userId, tenantId }) {
    const conv = await Conversation.findOne({ _id: id, userId, tenantId });
    if (!conv) throw AppError.notFound("Conversation");
    await conv.deleteOne();
  }

  // -------------------------------------------------------------------------
  // RAG
  // -------------------------------------------------------------------------
  async ragQuery({ query, userId, tenantId, workspaceId, limit, filters }) {
    return this.ragPipeline.query({ query, userId, tenantId, workspaceId, limit, filters });
  }

  async ragIngest({ content, metadata, strategy }) {
    return this.ragPipeline.ingest({ content, metadata, strategy });
  }

  async ragStatus({ tenantId }) {
    // Return basic pipeline health
    return {
      tenantId,
      status: "operational",
      providers: {
        embeddings: "active",
        vectorStore: "active",
      },
      timestamp: new Date().toISOString(),
    };
  }

  // -------------------------------------------------------------------------
  // Tools
  // -------------------------------------------------------------------------
  async listTools({ permissions }) {
    const tools = this.toolRegistry.getTools({ permissions });
    return tools.map((t) => ({ name: t.name, description: t.description, schema: t.schema }));
  }

  async executeTool({ name, args, userId, tenantId, permissions }) {
    const tools = this.toolRegistry.getTools({ permissions });
    const tool = tools.find((t) => t.name === name);
    if (!tool) throw AppError.notFound(`Tool "${name}"`);
    return tool.execute({ args, userId, tenantId });
  }

  // -------------------------------------------------------------------------
  // Summarize
  // -------------------------------------------------------------------------
  async summarize({ content, type, maxLength, userId, tenantId }) {
    const { ModelFallback } = await import("../../agent/runtime/fallback.js");
    const model = await new ModelFallback().getModel();
    const prompt = `Summarize the following ${type || "content"} concisely${maxLength ? ` in under ${maxLength} words` : ""}:\n\n${content}`;
    const response = await model.invoke(prompt);
    return {
      summary: typeof response === "string" ? response : response.content,
      type,
      originalLength: content.length,
    };
  }
}

export default AIService;
