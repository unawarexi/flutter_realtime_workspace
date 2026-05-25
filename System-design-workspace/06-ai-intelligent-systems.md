# 06 — AI & Intelligent Systems
# TeamSpot: LangGraph Agent, RAG Pipeline, MCP, Embeddings & AI Governance

---

## 1. AI Architecture Overview

TeamSpot's AI subsystem is not a simple chatbot. It is a **permission-aware, context-grounded, tool-augmented reasoning agent** built on LangGraph's StateGraph. The architecture separates concerns cleanly:

```
┌────────────────────────────────────────────────────────────────────┐
│                     AI INFRASTRUCTURE                               │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────────┐ │
│  │  AI Runtime  │  │ AI Knowledge│  │     AI Governance           │ │
│  │  Layer       │  │  Layer      │  │                             │ │
│  │  ─────────── │  │  ─────────  │  │  • Prompt injection guard   │ │
│  │  LangGraph   │  │  RAG +      │  │  • Permission enforcement   │ │
│  │  StateGraph  │  │  Qdrant     │  │  • Hallucination mitigation │ │
│  │  ReAct loop  │  │  embeddings │  │  • Audit logging            │ │
│  │  Tool calls  │  │  ACL filter │  │  • Token accounting         │ │
│  │  Streaming   │  │  retrieval  │  │  • Rate limiting            │ │
│  └─────────────┘  └─────────────┘  └────────────────────────────┘ │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────────┐ │
│  │  AI Memory   │  │  AI Tools   │  │     Model Fallback Chain    │ │
│  │  ─────────── │  │  ─────────  │  │  ──────────────────────── │ │
│  │  Conversation│  │  MCP server │  │  OpenRouter → GPT-4o        │ │
│  │  history     │  │  search_ws  │  │  → Claude Sonnet            │ │
│  │  Redis+Mongo │  │  create_task│  │  → Gemini Flash             │ │
│  │  Summarize   │  │  list_tasks │  │  → Mistral-7B (free)        │ │
│  └─────────────┘  └─────────────┘  └────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. LangGraph StateGraph: ReAct Agent

The agent uses a **ReAct loop** (Reason → Act → Observe → Reason...) implemented as a LangGraph StateGraph:

> **See** [`Backend_Realtime_Workspace/agent/runtime/agent-executor.js`](../Backend_Realtime_Workspace/agent/runtime/agent-executor.js) — `AgentExecutor` — LangGraph `StateGraph` ReAct loop, `ToolRegistry`, `ModelFallback`

### Why LangGraph over Simple LangChain Chains?

| Feature | LangChain Chain | LangGraph StateGraph |
|---------|----------------|---------------------|
| Multi-step reasoning | Limited | Native |
| Durable/resumable execution | No | Yes (checkpointers) |
| Tool call → observe → reason loop | Manual | Built-in ReAct |
| Human-in-the-loop approval | No | Yes |
| Streaming with tool calls | Complex | Native |
| State inspection / debugging | Hard | Graph visualization |

---

## 3. Model Fallback Chain

> **See** [`Backend_Realtime_Workspace/agent/runtime/fallback.js`](../Backend_Realtime_Workspace/agent/runtime/fallback.js) — `ModelFallback` — GPT-4o → Claude 3.5 → Cohere fallback chain

The fallback chain ensures the AI feature never goes completely dark. If OpenAI has an outage, the system automatically routes to Anthropic, then Google, then a free-tier model. Quality degrades gracefully rather than failing completely.

---

## 4. AI Tool Registry

Tools are the mechanism by which the agent acts on the workspace. Each tool is permission-gated — the agent cannot call a tool for resources the user cannot access.

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

---

## 5. RAG Pipeline

The RAG (Retrieval-Augmented Generation) pipeline makes the AI agent knowledge-grounded on workspace content.

### Ingestion Flow

```
Document uploaded (PDF/DOCX/XLSX/MD)
         │
         ▼
document-parser.js:
  extractTextFromPDF() / extractTextFromDocx()
  parseSpreadsheet() / parseMarkdown()
  → { text, metadata: { source, pages, tables, headings } }
         │
         ▼
chunking.js:
  chunkDocument(text, { strategy: 'recursive', chunkSize: 1500, overlap: 200 })
  → Array of text chunks with position metadata
         │
         ▼
Kafka: teamspot.rag.ingest
         │
         ▼
AI Worker (ai.worker.js):
         │
         ▼
embeddings.js:
  generateEmbeddings(chunks)
  → OpenAI text-embedding-3-small (1536 dim)
  → Fallback: Cohere embed-multilingual-v3
  → Fallback: HuggingFace all-MiniLM-L6-v2
  → Dev fallback: hash-based mock
         │
         ▼
Qdrant Vector DB:
  Collection: 'teamspot_documents'
  Point: {
    id: chunkId,
    vector: float[1536],
    payload: {
      documentId, tenantId, workspaceId,
      text, source, pageNumber,
      allowedRoles, allowedUsers,  // ACL
    }
  }
```

### ACL-Filtered Retrieval

This is the most security-critical part of the RAG system. The retriever must NEVER return chunks from documents the user cannot access:

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

**Why this matters**: Without ACL filtering in the vector search, the AI could retrieve and expose confidential HR documents, executive financials, or private project notes to users who don't have access. This is not hypothetical — several AI systems have leaked sensitive enterprise data this way.

### Chunking Strategies

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

---

## 6. MCP (Model Context Protocol) Server

TeamSpot exposes an MCP server so that external AI clients (Claude Desktop, other agents) can interact with the workspace.

> **See** [`Backend_Realtime_Workspace/agent/runtime/agent-executor.js`](../Backend_Realtime_Workspace/agent/runtime/agent-executor.js) — `AgentExecutor` — LangGraph `StateGraph` ReAct loop, `ToolRegistry`, `ModelFallback`

Resource URIs follow the MCP spec:
- `workspace://{workspaceId}` — workspace metadata
- `project://{projectId}` — project detail + tasks summary
- `document://{documentId}` — document content + metadata

---

## 7. AI Governance

### Prompt Injection Defense

> **See** [`Backend_Realtime_Workspace/agent/governance/prompt-guard.js`](../Backend_Realtime_Workspace/agent/governance/prompt-guard.js) — `PromptGuard.check()` — prompt injection detection and sanitisation

### AI Audit Logger

Every AI interaction is logged for compliance and debugging:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Hallucination Mitigation

1. **Source citation**: System prompt instructs agent to cite document sources for retrieved information
2. **Tool grounding**: Agent retrieves real data via tools rather than generating from memory
3. **Confidence thresholds**: RAG retrieval includes similarity scores; low-confidence results are discarded
4. **Human approval gates**: For destructive actions (delete, bulk update), agent must present plan and await user confirmation

---

## 8. Conversation Memory

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

---

## 9. Embedding Strategy & Cost Optimization

```
Embedding cost hierarchy:
1. OpenAI text-embedding-3-small: $0.02/1M tokens (best quality)
2. Cohere embed-multilingual-v3:  $0.10/1M tokens (multilingual)  
3. HuggingFace all-MiniLM-L6-v2: Free via Inference API (backup)
4. Dev hash fallback:             Free (deterministic, for testing only)

Cost optimization:
- Cache embeddings per chunk (content hash → embedding)
- Batch embedding requests: never embed one chunk at a time
- Async indexing: never block user uploads on embedding generation
- Embedding versioning: track model version per vector for re-indexing
```

### Re-indexing Strategy

When the embedding model changes (e.g., OpenAI releases a better model):
1. New model version is configured
2. Background migration job reads all documents from MongoDB
3. Re-generates embeddings in batches
4. Upserts to Qdrant with `model_version` payload field
5. Old vectors remain searchable during migration (dual-read period)
6. After migration completes, old vectors are pruned
