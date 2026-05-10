// ============================================================================
// TeamSpot — Whiteboard Model
// Real-time canvas management and state tracking
// ============================================================================
import mongoose from "mongoose";

const whiteboardSchema = new mongoose.Schema(
  {
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
    name: { type: String, required: true, trim: true },
    description: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    
    // Canvas State (For Yjs/Excalidraw, we might just store a blob URL or initial state)
    state: { type: mongoose.Schema.Types.Mixed }, // JSON representation of elements
    version: { type: Number, default: 1 },
    
    // Access control
    isPublic: { type: Boolean, default: false },
    collaborators: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    
    thumbnailUrl: { type: String },
    deletedAt: { type: Date },
  },
  { timestamps: true }
);

whiteboardSchema.index({ tenantId: 1, workspaceId: 1 });
whiteboardSchema.pre(/^find/, function () { if (!this.getQuery().includeDeleted) this.where({ deletedAt: null }); });

const Whiteboard = mongoose.model("Whiteboard", whiteboardSchema);
export default Whiteboard;
