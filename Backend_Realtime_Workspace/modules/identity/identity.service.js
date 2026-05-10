import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import { Role, Policy } from "./models/role.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";

class RoleRepository extends BaseRepository {
  constructor() {
    super(Role, { tenantScoped: true });
  }
}

class PolicyRepository extends BaseRepository {
  constructor() {
    super(Policy, { tenantScoped: true });
  }
}

class IdentityService extends BaseService {
  constructor() {
    super(new RoleRepository(), {
      name: "IdentityService",
      cachePrefix: "identity_role",
      cacheTTL: 3600,
    });
    this.policyRepository = new PolicyRepository();
  }

  // --- Roles ---
  async createRole(data, tenantId, orgId) {
    const existing = await this.repository.findOne({ slug: data.slug, orgId }, { tenantId });
    if (existing) {
      throw new AppError(HttpStatus.CONFLICT, "Role slug already exists", "E5004");
    }

    const newRole = await this.repository.create({
      ...data,
      tenantId,
      orgId,
      isSystem: false // Can only be set manually
    }, { tenantId });

    this.emit("role.created", { roleId: newRole._id, tenantId });
    return newRole;
  }

  async getRoleById(id, tenantId) {
    const role = await this.cachedFindById(id, { tenantId });
    if (!role) throw new AppError(HttpStatus.NOT_FOUND, "Role not found", "E3005");
    return role;
  }

  async updateRole(id, updates, tenantId) {
    const role = await this.getRoleById(id, tenantId);
    if (role.isSystem) {
      throw new AppError(HttpStatus.FORBIDDEN, "Cannot modify system roles", "E4003");
    }
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("role.updated", { roleId: id, tenantId });
    return updated;
  }

  async deleteRole(id, tenantId) {
    const role = await this.getRoleById(id, tenantId);
    if (role.isSystem) {
      throw new AppError(HttpStatus.FORBIDDEN, "Cannot delete system roles", "E4004");
    }
    await this.deleteById(id, { tenantId });
    this.emit("role.deleted", { roleId: id, tenantId });
    return true;
  }

  // --- Policies ---
  async createPolicy(data, tenantId, orgId) {
    const newPolicy = await this.policyRepository.create({
      ...data,
      tenantId,
      orgId,
    }, { tenantId });
    this.emit("policy.created", { policyId: newPolicy._id, tenantId });
    return newPolicy;
  }

  async getPolicies(filter, pagination, tenantId) {
    return this.policyRepository.paginate(filter, { 
      tenantId, 
      page: pagination.page, 
      limit: pagination.limit, 
      sort: pagination.sort 
    });
  }

  async updatePolicy(id, updates, tenantId) {
    const updated = await this.policyRepository.updateById(id, updates, { tenantId });
    if (!updated) throw new AppError(HttpStatus.NOT_FOUND, "Policy not found", "E3006");
    this.emit("policy.updated", { policyId: id, tenantId });
    return updated;
  }
}

export const identityService = new IdentityService();
