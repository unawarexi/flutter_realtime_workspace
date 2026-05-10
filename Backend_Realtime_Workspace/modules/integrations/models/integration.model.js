// ============================================================================
// TeamSpot — Integration & Webhook Model
// ============================================================================

import mongoose from "mongoose";

const integrationSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
  name: { type: String, required: true },
  type: { type: String, required: true, enum: [
    "github", "gitlab", "slack", "google_drive", "onedrive",
    "zoom", "jira", "notion", "figma", "custom_webhook",
  ]},
  config: {
    webhookUrl: { type: String },
    apiKey: { type: String },
    accessToken: { type: String },
    refreshToken: { type: String },
    tokenExpiresAt: { type: Date },
    customHeaders: { type: Map, of: String },
    scopes: [{ type: String }],
  },
  events: [{ type: String }], // Which events to send/receive
  enabled: { type: Boolean, default: true },
  lastSyncAt: { type: Date },
  lastError: { type: String },
  status: { type: String, enum: ["active", "error", "disabled"], default: "active" },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
}, { timestamps: true });

integrationSchema.index({ tenantId: 1, type: 1 });

const Integration = mongoose.model("Integration", integrationSchema);
export default Integration;
