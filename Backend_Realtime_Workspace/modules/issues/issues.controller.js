import { asyncHandler } from "../../core/base/base.controller.js";
import { issueService } from "./issue.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
});

export const createIssue = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const issue = await issueService.createIssue({ ...req.body, tenantId, userId });
  return created(res, issue, "Issue created");
});

export const listIssues = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await issueService.listIssues({ ...req.query, tenantId, userId });
  return paginated(res, result, "Issues retrieved");
});

export const getIssue = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const issue = await issueService.getIssueById(req.params.id, tenantId);
  return success(res, issue, "Issue retrieved");
});

export const updateIssue = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const issue = await issueService.updateIssue({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, issue, "Issue updated");
});

export const deleteIssue = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  await issueService.deleteIssue({ id: req.params.id, tenantId, userId });
  return noContent(res);
});

export const addComment = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const issue = await issueService.addComment({ id: req.params.id, content: req.body.content, tenantId, userId });
  return success(res, issue, "Comment added");
});

export const linkIssue = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const issue = await issueService.linkIssue({
    id: req.params.id, targetIssueId: req.body.targetIssueId,
    relation: req.body.relation, tenantId,
  });
  return success(res, issue, "Issue linked");
});

export const uploadAttachment = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  if (!req.file) return success(res, null, "No file provided");
  const attachment = await issueService.addAttachment({ id: req.params.id, file: req.file, tenantId, userId });
  return created(res, attachment, "Attachment uploaded");
});

export const issueController = {
  createIssue, listIssues, getIssue, updateIssue, deleteIssue,
  addComment, linkIssue, uploadAttachment,
};
