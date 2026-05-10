// ============================================================================
// TeamSpot — Audit Log Model (Append-only)
// ============================================================================

import mongoose from "mongoose";

const auditLogSchema = new mongoose.Schema(
  {
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", index: true },
    action: { type: String, required: true, index: true },
    category: { type: String, enum: ["auth", "iam", "data", "admin", "ai", "billing", "system"], required: true },
    actor: {
      userId: { type: String, required: true },
      email: { type: String },
      role: { type: String },
      ip: { type: String },
      userAgent: { type: String },
    },
    target: {
      type: { type: String }, // "project", "task", "user", etc.
      id: { type: String },
      name: { type: String },
    },
    changes: { before: { type: mongoose.Schema.Types.Mixed }, after: { type: mongoose.Schema.Types.Mixed } },
    metadata: { type: mongoose.Schema.Types.Mixed },
    requestId: { type: String },
    traceId: { type: String },
    status: { type: String, enum: ["success", "failure"], default: "success" },
    errorMessage: { type: String },
  },
  {
    timestamps: { createdAt: true, updatedAt: false }, // Append-only
    collection: "audit_logs",
  }
);

auditLogSchema.index({ tenantId: 1, createdAt: -1 });
auditLogSchema.index({ "actor.userId": 1, createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });
auditLogSchema.index({ "target.type": 1, "target.id": 1 });

const AuditLog = mongoose.model("AuditLog", auditLogSchema);
export default AuditLog;
