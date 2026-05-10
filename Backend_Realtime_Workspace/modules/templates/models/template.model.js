// ============================================================================
// TeamSpot — Template Model
// Email & PDF template management
// ============================================================================

import mongoose from "mongoose";

const templateSchema = new mongoose.Schema({
  name: { type: String, required: true },
  slug: { type: String, required: true },
  tenantId: { type: String, required: true, index: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization" },
  type: { type: String, enum: ["email", "pdf", "notification", "invoice"], required: true },
  subject: { type: String }, // For email templates
  body: { type: String, required: true }, // HTML/Handlebars template
  variables: [{ name: { type: String }, description: { type: String }, required: { type: Boolean, default: false } }],
  category: { type: String },
  isDefault: { type: Boolean, default: false },
  version: { type: Number, default: 1 },
  status: { type: String, enum: ["active", "draft", "archived"], default: "active" },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" },
}, { timestamps: true });

templateSchema.index({ tenantId: 1, type: 1, slug: 1 }, { unique: true });

const Template = mongoose.model("Template", templateSchema);
export default Template;
