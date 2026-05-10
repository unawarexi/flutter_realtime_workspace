// ============================================================================
// TeamSpot — Meeting Model
// Scheduled meetings with participants, recurrence, reminders, analytics
// ============================================================================
import mongoose from "mongoose";

const meetingSchema = new mongoose.Schema(
  {
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },
    meetingTitle: { type: String, required: true, trim: true, maxLength: 200 },
    description: { type: String, maxLength: 2000 },
    agenda: { type: String, maxLength: 5000 },
    organizer: {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
      name: { type: String, required: true },
      email: { type: String, required: true },
    },
    meetingDate: { type: Date, required: true, index: true },
    meetingTime: { start: { type: String, required: true }, end: { type: String, required: true } },
    duration: { type: Number, required: true, min: 5, max: 480 },
    timezone: { type: String, default: "UTC" },
    repeatOption: { type: String, enum: ["None", "Daily", "Weekly", "Bi-weekly", "Monthly"], default: "None" },
    recurrenceEndDate: { type: Date },
    recurringMeetings: [{ type: mongoose.Schema.Types.ObjectId, ref: "Meeting" }],
    meetingType: { type: String, enum: ["Virtual", "Physical"], required: true },
    location: {
      address: String, mapLink: String,
      meetingLink: String, meetingPassword: String,
      platform: { type: String, enum: ["LiveKit", "Zoom", "Google Meet", "Microsoft Teams", "Other"] },
    },
    participants: [{
      userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
      name: { type: String, required: true },
      email: { type: String, required: true },
      status: { type: String, enum: ["invited", "accepted", "declined", "tentative", "no-response"], default: "invited" },
      responseDate: Date, joinedAt: Date, leftAt: Date,
    }],
    status: { type: String, enum: ["scheduled", "ongoing", "ended", "cancelled", "postponed"], default: "scheduled" },
    actualStartTime: Date, actualEndTime: Date,
    cancellationReason: String,
    reminderSettings: {
      enabled: { type: Boolean, default: true },
      reminderTime: { type: String, enum: ["5 minutes before", "15 minutes before", "30 minutes before", "1 hour before", "1 day before"], default: "15 minutes before" },
      notificationMethods: [{ type: String, enum: ["push", "email", "sms"] }],
    },
    attachments: [{ fileName: String, fileUrl: String, fileSize: Number, mimeType: String, uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, uploadedAt: { type: Date, default: Date.now } }],
    analytics: {
      invitesSent: { type: Number, default: 0 }, acceptedCount: { type: Number, default: 0 },
      declinedCount: { type: Number, default: 0 }, actualAttendees: { type: Number, default: 0 },
      meetingDuration: Number, recordingUrl: String, meetingNotes: String,
    },
    visibility: { type: String, enum: ["public", "private", "department-only", "team-only"], default: "team-only" },
    allowGuestUsers: { type: Boolean, default: false },
    externalCalendarIds: [{ platform: { type: String, enum: ["google", "outlook", "apple"] }, eventId: String }],
    deletedAt: { type: Date },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

meetingSchema.index({ tenantId: 1, meetingDate: 1, status: 1 });
meetingSchema.index({ tenantId: 1, "organizer.userId": 1 });
meetingSchema.index({ tenantId: 1, "participants.userId": 1 });
meetingSchema.virtual("isUpcoming").get(function () { return this.meetingDate > new Date() && this.status === "scheduled"; });
meetingSchema.virtual("isToday").get(function () { return new Date().toDateString() === new Date(this.meetingDate).toDateString(); });
meetingSchema.pre("save", function (next) {
  if (this.isModified("participants")) {
    this.analytics.acceptedCount = this.participants.filter((p) => p.status === "accepted").length;
    this.analytics.declinedCount = this.participants.filter((p) => p.status === "declined").length;
    this.analytics.invitesSent = this.participants.length;
  }
  next();
});
meetingSchema.pre(/^find/, function () { if (!this.getQuery().includeDeleted) this.where({ deletedAt: null }); });

meetingSchema.statics.findUserMeetings = function (userId, opts = {}) {
  const { status = ["scheduled", "ongoing"], startDate = new Date(), limit = 50 } = opts;
  return this.find({
    $or: [{ "organizer.userId": userId }, { "participants.userId": userId }],
    status: { $in: Array.isArray(status) ? status : [status] },
    meetingDate: { $gte: startDate }, deletedAt: null,
  }).sort({ meetingDate: 1 }).limit(limit);
};

const Meeting = mongoose.model("Meeting", meetingSchema);
export default Meeting;
