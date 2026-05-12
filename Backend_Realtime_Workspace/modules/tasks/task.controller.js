// ============================================================================
// TeamSpot — Task Controller
// ============================================================================
import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created, paginated, noContent } from "../../core/utils/api-response.js";
import { taskService } from "./task.service.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId: req.user?._id?.toString() || req.user?.id,
});

export const createTask = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const files = req.files || [];
  const task = await taskService.createTask(req.body, tenantId, userId, files);
  return created(res, task, "Task created");
});

export const listTasks = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const { projectId, status, assignedTo, sprintId, priority, page = 1, limit = 20, sort = "-createdAt" } = req.query;
  const filter = { deletedAt: null };
  if (projectId) filter.projectId = projectId;
  if (status) filter.status = status;
  if (sprintId) filter.sprintId = sprintId;
  if (priority) filter.priority = priority;
  if (assignedTo) filter.assignedTo = assignedTo === "me" ? userId : assignedTo;

  const result = await taskService.paginate(filter, {
    tenantId,
    page: Number(page),
    limit: Number(limit),
    sort,
  });
  return paginated(res, result, "Tasks retrieved");
});

export const getTask = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const task = await taskService.getTaskById(req.params.id, tenantId);
  return success(res, task, "Task retrieved");
});

export const updateTask = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.updateTask(req.params.id, req.body, tenantId, userId);
  return success(res, task, "Task updated");
});

export const deleteTask = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await taskService.deleteTask(req.params.id, tenantId, userId);
  return noContent(res);
});

export const addComment = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.addComment(req.params.id, req.body.content, tenantId, userId);
  return success(res, task, "Comment added");
});

export const updateChecklist = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.updateChecklist(req.params.id, req.body.checklist, tenantId, userId);
  return success(res, task, "Checklist updated");
});

export const uploadAttachment = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  if (!req.file) return success(res, null, "No file provided");
  const attachment = await taskService.addAttachment(req.params.id, req.file, tenantId, userId);
  return created(res, attachment, "Attachment uploaded");
});

export const logHours = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.logHours(req.params.id, Number(req.body.hours), tenantId, userId);
  return success(res, task, "Hours logged");
});

export const watchTask = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.watchTask(req.params.id, tenantId, userId);
  return success(res, task, "Watching task");
});

export const unwatchTask = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const task = await taskService.unwatchTask(req.params.id, tenantId, userId);
  return success(res, task, "Unwatched task");
});

// Compat default export for module-registry
export const taskController = {
  createTask, listTasks, getTask, updateTask, deleteTask,
  addComment, updateChecklist, uploadAttachment, logHours,
  watchTask, unwatchTask,
};
