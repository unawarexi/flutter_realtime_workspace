// ============================================================================
// TeamSpot — AI Models (Conversation + Embedding)
// ============================================================================

import mongoose from "mongoose";

const conversationSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },
  workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace" },
  agentType: { type: String, enum: ["workspace", "project", "code", "meeting", "analytics", "hr", "security"], default: "workspace" },
  title: { type: String },
  messages: [{
    role: { type: String, enum: ["user", "assistant", "system", "tool"], required: true },
    content: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    metadata: { type: mongoose.Schema.Types.Mixed },
    toolCalls: [{ name: { type: String }, arguments: { type: mongoose.Schema.Types.Mixed }, result: { type: mongoose.Schema.Types.Mixed } }],
  }],
  context: {
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
    channelId: { type: mongoose.Schema.Types.ObjectId, ref: "Channel" },
    meetingId: { type: mongoose.Schema.Types.ObjectId, ref: "ScheduleMeet" },
  },
  tokenUsage: { input: { type: Number, default: 0 }, output: { type: Number, default: 0 }, total: { type: Number, default: 0 } },
  model: { type: String },
  status: { type: String, enum: ["active", "archived"], default: "active" },
}, { timestamps: true });

conversationSchema.index({ tenantId: 1, userId: 1, createdAt: -1 });

export const Conversation = mongoose.model("Conversation", conversationSchema);

const embeddingSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  sourceType: { type: String, enum: ["document", "message", "task", "issue", "meeting_note", "wiki"], required: true },
  sourceId: { type: mongoose.Schema.Types.ObjectId, required: true },
  chunkIndex: { type: Number, default: 0 },
  content: { type: String, required: true },
  metadata: { title: { type: String }, projectId: { type: String }, workspaceId: { type: String }, tags: [{ type: String }] },
  vectorId: { type: String }, // ID in vector database (Qdrant/Pinecone)
  model: { type: String, default: "text-embedding-3-small" },
  dimensions: { type: Number, default: 1536 },
  // ACL for permission-aware retrieval
  acl: {
    visibility: { type: String, enum: ["private", "workspace", "organization"], default: "workspace" },
    allowedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" }],
    allowedRoles: [{ type: String }],
  },
}, { timestamps: true });

embeddingSchema.index({ tenantId: 1, sourceType: 1, sourceId: 1 });
embeddingSchema.index({ "acl.visibility": 1 });

export const Embedding = mongoose.model("Embedding", embeddingSchema);
