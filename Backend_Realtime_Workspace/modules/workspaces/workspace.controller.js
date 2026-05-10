import BaseController from "../../core/base/base.controller.js";
import { workspaceService } from "./workspace.service.js";

class WorkspaceController extends BaseController {
  
  createWorkspace = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const workspace = await workspaceService.createWorkspace(req.body, tenantId, orgId, userId);
    return BaseController.sendCreated(res, workspace, "Workspace created successfully");
  };

  getWorkspaces = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    
    // Only return workspaces the user is a member of (or all if org admin - simplified for now)
    const filter = { orgId, "members.userId": userId }; 
    const pagination = BaseController.getPagination(req);
    
    const result = await workspaceService.paginate(filter, { 
      tenantId,
      page: pagination.page, 
      limit: pagination.limit, 
      sort: BaseController.parseSort(pagination.sort) 
    });

    return BaseController.sendPaginated(res, result, "Workspaces retrieved");
  };

  getWorkspaceById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const workspace = await workspaceService.getWorkspaceById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, workspace, "Workspace retrieved");
  };

  updateWorkspace = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    // Needs permissions check inside service or middleware
    const workspace = await workspaceService.updateWorkspace(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, workspace, "Workspace updated successfully");
  };

  deleteWorkspace = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await workspaceService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Workspace deleted successfully");
  };

  addMember = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { userId, role } = req.body;
    const workspace = await workspaceService.addMember(req.params.id, userId, role, tenantId);
    return BaseController.sendSuccess(res, workspace, "Member added successfully");
  };

  getMembers = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const workspace = await workspaceService.getWorkspaceById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, workspace.members, "Workspace members retrieved");
  };

  removeMember = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const workspace = await workspaceService.removeMember(req.params.id, req.params.userId, tenantId);
    return BaseController.sendSuccess(res, workspace, "Member removed successfully");
  };
}

export const workspaceController = new WorkspaceController();
