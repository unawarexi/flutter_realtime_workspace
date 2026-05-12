// ============================================================================
// TeamSpot — Task Service
// Full Kafka + RabbitMQ + WebSocket + Redis integration
// ============================================================================
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Task from "./models/task.model.js";
import { notFound, forbidden } from "../../core/errors/app-error.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser, emitToWorkspace } from "../../infrastructure/websocket/websocket.service.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";
import { KafkaTopics, RabbitQueues, SocketEvents } from "../../config/constants.js";

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
      cacheTTL: 30,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  async createTask(data, tenantId, userId, files = []) {
    const count = await this.repository.count({ projectId: data.projectId }, { tenantId });
    const key = `TSK-${String(count + 1).padStart(4, "0")}`;

    const newTask = await this.repository.create(
      { ...data, key, tenantId, createdBy: userId, sortOrder: count },
      { tenantId }
    );

    // Upload any attached files
    for (const file of files) {
      await this.addAttachment(newTask._id, file, tenantId, userId);
    }

    // Kafka event
    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "task.created",
      taskId: newTask._id,
      projectId: data.projectId,
      tenantId,
      createdBy: userId,
    });

    // WebSocket — notify workspace
    emitToWorkspace(tenantId, SocketEvents.TASK_CREATED, {
      taskId: newTask._id,
      key,
      title: newTask.title,
      projectId: data.projectId,
      createdBy: userId,
    });

    // Email assignee if set at creation
    if (data.assignedTo && data.assignedTo !== userId) {
      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email",
        to: null, // consumer resolves userId → email
        userId: data.assignedTo,
        templateName: "taskAssigned",
        templateData: {
          taskKey: key,
          taskTitle: newTask.title,
          projectId: data.projectId,
          assignedBy: userId,
          dueDate: data.dueDate || null,
        },
      });

      emitToUser(data.assignedTo, SocketEvents.TASK_ASSIGNED, {
        taskId: newTask._id,
        key,
        title: newTask.title,
        assignedBy: userId,
      });
    }

    // Audit
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "task.created",
      resourceType: "task",
      resourceId: newTask._id,
      actor: { id: userId },
      tenantId,
      metadata: { key, projectId: data.projectId },
    });

    return newTask;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  async getTaskById(id, tenantId) {
    const task = await this.cachedFindById(id, { tenantId });
    if (!task) throw notFound("Task");
    return task;
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  async updateTask(id, updates, tenantId, userId) {
    const task = await this.getTaskById(id, tenantId);
    const prevAssignee = task.assignedTo?.toString();
    const prevStatus = task.status;

    // Status transition tracking
    if (updates.status && updates.status !== prevStatus) {
      if (["done", "cancelled"].includes(updates.status)) {
        updates.completedAt = new Date();
      } else if (["done", "cancelled"].includes(prevStatus)) {
        updates.completedAt = null;
      }
    }

    const updated = await this.updateById(id, updates, { tenantId });

    // Kafka
    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "task.updated",
      taskId: id,
      tenantId,
      updatedBy: userId,
      changes: Object.keys(updates),
    });

    // WebSocket update to workspace
    emitToWorkspace(tenantId, SocketEvents.TASK_UPDATED, {
      taskId: id,
      updatedBy: userId,
      changes: Object.keys(updates),
    });

    // If status completed → emit TASK_COMPLETED
    if (updates.status === "done" && prevStatus !== "done") {
      await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
        type: "task.completed",
        taskId: id,
        tenantId,
        completedBy: userId,
      });

      emitToWorkspace(tenantId, SocketEvents.TASK_COMPLETED, {
        taskId: id,
        key: task.key,
        title: task.title,
        completedBy: userId,
      });
    }

    // Assignee changed → notify new assignee
    const newAssignee = updates.assignedTo?.toString();
    if (newAssignee && newAssignee !== prevAssignee && newAssignee !== userId) {
      emitToUser(newAssignee, SocketEvents.TASK_ASSIGNED, {
        taskId: id,
        key: task.key,
        title: task.title,
        assignedBy: userId,
      });

      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email",
        userId: newAssignee,
        templateName: "taskAssigned",
        templateData: {
          taskKey: task.key,
          taskTitle: task.title,
          assignedBy: userId,
          dueDate: updates.dueDate || task.dueDate,
        },
      });
    }

    // Audit
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "task.updated",
      resourceType: "task",
      resourceId: id,
      actor: { id: userId },
      tenantId,
      metadata: { changes: Object.keys(updates) },
    });

    return updated;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  async deleteTask(id, tenantId, userId) {
    await this.getTaskById(id, tenantId);
    await this.updateById(id, { deletedAt: new Date() }, { tenantId });

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "task.deleted",
      taskId: id,
      tenantId,
      deletedBy: userId,
    });

    emitToWorkspace(tenantId, SocketEvents.TASK_UPDATED, {
      taskId: id,
      action: "deleted",
      deletedBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "task.deleted",
      resourceType: "task",
      resourceId: id,
      actor: { id: userId },
      tenantId,
    });
  }

  // ── Comments ────────────────────────────────────────────────────────────────

  async addComment(id, content, tenantId, userId) {
    const task = await this.getTaskById(id, tenantId);

    const updated = await this.updateById(
      id,
      { $push: { comments: { userId, content, createdAt: new Date() } } },
      { tenantId }
    );

    // Notify assignee about new comment (if not the commenter)
    if (task.assignedTo && task.assignedTo.toString() !== userId) {
      emitToUser(task.assignedTo.toString(), SocketEvents.NOTIFICATION, {
        type: "task.comment",
        taskId: id,
        taskTitle: task.title,
        commentBy: userId,
      });
    }

    // Notify creator too if different from commenter
    if (task.createdBy && task.createdBy.toString() !== userId) {
      emitToUser(task.createdBy.toString(), SocketEvents.NOTIFICATION, {
        type: "task.comment",
        taskId: id,
        taskTitle: task.title,
        commentBy: userId,
      });
    }

    return updated;
  }

  // ── Checklist ───────────────────────────────────────────────────────────────

  async updateChecklist(id, checklist, tenantId, userId) {
    const updated = await this.updateById(id, { checklist }, { tenantId });

    emitToWorkspace(tenantId, SocketEvents.TASK_UPDATED, {
      taskId: id,
      action: "checklist_updated",
      updatedBy: userId,
    });

    return updated;
  }

  // ── Attachments ─────────────────────────────────────────────────────────────

  async addAttachment(id, file, tenantId, userId) {
    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/tasks/${id}`,
      resourceType: "auto",
    });

    const attachment = {
      url: uploadResult.url,
      filename: file.originalname,
      bytes: uploadResult.bytes,
      uploadedAt: new Date(),
    };

    await this.updateById(id, { $push: { attachments: attachment } }, { tenantId });

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "task.attachment_added",
      taskId: id,
      tenantId,
      uploadedBy: userId,
    });

    return attachment;
  }

  // ── Log Hours ───────────────────────────────────────────────────────────────

  async logHours(id, hours, tenantId, userId) {
    const updated = await this.updateById(
      id,
      { $inc: { loggedHours: hours } },
      { tenantId }
    );

    await publishEvent(KafkaTopics.TASK_EVENTS, tenantId, {
      type: "task.hours_logged",
      taskId: id,
      tenantId,
      hours,
      loggedBy: userId,
    });

    return updated;
  }

  // ── Watchers ────────────────────────────────────────────────────────────────

  async watchTask(id, tenantId, userId) {
    const updated = await this.updateById(
      id,
      { $addToSet: { watchers: userId } },
      { tenantId }
    );
    return updated;
  }

  async unwatchTask(id, tenantId, userId) {
    const updated = await this.updateById(
      id,
      { $pull: { watchers: userId } },
      { tenantId }
    );
    return updated;
  }
}

export const taskService = new TaskService();
