// ============================================================================
// TeamSpot — Workflow Service (automation engine)
// Trigger → Conditions → Actions; event matching dispatched via Kafka/RabbitMQ
// ============================================================================

import { v4 as uuidv4 } from "uuid";
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Workflow from "./models/workflow.model.js";
import { notFound, badRequest } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("WorkflowService");

class WorkflowRepository extends BaseRepository {
  constructor() { super(Workflow, { tenantScoped: true }); }
}

class WorkflowService extends BaseService {
  constructor() {
    super(new WorkflowRepository(), {
      name: "WorkflowService",
      cachePrefix: "workflow",
      cacheTTL: CacheTTL.PROJECT || 60,
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────
  async createWorkflow({ tenantId, orgId, workspaceId, userId, name, description, trigger, conditions = [], actions = [] }) {
    const workflow = await this.repository.create({
      name, description, tenantId, orgId, workspaceId,
      trigger, conditions, actions,
      createdBy: userId, enabled: true, status: "active",
    }, { tenantId });

    // Generate webhook URL for webhook-triggered workflows
    if (trigger?.type === "webhook") {
      const secret = uuidv4();
      await this.updateById(workflow._id, {
        "trigger.webhookUrl": `/api/v1/webhooks/workflows/${workflow._id}`,
        "trigger.webhookSecret": secret,
      }, { tenantId });
    }

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "workflow.created", workflowId: workflow._id, tenantId, orgId, userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "workflow.created", resourceType: "workflow",
      resourceId: workflow._id, actor: { id: userId }, tenantId,
    });

    return workflow;
  }

  // ── List ─────────────────────────────────────────────────────────────────────
  async listWorkflows({ tenantId, workspaceId, enabled, page = 1, limit = 20 }) {
    const filter = {};
    if (workspaceId !== undefined) filter.workspaceId = workspaceId;
    if (enabled !== undefined) filter.enabled = enabled === "true" || enabled === true;
    return this.repository.paginate({ filter, page: +page, limit: +limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get ──────────────────────────────────────────────────────────────────────
  async getWorkflowById(id, tenantId) {
    const wf = await this.cachedFindById(id, { tenantId });
    if (!wf) throw notFound("Workflow");
    return wf;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateWorkflow({ id, updates, tenantId, userId }) {
    const updated = await this.updateById(id, updates, { tenantId });
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, { type: "workflow.updated", workflowId: id, userId, tenantId });
    return updated;
  }

  // ── Toggle ───────────────────────────────────────────────────────────────────
  async toggleWorkflow({ id, enabled, tenantId, userId }) {
    const updated = await this.updateById(id, { enabled, status: enabled ? "active" : "paused" }, { tenantId });
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "workflow.toggled", workflowId: id, enabled, userId, tenantId,
    });
    return updated;
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  async deleteWorkflow({ id, tenantId, userId }) {
    await this.updateById(id, { status: "deleted", enabled: false }, { tenantId });
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "workflow.deleted", resourceType: "workflow",
      resourceId: id, actor: { id: userId }, tenantId,
    });
  }

  // ── Evaluate Event (called by workflow.worker.js) ────────────────────────────
  async evaluateEvent({ eventPayload, tenantId }) {
    const activeWorkflows = await this.repository.model.find({
      tenantId,
      enabled: true,
      status: "active",
      "trigger.type": "event",
      "trigger.event": eventPayload.type,
    }).lean();

    for (const wf of activeWorkflows) {
      const conditionsPass = this._evaluateConditions(wf.conditions, eventPayload);
      if (!conditionsPass) continue;

      // Enqueue action execution via AI_AGENT_TASK worker
      await publishToQueue(RabbitQueues.AI_AGENT_TASK, {
        type: "workflow.execute",
        workflowId: wf._id,
        actions: wf.actions,
        payload: eventPayload,
        tenantId,
      });

      // Update stats
      await this.repository.model.updateOne(
        { _id: wf._id },
        { $inc: { executionCount: 1 }, $set: { lastExecutedAt: new Date() } }
      );

      log.debug({ workflowId: wf._id, event: eventPayload.type }, "Workflow triggered");
    }
  }

  // ── Execute Manual ────────────────────────────────────────────────────────────
  async executeManual({ id, tenantId, userId, payload }) {
    const wf = await this.getWorkflowById(id, tenantId);
    if (wf.trigger.type !== "manual") throw badRequest("This workflow is not manually triggered");

    await publishToQueue(RabbitQueues.AI_AGENT_TASK, {
      type: "workflow.execute",
      workflowId: wf._id, actions: wf.actions,
      payload: { ...payload, executedBy: userId }, tenantId,
    });

    await this.repository.model.updateOne(
      { _id: id },
      { $inc: { executionCount: 1 }, $set: { lastExecutedAt: new Date() } }
    );

    return { triggered: true, workflowId: id };
  }

  // ── Handle Inbound Webhook ───────────────────────────────────────────────────
  async handleWebhook({ id, payload, tenantId }) {
    const wf = await this.getWorkflowById(id, tenantId);
    if (wf.trigger.type !== "webhook") throw badRequest("Workflow is not webhook-triggered");

    await publishToQueue(RabbitQueues.AI_AGENT_TASK, {
      type: "workflow.execute",
      workflowId: wf._id, actions: wf.actions, payload, tenantId,
    });

    return { triggered: true };
  }

  // ── Private: Condition Evaluator ─────────────────────────────────────────────
  _evaluateConditions(conditions, payload) {
    if (!conditions?.length) return true;
    for (const cond of conditions) {
      const value = cond.field.split(".").reduce((o, k) => o?.[k], payload);
      const pass = (() => {
        switch (cond.operator) {
          case "equals":     return value === cond.value;
          case "not_equals": return value !== cond.value;
          case "contains":   return String(value).includes(String(cond.value));
          case "gt":         return value > cond.value;
          case "lt":         return value < cond.value;
          case "in":         return Array.isArray(cond.value) && cond.value.includes(value);
          case "not_in":     return Array.isArray(cond.value) && !cond.value.includes(value);
          case "exists":     return value !== undefined && value !== null;
          default:           return true;
        }
      })();
      if (!pass) return false;
    }
    return true;
  }
}

export const workflowService = new WorkflowService();
