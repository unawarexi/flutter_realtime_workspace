import BaseController from "../../core/base/base.controller.js";
import { issueService } from "./issue.service.js";

class IssueController extends BaseController {
  
  createIssue = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const issue = await issueService.createIssue(req.body, tenantId, userId, files);
    return BaseController.sendCreated(res, issue, "Issue created successfully");
  };

  getIssues = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const { projectId, status, assignedTo, type } = req.query;
    
    const filter = {};
    if (projectId) filter.projectId = projectId;
    if (status) filter.status = status;
    if (type) filter.type = type;
    if (assignedTo) filter.assignedTo = assignedTo === 'me' ? userId : assignedTo;
    
    const pagination = BaseController.getPagination(req);
    const result = await issueService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Issues retrieved");
  };

  getIssueById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const issue = await issueService.getIssueById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, issue, "Issue retrieved");
  };

  updateIssue = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const issue = await issueService.updateIssue(req.params.id, req.body, tenantId, userId);
    return BaseController.sendSuccess(res, issue, "Issue updated");
  };

  deleteIssue = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await issueService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Issue deleted");
  };

  addComment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const issue = await issueService.addComment(req.params.id, req.body.content, tenantId, userId);
    return BaseController.sendSuccess(res, issue, "Comment added");
  };

  linkIssue = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { targetIssueId, relation } = req.body;
    const issue = await issueService.linkIssue(req.params.id, targetIssueId, relation, tenantId);
    return BaseController.sendSuccess(res, issue, "Issue linked");
  };

  uploadAttachment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    if (!req.file) return BaseController.sendSuccess(res, null, "No file provided");
    const attachment = await issueService.addAttachment(req.params.id, req.file, tenantId, userId);
    return BaseController.sendCreated(res, attachment, "Attachment uploaded");
  };
}

export const issueController = new IssueController();
