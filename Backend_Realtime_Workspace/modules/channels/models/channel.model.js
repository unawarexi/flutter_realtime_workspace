// ============================================================================
// TeamSpot — Channel Model
// Chat channels with threads, DMs, and workspace scoping
// ============================================================================

import mongoose from "mongoose";

const channelSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, lowercase: true, trim: true },
    description: { type: String },
    tenantId: { type: String, required: true, index: true },
    orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", required: true, index: true },

    type: { type: String, enum: ["public", "private", "direct", "group_dm"], required: true, default: "public" },
    topic: { type: String },
    icon: { type: String },

    // Members
    members: [{
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },
      role: { type: String, enum: ["admin", "moderator", "member"], default: "member" },
      joinedAt: { type: Date, default: Date.now },
      lastRead: { type: Date },
      muted: { type: Boolean, default: false },
      notificationPreference: { type: String, enum: ["all", "mentions", "none"], default: "all" },
    }],

    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },

    // Pins & bookmarks
    pinnedMessages: [{ type: mongoose.Schema.Types.ObjectId, ref: "Message" }],

    // Settings
    settings: {
      allowThreads: { type: Boolean, default: true },
      allowReactions: { type: Boolean, default: true },
      allowFileUploads: { type: Boolean, default: true },
      slowMode: { type: Number, default: 0 }, // seconds between messages, 0 = off
      retentionDays: { type: Number }, // null = inherit org setting
    },

    // Status
    status: { type: String, enum: ["active", "archived", "deleted"], default: "active" },
    archivedAt: { type: Date },

    // Denormalized counts
    messageCount: { type: Number, default: 0 },
    memberCount: { type: Number, default: 0 },
    lastMessageAt: { type: Date },
  },
  {
    timestamps: true,
    indexes: [
      { tenantId: 1, workspaceId: 1 },
      { "members.userId": 1 },
      { type: 1, status: 1 },
      { lastMessageAt: -1 },
    ],
  }
);

channelSchema.index({ name: "text", description: "text" });

const Channel = mongoose.model("Channel", channelSchema);
export default Channel;

// ============================================================================
// Message Model
// ============================================================================

const messageSchema = new mongoose.Schema(
  {
    channelId: { type: mongoose.Schema.Types.ObjectId, ref: "Channel", required: true, index: true },
    tenantId: { type: String, required: true, index: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo", required: true },

    // Content
    content: { type: String },
    contentType: { type: String, enum: ["text", "image", "video", "audio", "file", "system", "ai_response"], default: "text" },

    // Attachments
    attachments: [{
      url: { type: String, required: true },
      publicId: { type: String },
      filename: { type: String },
      mimeType: { type: String },
      bytes: { type: Number },
      width: { type: Number },
      height: { type: Number },
    }],

    // Thread
    threadId: { type: mongoose.Schema.Types.ObjectId, ref: "Message" },
    threadReplyCount: { type: Number, default: 0 },
    threadLastReplyAt: { type: Date },

    // Mentions
    mentions: [{ type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" }],
    mentionsEveryone: { type: Boolean, default: false },

    // Reactions
    reactions: [{
      emoji: { type: String, required: true },
      users: [{ type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" }],
      count: { type: Number, default: 0 },
    }],

    // Edit history
    edited: { type: Boolean, default: false },
    editedAt: { type: Date },
    editHistory: [{
      content: { type: String },
      editedAt: { type: Date, default: Date.now },
    }],

    // Status
    deleted: { type: Boolean, default: false },
    deletedAt: { type: Date },
    pinned: { type: Boolean, default: false },
    pinnedAt: { type: Date },
    pinnedBy: { type: mongoose.Schema.Types.ObjectId, ref: "UserInfo" },
  },
  {
    timestamps: true,
    indexes: [
      { channelId: 1, createdAt: -1 },
      { tenantId: 1, channelId: 1 },
      { threadId: 1 },
      { senderId: 1 },
    ],
  }
);

messageSchema.index({ content: "text" });

export const Message = mongoose.model("Message", messageSchema);
