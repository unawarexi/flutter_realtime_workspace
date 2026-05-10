// ============================================================================
// TeamSpot — User Model
// Comprehensive user profile with 2FA, referrals, workspace roles
// ============================================================================

import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    // ── Identity ──────────────────────────────────────────────────────────
    firebaseUid: { type: String, required: true, unique: true, index: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    fullName: { type: String, trim: true },
    displayName: { type: String, trim: true },
    profilePicture: { type: String },
    phoneNumber: { type: String },

    // ── Multi-tenancy ─────────────────────────────────────────────────────
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", index: true },
    workspaceIds: [{ type: mongoose.Schema.Types.ObjectId, ref: "Workspace" }],

    // ── Workspace Role & Preferences ──────────────────────────────────────
    roleTitle: { type: String },
    department: { type: String },
    workType: { type: String, enum: ["Full-time", "Part-time", "Freelancer", "Intern", "Contractor"] },
    timezone: { type: String, default: "UTC" },
    workingHours: {
      start: { type: String, default: "09:00" },
      end: { type: String, default: "17:00" },
    },

    // ── Company / Organization ────────────────────────────────────────────
    companyName: { type: String },
    companyWebsite: { type: String },
    industry: { type: String },
    teamSize: { type: String, enum: ["1-10", "11-50", "51-100", "100+"] },
    officeLocation: { type: String },

    // ── Referral / Invite System ──────────────────────────────────────────
    inviteCode: { type: String, index: true },
    inviteCodeExpiry: { type: Date },
    invitedBy: [{
      email: { type: String, required: true },
      name: { type: String },
      inviterCode: { type: String },
    }],
    referredTo: [{
      email: { type: String, required: true },
      name: { type: String },
    }],

    // ── Permissions ───────────────────────────────────────────────────────
    permissionsLevel: {
      type: String,
      enum: ["super_admin", "admin", "manager", "employee", "member", "guest"],
      default: "member",
    },
    invitePermissions: {
      admin: { type: Boolean, default: true },
      manager: { type: Boolean, default: true },
      employee: { type: Boolean, default: false },
    },
    roles: [{ type: mongoose.Schema.Types.ObjectId, ref: "Role" }],

    // ── Profile ───────────────────────────────────────────────────────────
    bio: { type: String, maxlength: 500 },
    interestsSkills: [{ type: String }],
    socialLinks: {
      linkedIn: String,
      github: String,
      twitter: String,
      website: String,
    },
    profileCompletion: { type: Number, default: 0, min: 0, max: 100 },

    // ── 2FA Security ──────────────────────────────────────────────────────
    totpSecret: { type: String, select: false },
    totpEnabled: { type: Boolean, default: false },
    totpSetupAt: { type: Date },
    totpDisabledAt: { type: Date },
    backupCodes: [{
      code: { type: String },
      used: { type: Boolean, default: false },
      usedAt: { type: Date },
    }],
    twoFactorSettings: {
      preferredMethod: { type: String, enum: ["email", "sms", "totp"], default: "email" },
      emailVerified: { type: Boolean, default: false },
      phoneVerified: { type: Boolean, default: false },
      trustedDevices: [{
        deviceId: String,
        deviceName: String,
        lastUsed: Date,
        addedAt: { type: Date, default: Date.now },
      }],
    },

    // ── Session & Security ────────────────────────────────────────────────
    lastLoginAt: { type: Date },
    lastLoginIp: { type: String },
    loginCount: { type: Number, default: 0 },
    failedLoginAttempts: { type: Number, default: 0 },
    lockedUntil: { type: Date },
    fcmTokens: [{ type: String }],

    // ── Status ────────────────────────────────────────────────────────────
    status: {
      type: String,
      enum: ["active", "inactive", "suspended", "pending", "deactivated"],
      default: "active",
      index: true,
    },
    onboardingComplete: { type: Boolean, default: false },
    deletedAt: { type: Date },

    // ── Preferences ───────────────────────────────────────────────────────
    preferences: {
      theme: { type: String, enum: ["light", "dark", "system"], default: "system" },
      language: { type: String, default: "en" },
      notifications: {
        email: { type: Boolean, default: true },
        push: { type: Boolean, default: true },
        inApp: { type: Boolean, default: true },
      },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
userSchema.index({ tenantId: 1, email: 1 });
userSchema.index({ tenantId: 1, status: 1 });
userSchema.index({ tenantId: 1, department: 1 });
userSchema.index({ fullName: "text", displayName: "text", email: "text" });

// ── Soft delete filter ────────────────────────────────────────────────────────
userSchema.pre(/^find/, function () {
  if (!this.getQuery().includeDeleted) {
    this.where({ deletedAt: null });
  }
});

// ── Virtuals ──────────────────────────────────────────────────────────────────
userSchema.virtual("isLocked").get(function () {
  return this.lockedUntil && this.lockedUntil > new Date();
});

userSchema.virtual("is2FAEnabled").get(function () {
  return this.totpEnabled;
});

const User = mongoose.model("User", userSchema);
export default User;
