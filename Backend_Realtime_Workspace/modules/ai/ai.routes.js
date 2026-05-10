// ============================================================================
// TeamSpot — AI Routes
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import {
  chat,
  getConversations,
  getConversation,
  deleteConversation,
  ragQuery,
  ragIngest,
  ragStatus,
  listTools,
  executeTool,
  summarize,
} from "./ai.controller.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Chat (supports ?stream=true for SSE)
router.post("/chat", chat);

// Conversation management
router.get("/conversations", getConversations);
router.get("/conversations/:id", getConversation);
router.delete("/conversations/:id", deleteConversation);

// RAG pipeline
router.post("/rag/query", ragQuery);
router.post("/rag/ingest", ragIngest);
router.get("/rag/status", ragStatus);

// Agent tools
router.get("/tools", listTools);
router.post("/tools/:name/execute", executeTool);

// Summarization
router.post("/summarize", summarize);

export default router;
