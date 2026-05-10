import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Project from "./models/project.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";
import { generateProjectKey } from "../../core/utils/id-generator.js";

class ProjectRepository extends BaseRepository {
  constructor() {
    super(Project, { tenantScoped: true });
  }
}

class ProjectService extends BaseService {
  constructor() {
    super(new ProjectRepository(), {
      name: "ProjectService",
      cachePrefix: "project",
      cacheTTL: 1800,
    });
  }

  async createProject(data, tenantId, userId, files = []) {
    // Generate key (e.g., PROJ-001)
    const count = await this.repository.count({}, { tenantId });
    const key = `PRJ-${String(count + 1).padStart(3, '0')}`;

    const newProject = await this.repository.create({
      ...data,
      key,
      tenantId,
      createdBy: userId,
      collaborators: [userId],
      timeline: [{ title: "Project Created", description: "Initial setup", type: "system" }]
    }, { tenantId });

    // Handle attachments if any
    if (files.length > 0) {
      for (const file of files) {
        await this.addAttachment(newProject._id, file, tenantId, userId);
      }
    }

    this.emit("project.created", { projectId: newProject._id, tenantId, createdBy: userId });
    return newProject;
  }

  async getProjectById(id, tenantId) {
    const project = await this.cachedFindById(id, { tenantId });
    if (!project) throw new AppError(HttpStatus.NOT_FOUND, "Project not found", "E3006");
    return project;
  }

  async updateProject(id, updates, tenantId, userId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("project.updated", { projectId: id, tenantId, userId, updates });
    return updated;
  }

  async toggleStar(id, tenantId) {
    const project = await this.getProjectById(id, tenantId);
    const updated = await this.updateById(id, { starred: !project.starred }, { tenantId });
    return updated;
  }

  async toggleArchive(id, tenantId, userId) {
    const project = await this.getProjectById(id, tenantId);
    const updated = await this.updateById(id, { 
      archived: !project.archived, 
      status: project.archived ? "active" : "archived" 
    }, { tenantId });
    
    this.emit("project.archived_toggled", { projectId: id, tenantId, archived: !project.archived, userId });
    return updated;
  }

  async updateCollaborators(id, collaborators, tenantId) {
    const updated = await this.updateById(id, { collaborators }, { tenantId });
    this.emit("project.collaborators_updated", { projectId: id, tenantId });
    return updated;
  }

  async addTimelineEvent(id, event, tenantId) {
    const updated = await this.updateById(id, {
      $push: { timeline: event }
    }, { tenantId });
    return updated;
  }

  async addAttachment(id, file, tenantId, userId) {
    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/projects/${id}`,
      resourceType: "auto" // Auto detect image/video/raw
    });

    const attachment = {
      url: uploadResult.url,
      public_id: uploadResult.publicId,
      resource_type: uploadResult.resourceType,
      format: uploadResult.format,
      bytes: uploadResult.bytes,
      filename: file.originalname,
      uploadedBy: userId,
      uploadedAt: new Date()
    };

    const updated = await this.updateById(id, {
      $push: { attachments: attachment }
    }, { tenantId });

    return attachment;
  }

  async removeAttachment(id, attachmentId, tenantId) {
    const project = await this.getProjectById(id, tenantId);
    const attachment = project.attachments.id(attachmentId); // Assuming mongoose document array
    
    if (!attachment) {
      throw new AppError(HttpStatus.NOT_FOUND, "Attachment not found", "E3007");
    }

    // Delete from cloudinary
    if (attachment.public_id) {
      await deleteFile(attachment.public_id);
    }

    const updated = await this.updateById(id, {
      $pull: { attachments: { _id: attachmentId } }
    }, { tenantId });

    return updated;
  }
}

export const projectService = new ProjectService();
