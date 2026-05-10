// ============================================================================
// TeamSpot — Project Model
// Project management with timeline, attachments, budget, and time tracking
// ============================================================================

import mongoose from "mongoose";

const timelineEventSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    description: { type: String },
    date: { type: Date, default: Date.now },
    type: { type: String, default: "custom" },
  },
  { _id: false }
);

const attachmentSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    public_id: { type: String, required: true },
    resource_type: { type: String, required: true },
    format: { type: String },
    bytes: { type: Number },
    filename: { type: String, required: true },
    original_filename: { type: String },
    type: { type: String },
    width: { type: Number },
    height: { type: Number },
    duration: { type: Number },
    uploadedAt: { type: Date, default: Date.now },
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  { _id: true }
);

const projectSchema = new mongoose.Schema(
  {
    // ── Multi-tenancy ─────────────────────────────────────────────────────
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },

    // ── Core ──────────────────────────────────────────────────────────────
    name: { type: String, required: true, trim: true },
    key: { type: String, unique: true, sparse: true },
    description: { type: String, trim: true },
    template: { type: String, enum: ["Kanban", "Scrum", "Blank Project", "Project Management", "Task Tracking"], default: "Kanban" },
    status: { type: String, enum: ["active", "archived", "on-hold", "completed", "planning", "review", "cancelled"], default: "active" },
    priority: { type: String, enum: ["low", "medium", "high", "critical"], default: "medium" },
    color: { type: String, default: "#1E40AF" },

    // ── Flags ─────────────────────────────────────────────────────────────
    isActive: { type: Boolean, default: true },
    archived: { type: Boolean, default: false },
    completed: { type: Boolean, default: false },
    recent: { type: Boolean, default: false },
    starred: { type: Boolean, default: false },

    // ── Ownership ─────────────────────────────────────────────────────────
    teamId: { type: mongoose.Schema.Types.ObjectId, ref: "Team" },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    collaborators: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    members: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    tags: [{ type: String, trim: true, lowercase: true }],

    // ── Dates ─────────────────────────────────────────────────────────────
    startDate: { type: Date },
    endDate: { type: Date },
    lastViewed: { type: Date, default: Date.now },
    progress: { type: Number, min: 0, max: 1, default: 0 },

    // ── Attachments & Timeline ────────────────────────────────────────────
    attachments: [attachmentSchema],
    timeline: [timelineEventSchema],

    // ── Budget & Time ─────────────────────────────────────────────────────
    budget: {
      allocated: { type: Number, default: 0 },
      spent: { type: Number, default: 0 },
      currency: { type: String, default: "USD" },
    },
    timeTracking: {
      estimated: { type: Number, default: 0 },
      actual: { type: Number, default: 0 },
      unit: { type: String, default: "hours" },
    },

    // ── Settings ──────────────────────────────────────────────────────────
    settings: {
      isPublic: { type: Boolean, default: false },
      allowComments: { type: Boolean, default: true },
      notifications: { type: Boolean, default: true },
      autoArchive: { type: Boolean, default: false },
      autoArchiveDays: { type: Number, default: 90 },
    },
    customFields: { type: mongoose.Schema.Types.Mixed },

    // ── Soft delete ───────────────────────────────────────────────────────
    deletedAt: { type: Date },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

// ── Indexes ───────────────────────────────────────────────────────────────
projectSchema.index({ tenantId: 1, teamId: 1, status: 1 });
projectSchema.index({ tenantId: 1, createdBy: 1 });
projectSchema.index({ tenantId: 1, starred: 1 });
projectSchema.index({ tenantId: 1, tags: 1 });
projectSchema.index({ lastViewed: -1 });
projectSchema.index({ name: "text", description: "text" });

// ── Virtuals ──────────────────────────────────────────────────────────────
projectSchema.virtual("progressPercentage").get(function () { return Math.round(this.progress * 100); });
projectSchema.virtual("attachmentCount").get(function () { return this.attachments?.length || 0; });
projectSchema.virtual("collaboratorCount").get(function () { return this.collaborators?.length || 0; });
projectSchema.virtual("isOverdue").get(function () { return this.endDate && new Date() > this.endDate && !this.completed; });

// ── Pre-save ──────────────────────────────────────────────────────────────
projectSchema.pre("save", function (next) {
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  this.recent = this.lastViewed && this.lastViewed > oneWeekAgo;

  if (this.progress === 1 && !this.completed) { this.completed = true; this.status = "completed"; }
  else if (this.progress < 1 && this.completed) { this.completed = false; if (this.status === "completed") this.status = "active"; }
  next();
});

// ── Soft delete filter ────────────────────────────────────────────────────
projectSchema.pre(/^find/, function () {
  if (!this.getQuery().includeDeleted) this.where({ deletedAt: null });
});

// ── Methods ───────────────────────────────────────────────────────────────
projectSchema.methods.addTimelineEvent = function (title, description, type = "custom") {
  this.timeline.push({ title, description, date: new Date(), type });
  return this.save();
};

// ── Statics ───────────────────────────────────────────────────────────────
projectSchema.statics.getProjectStats = function (tenantId, teamId = null) {
  const match = { tenantId: new mongoose.Types.ObjectId(tenantId) };
  if (teamId) match.teamId = new mongoose.Types.ObjectId(teamId);
  return this.aggregate([
    { $match: match },
    { $group: { _id: null, total: { $sum: 1 }, active: { $sum: { $cond: [{ $eq: ["$status", "active"] }, 1, 0] } }, completed: { $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] } }, averageProgress: { $avg: "$progress" } } },
  ]);
};

const Project = mongoose.model("Project", projectSchema);
export default Project;
