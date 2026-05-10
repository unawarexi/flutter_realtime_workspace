import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Workflow from "./models/workflow.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { v4 as uuidv4 } from "uuid";

class WorkflowRepository extends BaseRepository {
  constructor() {
    super(Workflow, { tenantScoped: true });
  }
}

class WorkflowService extends BaseService {
  constructor() {
    super(new WorkflowRepository(), {
      name: "WorkflowService",
      cachePrefix: "workflow",
      cacheTTL: 1800,
    });
  }

  async createWorkflow(data, tenantId, orgId, userId) {
    const newWorkflow = await this.repository.create({
      ...data,
      tenantId,
      orgId,
      createdBy: userId,
      enabled: true,
      status: "active"
    }, { tenantId });

    if (newWorkflow.trigger.type === "webhook") {
      newWorkflow.trigger.webhookUrl = `/api/v1/webhooks/workflows/${newWorkflow._id}/${uuidv4()}`;
      await newWorkflow.save();
    }

    this.emit("workflow.created", { workflowId: newWorkflow._id, tenantId, orgId });
    return newWorkflow;
  }

  async getWorkflowById(id, tenantId) {
    const workflow = await this.cachedFindById(id, { tenantId });
    if (!workflow) throw new AppError(HttpStatus.NOT_FOUND, "Workflow not found", "E3011");
    return workflow;
  }

  async updateWorkflow(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("workflow.updated", { workflowId: id, tenantId, updates });
    return updated;
  }

  async toggleWorkflow(id, enabled, tenantId) {
    const status = enabled ? "active" : "paused";
    const updated = await this.updateById(id, { enabled, status }, { tenantId });
    this.emit("workflow.toggled", { workflowId: id, tenantId, enabled });
    return updated;
  }

  // Engine evaluation hook (stubbed)
  async evaluateEvent(eventPayload, tenantId) {
    // This is where we'd query active workflows that listen to this event type
    // and queue them into a Redis worker for asynchronous execution.
    const activeWorkflows = await this.repository.find({
      tenantId,
      enabled: true,
      "trigger.type": "event",
      "trigger.event": eventPayload.type
    });

    for (const wf of activeWorkflows) {
      this.emit("workflow.triggered", { workflowId: wf._id, payload: eventPayload });
      // In reality: enqueue Job to evaluate conditions and run actions.
    }
  }
}

export const workflowService = new WorkflowService();
