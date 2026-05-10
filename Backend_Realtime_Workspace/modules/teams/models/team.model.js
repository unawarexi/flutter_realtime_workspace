// ============================================================================
// TeamSpot — Team Model
// Teams with members, roles, permissions, invites, and activity tracking
// ============================================================================

import mongoose from "mongoose";
import crypto from "crypto";

// ── Sub-schemas ───────────────────────────────────────────────────────────────

const activitySchema = new mongoose.Schema({
  type: { type: String, enum: ["member_joined", "member_left", "member_role_changed", "member_invited", "project_created", "project_completed", "team_updated", "settings_changed"], required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  target: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
  description: { type: String, required: true },
  metadata: { type: mongoose.Schema.Types.Mixed },
  timestamp: { type: Date, default: Date.now },
}, { _id: false });

const teamMemberSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  role: { type: String, enum: ["owner", "admin", "manager", "member", "viewer", "guest"], default: "member" },
  permissions: {
    canCreateProjects: { type: Boolean, default: true },
    canDeleteProjects: { type: Boolean, default: false },
    canManageMembers: { type: Boolean, default: false },
    canInviteMembers: { type: Boolean, default: false },
    canChangeSettings: { type: Boolean, default: false },
    canViewAllProjects: { type: Boolean, default: true },
    canExportData: { type: Boolean, default: false },
    canManageIntegrations: { type: Boolean, default: false },
  },
  joinedAt: { type: Date, default: Date.now },
  invitedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  status: { type: String, enum: ["active", "invited", "suspended", "removed"], default: "active" },
  lastActive: { type: Date, default: Date.now },
  notificationSettings: {
    email: { type: Boolean, default: true },
    push: { type: Boolean, default: true },
    projectUpdates: { type: Boolean, default: true },
    mentions: { type: Boolean, default: true },
  },
}, { _id: false });

const inviteSchema = new mongoose.Schema({
  email: { type: String, required: true },
  role: { type: String, enum: ["admin", "manager", "member", "viewer", "guest"], default: "member" },
  invitedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  token: { type: String, required: true, unique: true },
  message: { type: String },
  invitedAt: { type: Date, default: Date.now },
  expiresAt: { type: Date, required: true },
  acceptedAt: { type: Date },
  status: { type: String, enum: ["pending", "accepted", "expired", "cancelled"], default: "pending" },
}, { _id: true });

// ── Main schema ───────────────────────────────────────────────────────────────

const teamSchema = new mongoose.Schema(
  {
    // ── Multi-tenancy ─────────────────────────────────────────────────────
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },

    // ── Core ──────────────────────────────────────────────────────────────
    name: { type: String, required: true, trim: true },
    slug: { type: String, unique: true, sparse: true },
    description: { type: String, trim: true },
    avatar: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },

    // ── Classification ────────────────────────────────────────────────────
    industry: { type: String },
    size: { type: String, enum: ["1-10", "11-50", "51-100", "101-500", "500+"] },
    type: { type: String, enum: ["company", "agency", "startup", "non-profit", "educational", "personal"], default: "company" },

    // ── Status ────────────────────────────────────────────────────────────
    status: { type: String, enum: ["active", "archived", "suspended"], default: "active" },
    isActive: { type: Boolean, default: true },

    // ── Members & Invites ─────────────────────────────────────────────────
    members: [teamMemberSchema],
    invites: [inviteSchema],
    memberLimit: { type: Number, default: 50 },
    projects: [{ type: mongoose.Schema.Types.ObjectId, ref: "Project" }],

    // ── Settings ──────────────────────────────────────────────────────────
    settings: {
      isPublic: { type: Boolean, default: false },
      requireApprovalForJoining: { type: Boolean, default: true },
      allowMemberInvites: { type: Boolean, default: true },
      defaultProjectTemplate: { type: String, default: "Kanban" },
      timezone: { type: String, default: "UTC" },
      workingDays: { type: [String], default: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"] },
    },

    // ── Subscription ──────────────────────────────────────────────────────
    subscription: {
      plan: { type: String, enum: ["free", "basic", "pro", "enterprise"], default: "free" },
      status: { type: String, enum: ["active", "cancelled", "expired"], default: "active" },
      expiresAt: { type: Date },
    },

    // ── Activity & Stats ──────────────────────────────────────────────────
    activities: [activitySchema],
    stats: {
      totalProjects: { type: Number, default: 0 },
      activeProjects: { type: Number, default: 0 },
      completedProjects: { type: Number, default: 0 },
      totalMembers: { type: Number, default: 0 },
      activeMembers: { type: Number, default: 0 },
      lastActivityAt: { type: Date, default: Date.now },
    },

    // ── Integrations ──────────────────────────────────────────────────────
    integrations: {
      slack: { enabled: { type: Boolean, default: false }, webhookUrl: String },
      github: { enabled: { type: Boolean, default: false }, organization: String, repositories: [String] },
    },
    customFields: { type: mongoose.Schema.Types.Mixed },

    // ── Soft delete ───────────────────────────────────────────────────────
    deletedAt: { type: Date },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

// ── Indexes ───────────────────────────────────────────────────────────────
teamSchema.index({ tenantId: 1, status: 1 });
teamSchema.index({ tenantId: 1, "members.userId": 1 });
teamSchema.index({ "invites.email": 1 });

// ── Virtuals ──────────────────────────────────────────────────────────────
teamSchema.virtual("memberCount").get(function () { return this.members?.filter((m) => m.status === "active").length || 0; });
teamSchema.virtual("pendingInviteCount").get(function () { return this.invites?.filter((i) => i.status === "pending").length || 0; });

// ── Pre-save ──────────────────────────────────────────────────────────────
teamSchema.pre("save", function (next) {
  if (!this.slug && this.name) {
    this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  }
  this.stats.totalMembers = this.members.length;
  this.stats.activeMembers = this.members.filter((m) => m.status === "active").length;
  this.stats.lastActivityAt = new Date();
  next();
});

teamSchema.pre(/^find/, function () {
  if (!this.getQuery().includeDeleted) this.where({ deletedAt: null });
});

// ── Methods ───────────────────────────────────────────────────────────────
teamSchema.methods.addMember = function (userId, role = "member", invitedBy = null) {
  if (this.members.find((m) => m.userId.toString() === userId.toString())) throw new Error("Already a member");
  this.members.push({ userId, role, permissions: getDefaultPermissions(role), invitedBy, status: "active" });
  this.activities.unshift({ type: "member_joined", actor: invitedBy, target: userId, description: "New member joined", timestamp: new Date() });
  return this.save();
};

teamSchema.methods.inviteMember = function (email, role, invitedBy, message = "") {
  if (this.invites.find((i) => i.email === email && i.status === "pending")) throw new Error("Already invited");
  const token = crypto.randomBytes(32).toString("hex");
  const expiresAt = new Date(); expiresAt.setDate(expiresAt.getDate() + 7);
  this.invites.push({ email, role, invitedBy, token, message, expiresAt, status: "pending" });
  return this.save();
};

// ── Statics ───────────────────────────────────────────────────────────────
teamSchema.statics.findUserTeams = function (userId) {
  return this.find({ "members.userId": userId, "members.status": "active", status: "active" }).populate("members.userId", "fullName email profilePicture");
};

// ── Helper ────────────────────────────────────────────────────────────────
function getDefaultPermissions(role) {
  const map = {
    owner: { canCreateProjects: true, canDeleteProjects: true, canManageMembers: true, canInviteMembers: true, canChangeSettings: true, canViewAllProjects: true, canExportData: true, canManageIntegrations: true },
    admin: { canCreateProjects: true, canDeleteProjects: true, canManageMembers: true, canInviteMembers: true, canChangeSettings: true, canViewAllProjects: true, canExportData: true, canManageIntegrations: false },
    manager: { canCreateProjects: true, canDeleteProjects: false, canManageMembers: false, canInviteMembers: true, canChangeSettings: false, canViewAllProjects: true, canExportData: true, canManageIntegrations: false },
    member: { canCreateProjects: true, canDeleteProjects: false, canManageMembers: false, canInviteMembers: false, canChangeSettings: false, canViewAllProjects: true, canExportData: false, canManageIntegrations: false },
    viewer: { canCreateProjects: false, canDeleteProjects: false, canManageMembers: false, canInviteMembers: false, canChangeSettings: false, canViewAllProjects: true, canExportData: false, canManageIntegrations: false },
    guest: { canCreateProjects: false, canDeleteProjects: false, canManageMembers: false, canInviteMembers: false, canChangeSettings: false, canViewAllProjects: false, canExportData: false, canManageIntegrations: false },
  };
  return map[role] || map.member;
}

const Team = mongoose.model("Team", teamSchema);
export default Team;
