// ============================================================================
// TeamSpot — Ticket Model
// ============================================================================

import mongoose from "mongoose";

const ticketSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String },
    ticketNumber: { type: String, unique: true },
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace" },
    type: { type: String, enum: ["bug", "feature", "support", "question", "incident"], default: "support" },
    priority: { type: String, enum: ["critical", "high", "medium", "low"], default: "medium" },
    status: { type: String, enum: ["open", "in_progress", "waiting", "resolved", "closed"], default: "open" },
    category: { type: String },
    tags: [{ type: String }],
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    assignee: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    watchers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    comments: [{
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
      content: { type: String, required: true },
      internal: { type: Boolean, default: false },
      createdAt: { type: Date, default: Date.now },
    }],
    attachments: [{
      url: { type: String }, publicId: { type: String },
      filename: { type: String }, mimeType: { type: String }, bytes: { type: Number },
    }],
    relatedTo: { type: { type: String, enum: ["project", "task", "issue"] }, id: { type: mongoose.Schema.Types.ObjectId } },
    sla: { responseDeadline: { type: Date }, resolutionDeadline: { type: Date }, breached: { type: Boolean, default: false } },
    resolvedAt: { type: Date },
    closedAt: { type: Date },
    firstResponseAt: { type: Date },
  },
  { timestamps: true }
);

ticketSchema.index({ tenantId: 1, status: 1 });
ticketSchema.index({ assignee: 1, status: 1 });
ticketSchema.index({ title: "text", description: "text" });

const Ticket = mongoose.model("Ticket", ticketSchema);
export default Ticket;
