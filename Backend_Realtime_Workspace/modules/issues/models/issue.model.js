// ============================================================================
// TeamSpot — Issue Model
// ============================================================================
import mongoose from "mongoose";

const issueSchema = new mongoose.Schema(
  {
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String },
    key: { type: String, unique: true, sparse: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    priority: { type: String, enum: ["lowest", "low", "medium", "high", "critical"], default: "medium" },
    status: { type: String, enum: ["open", "in_progress", "resolved", "closed", "reopened", "wont_fix"], default: "open", index: true },
    type: { type: String, enum: ["bug", "feature", "improvement", "task", "epic", "story"], default: "bug" },
    severity: { type: String, enum: ["trivial", "minor", "major", "blocker"], default: "minor" },
    tags: [{ type: String, trim: true }],
    labels: [{ type: String, trim: true }],
    comments: [{
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
      content: { type: String, required: true },
      createdAt: { type: Date, default: Date.now },
    }],
    attachments: [{ url: String, filename: String, bytes: Number }],
    dueDate: { type: Date },
    resolvedAt: { type: Date },
    closedAt: { type: Date },
    environment: { type: String },
    stepsToReproduce: { type: String },
    expectedBehavior: { type: String },
    actualBehavior: { type: String },
    linkedIssues: [{ issueId: { type: mongoose.Schema.Types.ObjectId, ref: "Issue" }, relation: { type: String, enum: ["blocks", "blocked_by", "duplicates", "related_to"] } }],
    deletedAt: { type: Date },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

issueSchema.index({ tenantId: 1, projectId: 1, status: 1 });
issueSchema.index({ tenantId: 1, assignedTo: 1 });
issueSchema.index({ title: "text", description: "text" });
issueSchema.pre(/^find/, function () { if (!this.getQuery().includeDeleted) this.where({ deletedAt: null }); });

const Issue = mongoose.model("Issue", issueSchema);
export default Issue;
