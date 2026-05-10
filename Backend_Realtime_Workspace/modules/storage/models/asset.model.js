// ============================================================================
// TeamSpot — Storage / Asset Model
// ============================================================================

import mongoose from "mongoose";

const assetSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },
  filename: { type: String, required: true },
  originalName: { type: String, required: true },
  mimeType: { type: String, required: true },
  bytes: { type: Number, required: true },
  url: { type: String, required: true },
  publicId: { type: String },
  resourceType: { type: String, enum: ["image", "video", "audio", "document", "raw"], default: "raw" },
  folder: { type: String, default: "general" },
  // Derived assets
  thumbnailUrl: { type: String },
  variants: [{ name: { type: String }, url: { type: String }, width: { type: Number }, height: { type: Number } }],
  // Metadata
  width: { type: Number },
  height: { type: Number },
  duration: { type: Number }, // seconds for audio/video
  checksum: { type: String },
  // References
  attachedTo: { type: { type: String, enum: ["project", "task", "channel", "meeting", "document", "profile"] }, id: { type: mongoose.Schema.Types.ObjectId } },
  status: { type: String, enum: ["processing", "ready", "error", "deleted"], default: "ready" },
  deletedAt: { type: Date },
}, { timestamps: true });

assetSchema.index({ tenantId: 1, uploadedBy: 1 });
assetSchema.index({ "attachedTo.type": 1, "attachedTo.id": 1 });

const Asset = mongoose.model("Asset", assetSchema);
export default Asset;
