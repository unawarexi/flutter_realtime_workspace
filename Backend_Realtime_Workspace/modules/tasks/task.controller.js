import BaseController from "../../core/base/base.controller.js";
import { taskService } from "./task.service.js";

class TaskController extends BaseController {
  
  createTask = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const task = await taskService.createTask(req.body, tenantId, userId, files);
    return BaseController.sendCreated(res, task, "Task created successfully");
  };

  getTasks = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const { projectId, status, assignedTo } = req.query;
    
    const filter = {};
    if (projectId) filter.projectId = projectId;
    if (status) filter.status = status;
    if (assignedTo) filter.assignedTo = assignedTo === 'me' ? userId : assignedTo;
    
    const pagination = BaseController.getPagination(req);
    const result = await taskService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Tasks retrieved");
  };

  getTaskById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const task = await taskService.getTaskById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, task, "Task retrieved");
  };

  updateTask = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const task = await taskService.updateTask(req.params.id, req.body, tenantId, userId);
    return BaseController.sendSuccess(res, task, "Task updated");
  };

  deleteTask = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await taskService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Task deleted");
  };

  addComment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const task = await taskService.addComment(req.params.id, req.body.content, tenantId, userId);
    return BaseController.sendSuccess(res, task, "Comment added");
  };

  updateChecklist = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const task = await taskService.updateChecklist(req.params.id, req.body.checklist, tenantId);
    return BaseController.sendSuccess(res, task, "Checklist updated");
  };

  uploadAttachment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    if (!req.file) return BaseController.sendSuccess(res, null, "No file provided");
    const attachment = await taskService.addAttachment(req.params.id, req.file, tenantId, userId);
    return BaseController.sendCreated(res, attachment, "Attachment uploaded");
  };
}

export const taskController = new TaskController();
