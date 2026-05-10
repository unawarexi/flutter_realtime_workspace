import BaseController from "../../core/base/base.controller.js";
import { identityService } from "./identity.service.js";

class IdentityController extends BaseController {
  
  // --- Roles ---
  createRole = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const role = await identityService.createRole(req.body, tenantId, orgId);
    return BaseController.sendCreated(res, role, "Role created successfully");
  };

  getRoles = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const filter = { orgId }; 
    const pagination = BaseController.getPagination(req);
    
    const result = await identityService.paginate(filter, { 
      tenantId,
      page: pagination.page, 
      limit: pagination.limit, 
      sort: BaseController.parseSort(pagination.sort) 
    });

    return BaseController.sendPaginated(res, result, "Roles retrieved");
  };

  updateRole = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const role = await identityService.updateRole(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, role, "Role updated successfully");
  };

  deleteRole = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await identityService.deleteRole(req.params.id, tenantId);
    return BaseController.sendSuccess(res, null, "Role deleted successfully");
  };

  // --- Policies ---
  createPolicy = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const policy = await identityService.createPolicy(req.body, tenantId, orgId);
    return BaseController.sendCreated(res, policy, "Policy created successfully");
  };

  getPolicies = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const filter = { orgId };
    const pagination = BaseController.getPagination(req);
    
    const result = await identityService.getPolicies(filter, {
      ...pagination,
      sort: BaseController.parseSort(pagination.sort)
    }, tenantId);

    return BaseController.sendPaginated(res, result, "Policies retrieved");
  };

  updatePolicy = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const policy = await identityService.updatePolicy(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, policy, "Policy updated successfully");
  };

  // --- User Permissions ---
  getUserPermissions = async (req, res) => {
    // Stub implementation: Needs actual resolution logic from Roles + Policies
    return BaseController.sendSuccess(res, { roles: [], policies: [] }, "User permissions retrieved");
  };

  updateUserRole = async (req, res) => {
    // Stub implementation: Needs interaction with user service or workspace service
    return BaseController.sendSuccess(res, null, "User role updated");
  };
}

export const identityController = new IdentityController();
