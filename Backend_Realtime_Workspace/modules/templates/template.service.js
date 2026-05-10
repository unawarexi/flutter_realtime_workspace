// ============================================================================
// TeamSpot — Template Service
// Manage reusable email / PDF / notification templates per tenant
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Template from "./models/template.model.js";
import { notFound, conflict } from "../../core/errors/app-error.js";
import { RabbitQueues, KafkaTopics } from "../../config/constants.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("TemplateService");

class TemplateRepository extends BaseRepository {
  constructor() {
    super(Template, { tenantScoped: true });
  }
}

class TemplateService extends BaseService {
  constructor() {
    super(new TemplateRepository(), {
      name: "TemplateService",
      cachePrefix: "template",
      cacheTTL: 300,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────
  async createTemplate({ tenantId, orgId, userId, name, type, body, subject, variables = [], category, slug, status = "draft" }) {
    const existing = await this.repository.findOne({ tenantId, slug, type });
    if (existing) throw conflict(`A ${type} template with slug '${slug}' already exists`);

    const template = await this.repository.create({
      tenantId, orgId,
      name, slug, type, body, subject,
      variables, category, status,
      createdBy: userId,
      version: 1,
    });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "template.created",
      templateId: template._id,
      tenantId, userId,
    });

    return template;
  }

  // ── List ────────────────────────────────────────────────────────────────────
  async listTemplates({ tenantId, type, status, category, page = 1, limit = 20 }) {
    const filter = { tenantId };
    if (type)     filter.type = type;
    if (status)   filter.status = status;
    if (category) filter.category = category;

    return this.repository.paginate({ filter, page, limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get by ID ────────────────────────────────────────────────────────────────
  async getTemplate({ id, tenantId }) {
    const template = await this.repository.findById(id, { tenantId });
    if (!template) throw notFound("Template");
    return template;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateTemplate({ id, tenantId, userId, updates }) {
    const template = await this.repository.findById(id, { tenantId });
    if (!template) throw notFound("Template");

    // Bump version on body change
    if (updates.body && updates.body !== template.body) {
      updates.version = (template.version || 1) + 1;
    }

    const updated = await this.repository.updateById(id, updates, { tenantId });
    log.info({ templateId: id }, "Template updated");
    return updated;
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  async deleteTemplate({ id, tenantId }) {
    const template = await this.repository.findById(id, { tenantId });
    if (!template) throw notFound("Template");
    if (template.isDefault) throw conflict("Cannot delete a default template");

    await this.repository.deleteById(id, { tenantId });
    return { message: "Template deleted" };
  }

  // ── Preview: render with sample data ─────────────────────────────────────────
  async previewTemplate({ id, tenantId, sampleData = {} }) {
    const template = await this.getTemplate({ id, tenantId });

    if (template.type === "email") {
      // Queue a test email via notification worker
      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email",
        to: sampleData.previewEmail || "preview@teamspot.io",
        templateName: "customTemplate",
        templateData: {
          recipientName: sampleData.recipientName || "Preview User",
          subject: template.subject || template.name,
          body: template.body,
          variables: sampleData,
        },
      });
      return { message: "Preview email queued", templateId: id };
    }

    // For non-email types return rendered body with variable substitution
    let rendered = template.body;
    for (const [key, val] of Object.entries(sampleData)) {
      rendered = rendered.replaceAll(`{{${key}}}`, val);
    }
    return { rendered, template };
  }
}

export const templateService = new TemplateService();
