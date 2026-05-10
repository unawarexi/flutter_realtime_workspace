// ============================================================================
// TeamSpot — Workspace Model
// Workspaces within organizations for project/team isolation
// ============================================================================

import mongoose from "mongoose";

const workspaceSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, lowercase: true, trim: true },
    description: { type: String },
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },

    // Appearance
    icon: { type: String },
    color: { type: String, default: "#6366F1" },
    coverImage: { type: String },

    // Members
    members: [{
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },
      role: { type: String, enum: ["workspace_admin", "manager", "member", "guest"], default: "member" },
      joinedAt: { type: Date, default: Date.now },
    }],

    // Settings
    settings: {
      visibility: { type: String, enum: ["public", "private", "invite_only"], default: "private" },
      defaultProjectTemplate: { type: String, enum: ["kanban", "scrum", "blank"], default: "kanban" },
      allowGuests: { type: Boolean, default: false },
      notificationsEnabled: { type: Boolean, default: true },
    },

    // Status
    status: { type: String, enum: ["active", "archived", "deleted"], default: "active" },
    archivedAt: { type: Date },

    // Counts (denormalized for performance)
    projectCount: { type: Number, default: 0 },
    memberCount: { type: Number, default: 1 },
    channelCount: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    indexes: [
      { tenantId: 1, orgId: 1 },
      { slug: 1, orgId: 1 },
      { "members.userId": 1 },
      { status: 1 },
    ],
  }
);

workspaceSchema.index({ tenantId: 1, slug: 1 }, { unique: true });
workspaceSchema.index({ name: "text", description: "text" });

const Workspace = mongoose.model("Workspace", workspaceSchema);
export default Workspace;
