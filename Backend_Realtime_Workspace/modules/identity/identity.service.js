// ============================================================================
// TeamSpot — Identity Service (RBAC: roles, policies, permission checks)
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import { Role, Policy } from "./models/role.model.js";
import { notFound, forbidden, conflict } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";

class RoleRepository extends BaseRepository {
  constructor() { super(Role, { tenantScoped: true }); }
}

class PolicyRepository extends BaseRepository {
  constructor() { super(Policy, { tenantScoped: true }); }
}

class IdentityService extends BaseService {
  constructor() {
    super(new RoleRepository(), {
      name: "IdentityService",
      cachePrefix: "identity_role",
      cacheTTL: CacheTTL.TEAM_MEMBERS || 300,
    });
    this.policyRepository = new PolicyRepository();
  }

  // ── Roles ────────────────────────────────────────────────────────────────────
  async createRole({ name, slug, permissions, description, orgId, tenantId, userId }) {
    const existing = await this.repository.findOne({ slug, orgId }, { tenantId });
    if (existing) throw conflict("Role slug already exists");

    const role = await this.repository.create({
      name, slug, permissions, description,
      tenantId, orgId, isSystem: false, createdBy: userId,
    }, { tenantId });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, { type: "role.created", roleId: role._id, tenantId, userId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "identity.role_created", resourceType: "role",
      resourceId: role._id, actor: { id: userId }, tenantId,
    });
    return role;
  }

  async listRoles({ tenantId, orgId, page = 1, limit = 50 }) {
    return this.repository.paginate({ filter: { orgId }, page: +page, limit: +limit }, { tenantId });
  }

  async getRoleById(id, tenantId) {
    const role = await this.cachedFindById(id, { tenantId });
    if (!role) throw notFound("Role");
    return role;
  }

  async updateRole({ id, updates, tenantId, userId }) {
    const role = await this.getRoleById(id, tenantId);
    if (role.isSystem) throw forbidden("Cannot modify system roles");

    const updated = await this.updateById(id, updates, { tenantId });

    // Invalidate all user permission caches for this tenant
    const redis = getRedisClient();
    const keys = await redis.keys(`perm:${tenantId}:*`);
    if (keys.length) await redis.del(...keys);

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, { type: "role.updated", roleId: id, userId, tenantId });
    return updated;
  }

  async deleteRole({ id, tenantId, userId }) {
    const role = await this.getRoleById(id, tenantId);
    if (role.isSystem) throw forbidden("Cannot delete system roles");

    await this.deleteById(id, { tenantId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "identity.role_deleted", resourceType: "role",
      resourceId: id, actor: { id: userId }, tenantId,
    });
  }

  // ── Policies ─────────────────────────────────────────────────────────────────
  async createPolicy({ orgId, tenantId, userId, ...data }) {
    const policy = await this.policyRepository.create({ ...data, tenantId, orgId, createdBy: userId }, { tenantId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "identity.policy_created", resourceType: "policy",
      resourceId: policy._id, actor: { id: userId }, tenantId,
    });
    return policy;
  }

  async listPolicies({ tenantId, orgId, page = 1, limit = 50 }) {
    return this.policyRepository.paginate({ filter: { orgId }, page: +page, limit: +limit }, { tenantId });
  }

  async updatePolicy({ id, updates, tenantId, userId }) {
    const updated = await this.policyRepository.updateById(id, updates, { tenantId });
    if (!updated) throw notFound("Policy");

    const redis = getRedisClient();
    const keys = await redis.keys(`perm:${tenantId}:*`);
    if (keys.length) await redis.del(...keys);
    return updated;
  }

  async deletePolicy({ id, tenantId, userId }) {
    await this.policyRepository.deleteById(id, { tenantId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "identity.policy_deleted", resourceType: "policy",
      resourceId: id, actor: { id: userId }, tenantId,
    });
  }

  // ── Permission Check (for middleware / guard use) ─────────────────────────────
  async hasPermission({ userId, roleIds, permission, tenantId }) {
    const redis = getRedisClient();
    const cacheKey = `perm:${tenantId}:${userId}:${permission}`;
    const cached = await redis.get(cacheKey);
    if (cached !== null) return cached === "1";

    // Load roles and check permissions
    const roles = await this.repository.model.find({ _id: { $in: roleIds }, tenantId }).lean();
    const allPerms = roles.flatMap(r => r.permissions || []);
    const allowed = allPerms.includes(permission) || allPerms.includes("*");

    await redis.set(cacheKey, allowed ? "1" : "0", "EX", CacheTTL.TEAM_MEMBERS || 300);
    return allowed;
  }
}

export const identityService = new IdentityService();
