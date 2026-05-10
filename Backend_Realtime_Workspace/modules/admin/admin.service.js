// ============================================================================
// TeamSpot — Admin Service (super-admin: tenant mgmt, impersonation, stats)
// ============================================================================

import mongoose from "mongoose";
import jwt from "jsonwebtoken";
import BaseService from "../../core/base/base.service.js";
import { notFound, forbidden, badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import env from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("AdminService");

class AdminService extends BaseService {
  constructor() { super(null, { name: "AdminService" }); }

  // ── Tenants ──────────────────────────────────────────────────────────────────
  async listTenants({ status, plan, search, page = 1, limit = 20 }) {
    const Org = mongoose.model("Organization");
    const filter = {};
    if (status) filter.status = status;
    if (plan)   filter.plan   = plan;
    if (search) filter.$text  = { $search: search };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      Org.find(filter).skip(skip).limit(+limit).sort({ createdAt: -1 }).lean(),
      Org.countDocuments(filter),
    ]);
    return { data, total, page: +page, limit: +limit, pages: Math.ceil(total / limit) };
  }

  async updateTenantStatus({ id, status, adminUserId, reason }) {
    const Org = mongoose.model("Organization");
    const org = await Org.findByIdAndUpdate(
      id,
      { status, ...(status === "suspended" ? { suspendedAt: new Date(), suspendReason: reason } : {}) },
      { new: true }
    );
    if (!org) throw notFound("Tenant");

    // Notify tenant owner
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      to: null, _meta: { userId: String(org.owner) },
      templateName: "accountStatusChanged",
      templateData: { orgName: org.name, status, reason },
    });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, org.tenantId, {
      type: "tenant.status_changed", orgId: id, status, adminUserId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "admin.tenant_status_changed", resourceType: "organization",
      resourceId: id, actor: { id: adminUserId }, tenantId: org.tenantId,
      meta: { status, reason }, category: "admin",
    });

    return org;
  }

  // ── System Stats ─────────────────────────────────────────────────────────────
  async getSystemStats() {
    const [orgs, users, projects, tasks, meetings, issues] = await Promise.all([
      mongoose.model("Organization").countDocuments(),
      mongoose.model("UserInfo").countDocuments(),
      mongoose.model("Project").countDocuments(),
      mongoose.model("Task").countDocuments(),
      mongoose.model("Meeting").countDocuments(),
      mongoose.model("Issue").countDocuments(),
    ]);

    const redis = getRedisClient();
    const activeConnections = await redis.get("ws:connections:total");
    return { orgs, users, projects, tasks, meetings, issues, activeConnections: +(activeConnections || 0) };
  }

  // ── User Management ───────────────────────────────────────────────────────────
  async listUsers({ tenantId, search, role, page = 1, limit = 20 }) {
    const User = mongoose.model("UserInfo");
    const filter = { tenantId };
    if (role)   filter.roles  = role;
    if (search) filter.$text  = { $search: search };

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      User.find(filter).select("-password -refreshTokens").skip(skip).limit(+limit).lean(),
      User.countDocuments(filter),
    ]);
    return { data, total, page: +page, limit: +limit, pages: Math.ceil(total / limit) };
  }

  async suspendUser({ userId, adminUserId, tenantId, reason }) {
    const User = mongoose.model("UserInfo");
    const user = await User.findByIdAndUpdate(userId, { isActive: false, suspendedAt: new Date() }, { new: true });
    if (!user) throw notFound("User");

    // Invalidate all Redis sessions
    const redis = getRedisClient();
    const sessionKeys = await redis.keys(`session:${userId}:*`);
    if (sessionKeys.length) await redis.del(...sessionKeys);

    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email", to: user.email,
      templateName: "accountSuspended",
      templateData: { reason },
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "admin.user_suspended", resourceType: "user",
      resourceId: userId, actor: { id: adminUserId }, tenantId, meta: { reason }, category: "admin",
    });

    return user;
  }

  // ── Impersonation ────────────────────────────────────────────────────────────
  async impersonateUser({ adminUserId, targetUserId }) {
    const User = mongoose.model("UserInfo");
    const target = await User.findById(targetUserId).lean();
    if (!target) throw notFound("User");
    if (target.roles?.includes("superadmin")) throw forbidden("Cannot impersonate a superadmin");

    // Short-lived impersonation token (30 min)
    const token = jwt.sign(
      {
        sub: target._id, email: target.email,
        tenantId: target.tenantId, roles: target.roles,
        impersonatedBy: adminUserId,
      },
      env.JWT_SECRET,
      { expiresIn: "30m" }
    );

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "admin.user_impersonated", resourceType: "user",
      resourceId: targetUserId, actor: { id: adminUserId }, tenantId: target.tenantId,
      category: "admin", severity: "high",
    });

    log.warn({ adminUserId, targetUserId }, "Impersonation token issued");
    return { token, target: { id: target._id, email: target.email, tenantId: target.tenantId } };
  }

  // ── Feature Flags ────────────────────────────────────────────────────────────
  async setFeatureFlag({ tenantId, flag, enabled, adminUserId }) {
    const redis = getRedisClient();
    await redis.set(`ff:${tenantId}:${flag}`, enabled ? "1" : "0");

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "admin.feature_flag_set", resourceType: "organization",
      actor: { id: adminUserId }, tenantId, meta: { flag, enabled }, category: "admin",
    });
    return { tenantId, flag, enabled };
  }

  async getFeatureFlags(tenantId) {
    const redis = getRedisClient();
    const keys = await redis.keys(`ff:${tenantId}:*`);
    const flags = {};
    for (const key of keys) {
      const flag = key.split(":")[2];
      flags[flag] = (await redis.get(key)) === "1";
    }
    return flags;
  }
}

export const adminService = new AdminService();
