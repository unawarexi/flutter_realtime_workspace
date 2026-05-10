import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Workspace from "./models/workspace.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";

class WorkspaceRepository extends BaseRepository {
  constructor() {
    super(Workspace, { tenantScoped: true });
  }
}

class WorkspaceService extends BaseService {
  constructor() {
    super(new WorkspaceRepository(), {
      name: "WorkspaceService",
      cachePrefix: "workspace",
      cacheTTL: 3600,
    });
  }

  async createWorkspace(data, tenantId, orgId, userId) {
    const { slug } = data;
    
    const existing = await this.repository.findOne({ slug, orgId }, { tenantId });
    if (existing) {
      throw new AppError(HttpStatus.CONFLICT, "Workspace slug is already taken in this organization", "E5002");
    }

    const newWorkspace = await this.repository.create({
      ...data,
      tenantId,
      orgId,
      owner: userId,
      members: [{ userId, role: "workspace_admin" }],
    }, { tenantId });

    this.emit("workspace.created", { workspaceId: newWorkspace._id, tenantId, orgId });

    return newWorkspace;
  }

  async getWorkspaceById(id, tenantId) {
    const workspace = await this.cachedFindById(id, { tenantId });
    if (!workspace) {
      throw new AppError(HttpStatus.NOT_FOUND, "Workspace not found", "E3002");
    }
    return workspace;
  }

  async updateWorkspace(id, updates, tenantId) {
    const workspace = await this.getWorkspaceById(id, tenantId);
    
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("workspace.updated", { workspaceId: id, tenantId, updates });
    return updated;
  }

  async addMember(id, userId, role, tenantId) {
      const workspace = await this.getWorkspaceById(id, tenantId);

      const isMember = workspace.members.some(m => m.userId.toString() === userId.toString());
      if (isMember) {
          throw new AppError(HttpStatus.BAD_REQUEST, "User is already a member", "E5003");
      }

      const updated = await this.updateById(id, {
          $push: { members: { userId, role: role || "member" } },
          $inc: { memberCount: 1 }
      }, { tenantId });

      this.emit("workspace.member_added", { workspaceId: id, tenantId, userId, role });
      return updated;
  }

  async removeMember(id, userId, tenantId) {
      const workspace = await this.getWorkspaceById(id, tenantId);
      
      const updated = await this.updateById(id, {
          $pull: { members: { userId } },
          $inc: { memberCount: -1 }
      }, { tenantId });

      this.emit("workspace.member_removed", { workspaceId: id, tenantId, userId });
      return updated;
  }
}

export const workspaceService = new WorkspaceService();
