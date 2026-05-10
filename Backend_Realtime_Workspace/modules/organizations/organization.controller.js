import BaseController from "../../core/base/base.controller.js";
import { organizationService } from "./organization.service.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";

class OrganizationController extends BaseController {
  
  createOrganization = async (req, res) => {
    const { userId } = BaseController.getContext(req);
    if (!userId) {
        throw new AppError(HttpStatus.UNAUTHORIZED, "User context not found", "E1001");
    }

    const org = await organizationService.createOrganization(req.body, userId);
    return BaseController.sendCreated(res, org, "Organization created successfully");
  };

  getOrganizations = async (req, res) => {
    // In a real app, you only return orgs the user is part of.
    const { userId } = BaseController.getContext(req);
    // for now, we just list all orgs where user is owner.
    // when member system is fully implemented, this will query tenant memberships.
    const filter = { owner: userId }; 
    const pagination = BaseController.getPagination(req);
    
    const result = await organizationService.paginate(filter, { 
      page: pagination.page, 
      limit: pagination.limit, 
      sort: BaseController.parseSort(pagination.sort) 
    });

    return BaseController.sendPaginated(res, result, "Organizations retrieved");
  };

  getOrganizationById = async (req, res) => {
    const org = await organizationService.getOrganizationById(req.params.id);
    return BaseController.sendSuccess(res, org, "Organization retrieved");
  };

  updateOrganization = async (req, res) => {
    const { userId } = BaseController.getContext(req);
    const org = await organizationService.updateOrganization(req.params.id, req.body, userId);
    return BaseController.sendSuccess(res, org, "Organization updated successfully");
  };

  updateSettings = async (req, res) => {
    const { userId } = BaseController.getContext(req);
    const org = await organizationService.updateSettings(req.params.id, req.body, userId);
    return BaseController.sendSuccess(res, org, "Organization settings updated successfully");
  };

  // Stubs for members
  inviteMember = async (req, res) => {
    // To be implemented fully with Notification service and Identity service
    return BaseController.sendSuccess(res, null, "Member invited (stub)");
  };

  getMembers = async (req, res) => {
    // To be implemented
    return BaseController.sendSuccess(res, [], "Members retrieved (stub)");
  };

  removeMember = async (req, res) => {
    // To be implemented
    return BaseController.sendSuccess(res, null, "Member removed (stub)");
  };
}

export const organizationController = new OrganizationController();
