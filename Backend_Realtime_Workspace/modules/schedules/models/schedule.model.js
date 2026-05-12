// ============================================================================
// TeamSpot — Schedule / Calendar Event Model
// ============================================================================
import mongoose from "mongoose";

const attendeeSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    status: { type: String, enum: ["pending", "accepted", "declined", "tentative"], default: "pending" },
    respondedAt: { type: Date },
  },
  { _id: false }
);

const recurrenceSchema = new mongoose.Schema(
  {
    freq: { type: String, enum: ["daily", "weekly", "monthly", "yearly"], required: true },
    interval: { type: Number, default: 1 },
    daysOfWeek: [{ type: Number, min: 0, max: 6 }], // 0=Sun … 6=Sat
    until: { type: Date },
    count: { type: Number },
  },
  { _id: false }
);

const scheduleSchema = new mongoose.Schema(
  {
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project" },
    teamId: { type: mongoose.Schema.Types.ObjectId, ref: "Team" },

    title: { type: String, required: true, trim: true },
    description: { type: String },
    location: { type: String },
    color: { type: String, default: "#4A90E2" }, // calendar colour

    startTime: { type: Date, required: true, index: true },
    endTime: { type: Date, required: true },
    allDay: { type: Boolean, default: false },
    timezone: { type: String, default: "UTC" },

    type: {
      type: String,
      enum: ["event", "task_deadline", "reminder", "blocked", "out_of_office", "meeting_slot"],
      default: "event",
    },

    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    attendees: [attendeeSchema],

    recurrence: recurrenceSchema,
    recurrenceSeriesId: { type: mongoose.Schema.Types.ObjectId }, // groups occurrences

    reminders: [
      {
        method: { type: String, enum: ["email", "push", "websocket"], default: "push" },
        minutesBefore: { type: Number, default: 15 },
      },
    ],

    status: { type: String, enum: ["scheduled", "cancelled", "completed"], default: "scheduled" },
    cancelledAt: { type: Date },
    cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },

    metadata: { type: mongoose.Schema.Types.Mixed }, // integrations payload
    deletedAt: { type: Date },
  },
  { timestamps: true }
);

scheduleSchema.index({ tenantId: 1, startTime: 1, endTime: 1 });
scheduleSchema.index({ tenantId: 1, "attendees.userId": 1, startTime: 1 });
scheduleSchema.pre(/^find/, function () {
  if (!this.getQuery().includeDeleted) this.where({ deletedAt: null });
});

const Schedule = mongoose.model("Schedule", scheduleSchema);
export default Schedule;
