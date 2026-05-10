import BaseController from "../../core/base/base.controller.js";
import { teamService } from "./team.service.js";

class TeamController extends BaseController {
  
  createTeam = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const team = await teamService.createTeam(req.body, tenantId, userId);
    return BaseController.sendCreated(res, team, "Team created successfully");
  };

  getUserTeams = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    
    // Only return teams the user is a member of
    const filter = { "members.userId": userId, "members.status": "active" }; 
    const pagination = BaseController.getPagination(req);
    
    const result = await teamService.paginate(filter, { 
      tenantId,
      page: pagination.page, 
      limit: pagination.limit, 
      sort: BaseController.parseSort(pagination.sort) 
    });

    return BaseController.sendPaginated(res, result, "Teams retrieved");
  };

  getTeamById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const team = await teamService.getTeamById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, team, "Team retrieved");
  };

  updateTeam = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const team = await teamService.updateTeam(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, team, "Team updated successfully");
  };

  deleteTeam = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await teamService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Team deleted successfully");
  };

  inviteMember = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const { email, role, message } = req.body;
    
    const team = await teamService.inviteMember(req.params.id, email, role, message, tenantId, userId);
    return BaseController.sendSuccess(res, team, "Member invited successfully");
  };
}

export const teamController = new TeamController();
