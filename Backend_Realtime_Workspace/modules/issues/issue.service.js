import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Issue from "./models/issue.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";

class IssueRepository extends BaseRepository {
  constructor() {
    super(Issue, { tenantScoped: true });
  }
}

class IssueService extends BaseService {
  constructor() {
    super(new IssueRepository(), {
      name: "IssueService",
      cachePrefix: "issue",
      cacheTTL: 1800,
    });
  }

  async createIssue(data, tenantId, userId, files = []) {
    const count = await this.repository.count({ projectId: data.projectId }, { tenantId });
    const key = `ISSUE-${String(count + 1).padStart(4, '0')}`;

    const newIssue = await this.repository.create({
      ...data,
      key,
      tenantId,
      createdBy: userId,
      reporter: userId,
    }, { tenantId });

    if (files.length > 0) {
      for (const file of files) {
        await this.addAttachment(newIssue._id, file, tenantId, userId);
      }
    }

    this.emit("issue.created", { issueId: newIssue._id, tenantId, projectId: data.projectId, createdBy: userId });
    return newIssue;
  }

  async getIssueById(id, tenantId) {
    const issue = await this.cachedFindById(id, { tenantId });
    if (!issue) throw new AppError(HttpStatus.NOT_FOUND, "Issue not found", "E3009");
    return issue;
  }

  async updateIssue(id, updates, tenantId, userId) {
    const issue = await this.getIssueById(id, tenantId);
    
    // Status tracking
    if (updates.status && updates.status !== issue.status) {
      if (updates.status === 'resolved') updates.resolvedAt = new Date();
      if (updates.status === 'closed') updates.closedAt = new Date();
      this.emit("issue.status_changed", { issueId: id, tenantId, oldStatus: issue.status, newStatus: updates.status, userId });
    }

    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("issue.updated", { issueId: id, tenantId, updates, userId });
    return updated;
  }

  async addComment(id, content, tenantId, userId) {
    const updated = await this.updateById(id, {
      $push: { comments: { userId, content, createdAt: new Date() } }
    }, { tenantId });
    
    this.emit("issue.comment_added", { issueId: id, tenantId, userId });
    return updated;
  }

  async linkIssue(id, targetIssueId, relation, tenantId) {
    const updated = await this.updateById(id, {
      $push: { linkedIssues: { issueId: targetIssueId, relation } }
    }, { tenantId });
    return updated;
  }

  async addAttachment(id, file, tenantId, userId) {
    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/issues/${id}`,
      resourceType: "auto"
    });

    const attachment = {
      url: uploadResult.url,
      filename: file.originalname,
      bytes: uploadResult.bytes
    };

    const updated = await this.updateById(id, {
      $push: { attachments: attachment }
    }, { tenantId });

    return attachment;
  }
}

export const issueService = new IssueService();
