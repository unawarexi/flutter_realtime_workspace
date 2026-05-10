// ============================================================================
// TeamSpot — Organization Service (full infrastructure integration)
// Org = top-level tenant; members, branding, settings, SSO, billing hooks
// ============================================================================

import { v4 as uuidv4 } from "uuid";
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Organization from "./models/organization.model.js";
import { notFound, forbidden, conflict, badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("OrganizationService");

class OrganizationRepository extends BaseRepository {
  constructor() { super(Organization, { tenantScoped: false }); } // orgs define the tenant
}

class OrganizationService extends BaseService {
  constructor() {
    super(new OrganizationRepository(), {
      name: "OrganizationService",
      cachePrefix: "org",
      cacheTTL: CacheTTL.ORGANIZATION || 600,
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────
  async createOrganization({ name, slug, industry, size, country, timezone, website, plan = "free" }, userId) {
    const existing = await this.repository.findOne({ slug });
    if (existing) throw conflict("Organization slug is already taken");

    const tenantId = `tnt_${uuidv4().replace(/-/g, "")}`;
    const org = await this.repository.create({
      name, slug, industry, size, country, timezone, website, plan,
      tenantId, owner: userId, createdBy: userId,
    });

    // Cache tenantId → orgId mapping
    const redis = getRedisClient();
    await redis.set(`tenant:slug:${slug}`, org._id.toString(), "EX", 86400);

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "organization.created", orgId: org._id, tenantId, ownerId: userId, plan,
    });

    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      to: null, // fetched by worker from user record; pass userId
      templateName: "organizationWelcome",
      templateData: { orgName: name, slug },
      _meta: { userId },
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "organization.created", resourceType: "organization",
      resourceId: org._id, actor: { id: userId }, tenantId,
    });

    eventBus.publish(DomainEvents.ORGANIZATION_CREATED, { orgId: org._id, tenantId, ownerId: userId });
    return org;
  }

  // ── Get ──────────────────────────────────────────────────────────────────────
  async getOrganizationById(id) {
    const org = await this.cachedFindById(id);
    if (!org) throw notFound("Organization");
    return org;
  }

  async getOrganizationByTenantId(tenantId) {
    const org = await this.repository.findOne({ tenantId });
    if (!org) throw notFound("Organization");
    return org;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateOrganization(id, updates, userId) {
    const org = await this.getOrganizationById(id);
    if (String(org.owner) !== String(userId)) throw forbidden("Only the owner can update the organization");

    const updated = await this.updateById(id, updates);
    emitToUser(String(userId), SocketEvents.WORKSPACE_UPDATED, { orgId: id });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, org.tenantId, { type: "organization.updated", orgId: id, userId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "organization.updated", resourceType: "organization",
      resourceId: id, actor: { id: userId }, tenantId: org.tenantId,
    });
    return updated;
  }

  // ── Settings ─────────────────────────────────────────────────────────────────
  async updateSettings(id, settings, userId) {
    const org = await this.getOrganizationById(id);
    if (String(org.owner) !== String(userId)) throw forbidden("Only the owner can update settings");

    const updated = await this.updateById(id, { settings: { ...org.settings?.toObject?.() || org.settings, ...settings } });
    return updated;
  }

  // ── Members ──────────────────────────────────────────────────────────────────
  async inviteMember({ orgId, email, role = "member", invitedBy, tenantId }) {
    const org = await this.getOrganizationById(orgId);

    // Enforce quotas
    if (org.memberCount >= org.quotas.maxMembers) throw badRequest("Member quota reached for this plan");

    const redis = getRedisClient();
    const token = uuidv4();
    await redis.set(
      `org_invite:${token}`,
      JSON.stringify({ orgId, email, role, invitedBy, tenantId }),
      "EX", 7 * 24 * 3600  // 7 days
    );

    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      to: email,
      templateName: "organizationInvite",
      templateData: {
        orgName: org.name,
        inviteLink: `${process.env.FRONTEND_URL}/invites/org/${token}`,
        role,
      },
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "organization.member_invited", resourceType: "organization",
      resourceId: orgId, actor: { id: invitedBy }, tenantId,
      meta: { email, role },
    });

    return { invited: email, token };
  }

  async acceptInvite(token, userId, userEmail) {
    const redis = getRedisClient();
    const raw = await redis.get(`org_invite:${token}`);
    if (!raw) throw badRequest("Invitation expired or invalid");

    const { orgId, email, role, tenantId } = JSON.parse(raw);
    if (email !== userEmail) throw forbidden("This invite was sent to a different email");

    await redis.del(`org_invite:${token}`);
    await this.updateById(orgId, { $inc: { memberCount: 1 } });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "organization.member_joined", orgId, userId, role, tenantId,
    });
    emitToUser(String(userId), SocketEvents.MEMBER_JOINED, { orgId, role });
    return { orgId, role };
  }

  // ── SSO ──────────────────────────────────────────────────────────────────────
  async updateSSO(id, ssoConfig, userId) {
    const org = await this.getOrganizationById(id);
    if (String(org.owner) !== String(userId)) throw forbidden("Only the owner can configure SSO");

    const updated = await this.updateById(id, { sso: ssoConfig });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "organization.sso_updated", resourceType: "organization",
      resourceId: id, actor: { id: userId }, tenantId: org.tenantId,
    });
    return updated;
  }
}

export const organizationService = new OrganizationService();
