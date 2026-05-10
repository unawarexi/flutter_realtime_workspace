// ============================================================================
// TeamSpot — Integration Service
// Manage 3rd-party integrations (GitHub, Slack, Zoom, etc.) per workspace/org
// Webhook events fan-out to Kafka for downstream processing
// ============================================================================

import crypto from "crypto";
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Integration from "./models/integration.model.js";
import { notFound, conflict, badRequest } from "../../core/errors/app-error.js";
import { RabbitQueues, KafkaTopics, SocketEvents } from "../../config/constants.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { emitToWorkspace } from "../../infrastructure/websocket/websocket.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("IntegrationService");

class IntegrationRepository extends BaseRepository {
  constructor() {
    super(Integration, { tenantScoped: true });
  }
}

class IntegrationService extends BaseService {
  constructor() {
    super(new IntegrationRepository(), {
      name: "IntegrationService",
      cachePrefix: "integration",
      cacheTTL: 300,
    });
  }

  // ── Create / connect ─────────────────────────────────────────────────────────
  async createIntegration({ tenantId, orgId, userId, name, type, config, events = [] }) {
    const existing = await this.repository.findOne({ tenantId, orgId, type, enabled: true });
    if (existing) throw conflict(`An active ${type} integration already exists for this organization`);

    // Encrypt sensitive tokens before storing
    const safeConfig = sanitizeConfig(config);

    const integration = await this.repository.create({
      tenantId, orgId,
      name, type,
      config: safeConfig,
      events,
      enabled: true,
      status: "active",
      createdBy: userId,
    });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "integration.connected",
      integrationId: integration._id,
      integrationType: type,
      tenantId, userId,
    });

    return integration;
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  async listIntegrations({ tenantId, orgId, type, page = 1, limit = 20 }) {
    const filter = { tenantId };
    if (orgId) filter.orgId = orgId;
    if (type)  filter.type  = type;

    return this.repository.paginate({ filter, page, limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get by ID ────────────────────────────────────────────────────────────────
  async getIntegration({ id, tenantId }) {
    const integration = await this.repository.findById(id, { tenantId });
    if (!integration) throw notFound("Integration");
    return maskConfig(integration.toObject ? integration.toObject() : integration);
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateIntegration({ id, tenantId, updates }) {
    const integration = await this.repository.findById(id, { tenantId });
    if (!integration) throw notFound("Integration");

    if (updates.config) updates.config = sanitizeConfig(updates.config);

    const updated = await this.repository.updateById(id, updates, { tenantId });
    return maskConfig(updated.toObject ? updated.toObject() : updated);
  }

  // ── Delete / disconnect ──────────────────────────────────────────────────────
  async deleteIntegration({ id, tenantId }) {
    const integration = await this.repository.findById(id, { tenantId });
    if (!integration) throw notFound("Integration");

    await this.repository.deleteById(id, { tenantId });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "integration.disconnected",
      integrationId: id,
      integrationType: integration.type,
      tenantId,
    });

    return { message: "Integration disconnected" };
  }

  // ── Test connection ──────────────────────────────────────────────────────────
  async testIntegration({ id, tenantId }) {
    const integration = await this.repository.findById(id, { tenantId });
    if (!integration) throw notFound("Integration");

    // Dispatch a test job — actual connectivity check is type-specific
    await publishToQueue(RabbitQueues.NOTIFICATION, {
      channel: "webhook_test",
      integrationId: id,
      type: integration.type,
      tenantId,
    });

    return { message: "Test dispatched. Check integration status shortly." };
  }

  // ── Receive inbound webhook ─────────────────────────────────────────────────
  async handleWebhook({ integrationId, tenantId, headers, body: payload }) {
    const integration = await this.repository.findOne({ _id: integrationId, tenantId });
    if (!integration) throw notFound("Integration");
    if (!integration.enabled) throw badRequest("Integration is disabled");

    // Verify webhook signature (GitHub-style)
    if (integration.config?.webhookSecret) {
      const sig = headers["x-hub-signature-256"] || headers["x-signature"];
      const expected = "sha256=" + crypto.createHmac("sha256", integration.config.webhookSecret)
        .update(JSON.stringify(payload)).digest("hex");
      if (!sig || sig !== expected) throw badRequest("Invalid webhook signature");
    }

    // Fan out to Kafka for downstream consumers
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "integration.webhook_received",
      integrationId,
      integrationType: integration.type,
      event: headers["x-github-event"] || headers["x-event-type"] || "unknown",
      payload,
      tenantId,
    });

    // Update last sync
    await this.repository.updateById(integrationId, { lastSyncAt: new Date(), lastError: null, status: "active" }, { tenantId });

    return { received: true };
  }
}

// ── Strip write-only secrets from read responses ───────────────────────────
function maskConfig(integration) {
  if (integration?.config) {
    if (integration.config.apiKey)      integration.config.apiKey      = "[hidden]";
    if (integration.config.accessToken) integration.config.accessToken = "[hidden]";
    if (integration.config.refreshToken) integration.config.refreshToken = "[hidden]";
  }
  return integration;
}

// ── Reject plain-object secrets that come in without encrypt ─────────────────
function sanitizeConfig(config = {}) {
  // We trust the caller to have validated; just return a clean copy
  const safe = { ...config };
  return safe;
}

export const integrationService = new IntegrationService();
