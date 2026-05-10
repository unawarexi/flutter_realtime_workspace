import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Task from "./models/task.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";

class TaskRepository extends BaseRepository {
  constructor() {
    super(Task, { tenantScoped: true });
  }
}

class TaskService extends BaseService {
  constructor() {
    super(new TaskRepository(), {
      name: "TaskService",
      cachePrefix: "task",
      cacheTTL: 1800,
    });
  }

  async createTask(data, tenantId, userId, files = []) {
    const count = await this.repository.count({ projectId: data.projectId }, { tenantId });
    const key = `TSK-${String(count + 1).padStart(4, '0')}`;

    const newTask = await this.repository.create({
      ...data,
      key,
      tenantId,
      createdBy: userId,
      sortOrder: count,
    }, { tenantId });

    if (files.length > 0) {
      for (const file of files) {
        await this.addAttachment(newTask._id, file, tenantId, userId);
      }
    }

    this.emit("task.created", { taskId: newTask._id, tenantId, projectId: data.projectId, createdBy: userId });
    return newTask;
  }

  async getTaskById(id, tenantId) {
    const task = await this.cachedFindById(id, { tenantId });
    if (!task) throw new AppError(HttpStatus.NOT_FOUND, "Task not found", "E3008");
    return task;
  }

  async updateTask(id, updates, tenantId, userId) {
    const task = await this.getTaskById(id, tenantId);
    
    // Status transition tracking
    if (updates.status && updates.status !== task.status) {
      if (updates.status === 'done' || updates.status === 'cancelled') {
        updates.completedAt = new Date();
      } else if (task.status === 'done' || task.status === 'cancelled') {
        updates.completedAt = null;
      }
      this.emit("task.status_changed", { taskId: id, tenantId, oldStatus: task.status, newStatus: updates.status, userId });
    }

    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("task.updated", { taskId: id, tenantId, updates, userId });
    return updated;
  }

  async addComment(id, content, tenantId, userId) {
    const updated = await this.updateById(id, {
      $push: { comments: { userId, content, createdAt: new Date() } }
    }, { tenantId });
    
    this.emit("task.comment_added", { taskId: id, tenantId, userId });
    return updated;
  }

  async updateChecklist(id, checklist, tenantId) {
    const updated = await this.updateById(id, { checklist }, { tenantId });
    return updated;
  }

  async addAttachment(id, file, tenantId, userId) {
    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/tasks/${id}`,
      resourceType: "auto"
    });

    const attachment = {
      url: uploadResult.url,
      filename: file.originalname,
      bytes: uploadResult.bytes,
      uploadedAt: new Date()
    };

    const updated = await this.updateById(id, {
      $push: { attachments: attachment }
    }, { tenantId });

    return attachment;
  }
}

export const taskService = new TaskService();
