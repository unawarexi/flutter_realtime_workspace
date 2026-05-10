// ============================================================================
// TeamSpot — Workflow Model
// Automation engine: triggers → conditions → actions
// ============================================================================

import mongoose from "mongoose";

const workflowSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String },
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace" },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    // Trigger
    trigger: {
      type: { type: String, required: true, enum: ["event", "schedule", "webhook", "manual"] },
      event: { type: String }, // e.g. "task.status_changed"
      schedule: { cron: { type: String }, timezone: { type: String } },
      webhookUrl: { type: String },
    },

    // Conditions (all must be true)
    conditions: [{
      field: { type: String, required: true },
      operator: { type: String, enum: ["equals", "not_equals", "contains", "gt", "lt", "in", "not_in", "exists"], required: true },
      value: { type: mongoose.Schema.Types.Mixed, required: true },
    }],

    // Actions (executed in order)
    actions: [{
      type: { type: String, required: true, enum: [
        "send_notification", "send_email", "update_field", "create_task",
        "assign_user", "add_comment", "trigger_webhook", "ai_summarize",
        "move_to_status", "add_tag", "remove_tag",
      ]},
      config: { type: mongoose.Schema.Types.Mixed, required: true },
      order: { type: Number, default: 0 },
    }],

    // State
    enabled: { type: Boolean, default: true },
    executionCount: { type: Number, default: 0 },
    lastExecutedAt: { type: Date },
    lastError: { type: String },
    status: { type: String, enum: ["active", "paused", "error", "deleted"], default: "active" },
  },
  { timestamps: true }
);

workflowSchema.index({ tenantId: 1, enabled: 1 });
workflowSchema.index({ "trigger.event": 1 });

const Workflow = mongoose.model("Workflow", workflowSchema);
export default Workflow;
