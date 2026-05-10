// ============================================================================
// TeamSpot — Task Model
// ============================================================================
import mongoose from "mongoose";

const checklistItemSchema = new mongoose.Schema(
  { title: { type: String, required: true }, completed: { type: Boolean, default: false } },
  { _id: false }
);

const commentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  content: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

const taskSchema = new mongoose.Schema(
  {
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true, index: true },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: "Workspace", index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String },
    key: { type: String, unique: true, sparse: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true, index: true },
    issueId: { type: mongoose.Schema.Types.ObjectId, ref: "Issue" },
    parentTaskId: { type: mongoose.Schema.Types.ObjectId, ref: "Task" },
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    watchers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    status: { type: String, enum: ["backlog", "todo", "in_progress", "in_review", "done", "blocked", "cancelled"], default: "todo", index: true },
    priority: { type: String, enum: ["lowest", "low", "medium", "high", "critical"], default: "medium" },
    labels: [{ type: String, trim: true }],
    dueDate: { type: Date },
    startDate: { type: Date },
    completedAt: { type: Date },
    estimatedHours: { type: Number, min: 0 },
    loggedHours: { type: Number, default: 0, min: 0 },
    checklist: [checklistItemSchema],
    comments: [commentSchema],
    attachments: [{ url: String, filename: String, bytes: Number, uploadedAt: { type: Date, default: Date.now } }],
    sortOrder: { type: Number, default: 0 },
    sprintId: { type: mongoose.Schema.Types.ObjectId },
    deletedAt: { type: Date },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

taskSchema.index({ tenantId: 1, projectId: 1, status: 1 });
taskSchema.index({ tenantId: 1, assignedTo: 1, status: 1 });
taskSchema.index({ title: "text", description: "text" });
taskSchema.virtual("isOverdue").get(function () { return this.dueDate && new Date() > this.dueDate && this.status !== "done"; });
taskSchema.virtual("subtasks", { ref: "Task", localField: "_id", foreignField: "parentTaskId" });
taskSchema.pre(/^find/, function () { if (!this.getQuery().includeDeleted) this.where({ deletedAt: null }); });

const Task = mongoose.model("Task", taskSchema);
export default Task;
