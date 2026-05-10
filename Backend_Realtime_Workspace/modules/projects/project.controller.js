import BaseController from "../../core/base/base.controller.js";
import { projectService } from "./project.service.js";

class ProjectController extends BaseController {
  
  createProject = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const project = await projectService.createProject(req.body, tenantId, userId, files);
    return BaseController.sendCreated(res, project, "Project created successfully");
  };

  getProjects = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    // User can see projects they created or collaborate on, or team projects (simplified)
    const filter = { $or: [{ createdBy: userId }, { collaborators: userId }] };
    
    const pagination = BaseController.getPagination(req);
    const result = await projectService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });
    return BaseController.sendPaginated(res, result, "Projects retrieved");
  };

  getProjectById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const project = await projectService.getProjectById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, project, "Project retrieved");
  };

  updateProject = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const project = await projectService.updateProject(req.params.id, req.body, tenantId, userId);
    return BaseController.sendSuccess(res, project, "Project updated");
  };

  deleteProject = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await projectService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Project deleted");
  };

  toggleProjectStar = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const project = await projectService.toggleStar(req.params.id, tenantId);
    return BaseController.sendSuccess(res, project, "Project star toggled");
  };

  toggleProjectArchive = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const project = await projectService.toggleArchive(req.params.id, tenantId, userId);
    return BaseController.sendSuccess(res, project, "Project archive toggled");
  };

  updateProjectCollaborators = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const project = await projectService.updateCollaborators(req.params.id, req.body.collaborators, tenantId);
    return BaseController.sendSuccess(res, project, "Collaborators updated");
  };

  addTimelineEvent = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const project = await projectService.addTimelineEvent(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, project, "Timeline event added");
  };

  uploadAttachment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    if (!req.file) return BaseController.sendSuccess(res, null, "No file provided");
    const attachment = await projectService.addAttachment(req.params.id, req.file, tenantId, userId);
    return BaseController.sendCreated(res, attachment, "Attachment uploaded");
  };

  deleteAttachment = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await projectService.removeAttachment(req.params.id, req.params.attachmentId, tenantId);
    return BaseController.sendSuccess(res, null, "Attachment deleted");
  };
}

export const projectController = new ProjectController();
