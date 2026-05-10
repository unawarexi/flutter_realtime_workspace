// ============================================================================
// TeamSpot — Organization Model
// Multi-tenant org with branding, billing, and settings
// ============================================================================

import mongoose from "mongoose";

const organizationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, lowercase: true, trim: true },
    tenantId: { type: String, required: true, unique: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },

    // Branding
    logo: { type: String },
    favicon: { type: String },
    primaryColor: { type: String, default: "#6366F1" },
    domain: { type: String },

    // Company info
    industry: { type: String },
    size: { type: String, enum: ["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"] },
    website: { type: String },
    country: { type: String },
    timezone: { type: String, default: "UTC" },

    // Plan & quotas
    plan: { type: String, enum: ["free", "starter", "professional", "enterprise"], default: "free" },
    quotas: {
      maxMembers: { type: Number, default: 10 },
      maxWorkspaces: { type: Number, default: 3 },
      maxProjects: { type: Number, default: 20 },
      maxStorageGB: { type: Number, default: 5 },
      aiCredits: { type: Number, default: 100 },
    },

    // Security settings
    settings: {
      enforced2FA: { type: Boolean, default: false },
      allowedAuthProviders: [{ type: String }],
      ipWhitelist: [{ type: String }],
      sessionTimeoutMinutes: { type: Number, default: 480 },
      dataRetentionDays: { type: Number, default: 365 },
    },

    // SSO
    sso: {
      enabled: { type: Boolean, default: false },
      provider: { type: String, enum: ["saml", "oidc"] },
      entityId: { type: String },
      ssoUrl: { type: String },
      certificate: { type: String },
    },

    // Status
    status: { type: String, enum: ["active", "suspended", "trial", "cancelled"], default: "active" },
    trialEndsAt: { type: Date },
    suspendedAt: { type: Date },
    suspendReason: { type: String },

    // Metadata
    memberCount: { type: Number, default: 1 },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" },
  },
  {
    timestamps: true,
    indexes: [
      { tenantId: 1 },
      { slug: 1 },
      { owner: 1 },
      { status: 1 },
    ],
  }
);

organizationSchema.index({ name: "text" });

const Organization = mongoose.model("Organization", organizationSchema);
export default Organization;
