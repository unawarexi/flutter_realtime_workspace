// ============================================================================
// TeamSpot — Workflow Worker
// Executes workflow automations (triggers → conditions → actions)
// ============================================================================

import { createLogger } from "../observability/logger.js";

const log = createLogger("WorkflowWorker");

export async function processWorkflow(job) {
  const { data } = job;

  try {
    log.info("Executing workflow", {
      workflowId: data.workflowId,
      trigger: data.trigger,
      tenantId: data.tenantId,
    });

    const Workflow = (await import("../modules/workflows/models/workflow.model.js")).default;
    const workflow = await Workflow.findById(data.workflowId);

    if (!workflow || !workflow.enabled) {
      log.warn("Workflow not found or disabled", { workflowId: data.workflowId });
      return;
    }

    // Evaluate conditions
    const conditionsMet = evaluateConditions(workflow.conditions, data.context);
    if (!conditionsMet) {
      log.debug("Workflow conditions not met", { workflowId: data.workflowId });
      return;
    }

    // Execute actions in order
    const sortedActions = workflow.actions.sort((a, b) => a.order - b.order);
    for (const action of sortedActions) {
      await executeAction(action, data.context);
    }

    // Update execution stats
    await Workflow.updateOne(
      { _id: data.workflowId },
      { $inc: { executionCount: 1 }, lastExecutedAt: new Date(), lastError: null }
    );

    log.info("Workflow executed successfully", { workflowId: data.workflowId });
  } catch (err) {
    log.error("Workflow execution failed", { error: err, workflowId: data.workflowId });

    try {
      const Workflow = (await import("../modules/workflows/models/workflow.model.js")).default;
      await Workflow.updateOne(
        { _id: data.workflowId },
        { lastError: err.message, status: "error" }
      );
    } catch {}

    throw err;
  }
}

function evaluateConditions(conditions, context) {
  if (!conditions || conditions.length === 0) return true;

  return conditions.every((cond) => {
    const fieldValue = context?.[cond.field];
    switch (cond.operator) {
      case "equals": return fieldValue === cond.value;
      case "not_equals": return fieldValue !== cond.value;
      case "contains": return String(fieldValue).includes(String(cond.value));
      case "gt": return fieldValue > cond.value;
      case "lt": return fieldValue < cond.value;
      case "in": return Array.isArray(cond.value) && cond.value.includes(fieldValue);
      case "not_in": return Array.isArray(cond.value) && !cond.value.includes(fieldValue);
      case "exists": return fieldValue !== undefined && fieldValue !== null;
      default: return false;
    }
  });
}

async function executeAction(action, context) {
  log.debug("Executing action", { type: action.type });

  switch (action.type) {
    case "send_notification":
    case "send_email":
      // Queue notification via RabbitMQ
      break;
    case "update_field":
    case "move_to_status":
      // Update entity in database
      break;
    case "assign_user":
      // Assign user to resource
      break;
    case "add_comment":
      // Add comment to resource
      break;
    case "trigger_webhook":
      // Send HTTP request to webhook URL
      break;
    case "add_tag":
    case "remove_tag":
      // Modify tags
      break;
    default:
      log.warn("Unknown action type", { type: action.type });
  }
}

export default { processWorkflow };
