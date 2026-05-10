// ============================================================================
// TeamSpot — Identity / Permission Models
// ============================================================================

import mongoose from "mongoose";

// Role definitions
const roleSchema = new mongoose.Schema({
  name: { type: String, required: true },
  slug: { type: String, required: true },
  tenantId: { type: String, required: true, index: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
  description: { type: String },
  permissions: [{ resource: { type: String, required: true }, actions: [{ type: String }] }],
  isSystem: { type: Boolean, default: false }, // System roles can't be deleted
  hierarchy: { type: Number, default: 0 },
}, { timestamps: true });

roleSchema.index({ tenantId: 1, slug: 1 }, { unique: true });

export const Role = mongoose.model("Role", roleSchema);

// ABAC policies
const policySchema = new mongoose.Schema({
  name: { type: String, required: true },
  tenantId: { type: String, required: true, index: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
  description: { type: String },
  effect: { type: String, enum: ["allow", "deny"], required: true },
  conditions: [{
    attribute: { type: String, required: true },
    operator: { type: String, enum: ["equals", "not_equals", "in", "not_in", "contains", "gt", "lt"], required: true },
    value: { type: mongoose.Schema.Types.Mixed, required: true },
  }],
  resource: { type: String, required: true },
  actions: [{ type: String }],
  enabled: { type: Boolean, default: true },
  priority: { type: Number, default: 0 },
}, { timestamps: true });

policySchema.index({ tenantId: 1, resource: 1, enabled: 1 });

export const Policy = mongoose.model("Policy", policySchema);
