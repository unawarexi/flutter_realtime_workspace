// ============================================================================
// TeamSpot — Notification Model & Preferences
// ============================================================================

import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true, index: true },
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" },
  type: { type: String, required: true, enum: [
    "mention", "assignment", "comment", "invite", "meeting", "task_update",
    "project_update", "ticket_update", "system", "ai_result", "workflow",
  ]},
  title: { type: String, required: true },
  body: { type: String },
  data: { type: mongoose.Schema.Types.Mixed },
  channel: { type: String, enum: ["in_app", "email", "push", "sms"], default: "in_app" },
  resource: { type: { type: String }, id: { type: mongoose.Schema.Types.ObjectId }, name: { type: String } },
  read: { type: Boolean, default: false },
  readAt: { type: Date },
  actionUrl: { type: String },
  priority: { type: String, enum: ["low", "normal", "high", "urgent"], default: "normal" },
  expiresAt: { type: Date },
}, { timestamps: true });

notificationSchema.index({ recipientId: 1, read: 1, createdAt: -1 });
notificationSchema.index({ tenantId: 1, recipientId: 1 });

export const Notification = mongoose.model("Notification", notificationSchema);

// Notification preferences per user
const notifPrefSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true, unique: true },
  tenantId: { type: String, required: true },
  channels: {
    email: { type: Boolean, default: true },
    push: { type: Boolean, default: true },
    sms: { type: Boolean, default: false },
    inApp: { type: Boolean, default: true },
  },
  digestFrequency: { type: String, enum: ["realtime", "hourly", "daily", "weekly"], default: "realtime" },
  quietHours: { enabled: { type: Boolean, default: false }, start: { type: String }, end: { type: String }, timezone: { type: String } },
  mutedChannels: [{ type: mongoose.Schema.Types.ObjectId, ref: "Channel" }],
  mutedProjects: [{ type: mongoose.Schema.Types.ObjectId, ref: "Project" }],
  typeOverrides: { type: Map, of: { email: Boolean, push: Boolean, sms: Boolean, inApp: Boolean } },
}, { timestamps: true });

export const NotificationPreference = mongoose.model("NotificationPreference", notifPrefSchema);

export default Notification;
