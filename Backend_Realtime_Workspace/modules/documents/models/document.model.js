// ============================================================================
// TeamSpot — Document Model
// ============================================================================

import mongoose from "mongoose";

const documentSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace" },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },
    type: { type: String, enum: ["pdf", "docx", "xlsx", "pptx", "image", "video", "audio", "markdown", "text", "csv", "other"], required: true },
    file: {
      url: { type: String, required: true },
      publicId: { type: String },
      filename: { type: String, required: true },
      mimeType: { type: String, required: true },
      bytes: { type: Number },
      checksum: { type: String },
    },
    // Parsed content (from document parser)
    parsedContent: { type: String },
    metadata: { pageCount: { type: Number }, wordCount: { type: Number }, author: { type: String }, language: { type: String } },
    // RAG integration
    indexed: { type: Boolean, default: false },
    indexedAt: { type: Date },
    embeddingIds: [{ type: String }],
    chunkCount: { type: Number, default: 0 },
    // Access control
    visibility: { type: String, enum: ["private", "workspace", "organization", "public"], default: "workspace" },
    sharedWith: [{ userId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" }, permission: { type: String, enum: ["view", "edit"], default: "view" } }],
    // Versioning
    version: { type: Number, default: 1 },
    versions: [{ version: { type: Number }, url: { type: String }, uploadedAt: { type: Date, default: Date.now }, uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" } }],
    tags: [{ type: String }],
    status: { type: String, enum: ["active", "archived", "deleted"], default: "active" },
    deletedAt: { type: Date },
  },
  { timestamps: true }
);

documentSchema.index({ tenantId: 1, workspaceId: 1 });
documentSchema.index({ title: "text", "file.filename": "text", tags: "text" });

const Document = mongoose.model("Document", documentSchema);
export default Document;
