import BaseController from "../../core/base/base.controller.js";
import { workflowService } from "./workflow.service.js";

class WorkflowController extends BaseController {
  
  createWorkflow = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const workflow = await workflowService.createWorkflow(req.body, tenantId, orgId, userId);
    return BaseController.sendCreated(res, workflow, "Workflow created successfully");
  };

  getWorkflows = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const { enabled, triggerType } = req.query;
    
    const filter = { orgId };
    if (enabled !== undefined) filter.enabled = enabled === 'true';
    if (triggerType) filter['trigger.type'] = triggerType;
    
    const pagination = BaseController.getPagination(req);
    const result = await workflowService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Workflows retrieved");
  };

  getWorkflowById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const workflow = await workflowService.getWorkflowById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, workflow, "Workflow retrieved");
  };

  updateWorkflow = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const workflow = await workflowService.updateWorkflow(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, workflow, "Workflow updated");
  };

  deleteWorkflow = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await workflowService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Workflow deleted");
  };

  toggleWorkflow = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { enabled } = req.body;
    const workflow = await workflowService.toggleWorkflow(req.params.id, enabled, tenantId);
    return BaseController.sendSuccess(res, workflow, `Workflow ${enabled ? 'enabled' : 'disabled'}`);
  };

  testWorkflow = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    // Triggers the workflow manually
    workflowService.emit("workflow.triggered", { workflowId: req.params.id, payload: req.body });
    return BaseController.sendSuccess(res, null, "Workflow test triggered");
  };
}

export const workflowController = new WorkflowController();
