// ============================================================================
// TeamSpot — Feedback Model
// ============================================================================

import mongoose from "mongoose";

const feedbackSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  type: { type: String, enum: ["bug", "feature", "improvement", "praise", "complaint", "survey"], required: true },
  title: { type: String, required: true },
  description: { type: String },
  rating: { type: Number, min: 1, max: 5 },
  category: { type: String },
  status: { type: String, enum: ["new", "acknowledged", "in_progress", "resolved", "closed"], default: "new" },
  priority: { type: String, enum: ["low", "medium", "high"], default: "medium" },
  attachments: [{ url: { type: String }, filename: { type: String } }],
  response: { content: { type: String }, respondedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, respondedAt: { type: Date } },
  metadata: { page: { type: String }, browser: { type: String }, os: { type: String } },
}, { timestamps: true });

feedbackSchema.index({ tenantId: 1, status: 1 });
feedbackSchema.index({ title: "text", description: "text" });

const Feedback = mongoose.model("Feedback", feedbackSchema);
export default Feedback;
