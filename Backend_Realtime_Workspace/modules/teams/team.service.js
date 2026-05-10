import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Team from "./models/team.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";

class TeamRepository extends BaseRepository {
  constructor() {
    super(Team, { tenantScoped: true });
  }
}

class TeamService extends BaseService {
  constructor() {
    super(new TeamRepository(), {
      name: "TeamService",
      cachePrefix: "team",
      cacheTTL: 1800,
    });
  }

  async createTeam(data, tenantId, userId) {
    const newTeam = await this.repository.create({
      ...data,
      tenantId,
      createdBy: userId,
      members: [{ userId, role: "owner", status: "active" }],
    }, { tenantId });

    this.emit("team.created", { teamId: newTeam._id, tenantId, createdBy: userId });
    return newTeam;
  }

  async getTeamById(id, tenantId) {
    const team = await this.cachedFindById(id, { tenantId });
    if (!team) {
      throw new AppError(HttpStatus.NOT_FOUND, "Team not found", "E3003");
    }
    return team;
  }

  async updateTeam(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("team.updated", { teamId: id, tenantId, updates });
    return updated;
  }

  async inviteMember(id, email, role, message, tenantId, invitedByUserId) {
    const team = await this.getTeamById(id, tenantId);
    
    // Check if the user sending invite has permission
    const inviter = team.members.find(m => m.userId.toString() === invitedByUserId.toString() && m.status === 'active');
    if (!inviter || (inviter.role !== 'owner' && inviter.role !== 'admin' && inviter.role !== 'manager')) {
        throw new AppError(HttpStatus.FORBIDDEN, "Insufficient permissions to invite members", "E4002");
    }

    // In a real implementation, we'd use the Team model's methods if it wasn't lean, 
    // but BaseRepository uses .lean(). We need to update directly via DB.
    
    // Simplified invite push
    const token = Math.random().toString(36).substring(2, 15); // Stub token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const updated = await this.updateById(id, {
        $push: {
            invites: { email, role: role || "member", invitedBy: invitedByUserId, token, message, expiresAt, status: "pending" }
        }
    }, { tenantId });

    this.emit("team.member_invited", { teamId: id, tenantId, email, role });
    // TODO: emit to RabbitMQ email queue

    return updated;
  }
}

export const teamService = new TeamService();
