import { asyncHandler } from "../../core/base/base.controller.js";
import { workflowService } from "./workflow.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId:  req.tenant?.id || req.user?.tenantId,
  userId:    req.user?._id?.toString() || req.user?.id,
  orgId:     req.user?.orgId || null,
});

export const createWorkflow = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const wf = await workflowService.createWorkflow({ ...req.body, tenantId, userId, orgId });
  return created(res, wf, "Workflow created");
});

export const listWorkflows = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await workflowService.listWorkflows({ ...req.query, tenantId });
  return paginated(res, result, "Workflows retrieved");
});

export const getWorkflow = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const wf = await workflowService.getWorkflowById(req.params.id, tenantId);
  return success(res, wf, "Workflow retrieved");
});

export const updateWorkflow = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const wf = await workflowService.updateWorkflow({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, wf, "Workflow updated");
});

export const toggleWorkflow = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const wf = await workflowService.toggleWorkflow({ id: req.params.id, enabled: req.body.enabled, tenantId, userId });
  return success(res, wf, `Workflow ${req.body.enabled ? "enabled" : "disabled"}`);
});

export const deleteWorkflow = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await workflowService.deleteWorkflow({ id: req.params.id, tenantId, userId });
  return noContent(res);
});

export const executeManual = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await workflowService.executeManual({ id: req.params.id, tenantId, userId, payload: req.body });
  return success(res, result, "Workflow executed");
});

export const workflowController = {
  createWorkflow, listWorkflows, getWorkflow, updateWorkflow,
  toggleWorkflow, deleteWorkflow, executeManual,
};
