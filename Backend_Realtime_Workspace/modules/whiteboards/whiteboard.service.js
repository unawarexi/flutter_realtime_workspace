// ============================================================================
// TeamSpot — Whiteboard Service
// Real-time collaborative canvas with WebSocket + Kafka + Redis cursor tracking
// ============================================================================
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Whiteboard from "./models/whiteboard.model.js";
import { notFound, forbidden } from "../../core/errors/app-error.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToChannel, emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { KafkaTopics, RabbitQueues, SocketEvents } from "../../config/constants.js";

// Custom socket event keys for whiteboard real-time sync
const WB_EVENTS = {
  UPDATED: "whiteboard:updated",
  CURSOR: "whiteboard:cursor",
  COLLABORATOR_JOINED: "whiteboard:collaborator_joined",
  COLLABORATOR_LEFT: "whiteboard:collaborator_left",
  DELETED: "whiteboard:deleted",
};

class WhiteboardRepository extends BaseRepository {
  constructor() {
    super(Whiteboard, { tenantScoped: true });
  }
}

class WhiteboardService extends BaseService {
  constructor() {
    super(new WhiteboardRepository(), {
      name: "WhiteboardService",
      cachePrefix: "wb",
      cacheTTL: 1800,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  async createWhiteboard(data, tenantId, userId) {
    const newBoard = await this.repository.create(
      {
        ...data,
        tenantId,
        createdBy: userId,
        collaborators: [userId],
        version: 1,
      },
      { tenantId }
    );

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "whiteboard.created",
      whiteboardId: newBoard._id,
      tenantId,
      createdBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "whiteboard.created",
      resourceType: "whiteboard",
      resourceId: newBoard._id,
      actor: { id: userId },
      tenantId,
    });

    return newBoard;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  async getWhiteboardById(id, tenantId) {
    const board = await this.cachedFindById(id, { tenantId });
    if (!board) throw notFound("Whiteboard");
    return board;
  }

  // ── State Update (real-time canvas sync) ────────────────────────────────────

  async updateState(id, state, tenantId, userId) {
    // Optimistic concurrency via $inc version
    const updated = await this.updateById(
      id,
      { state, $inc: { version: 1 } },
      { tenantId }
    );

    if (!updated) throw notFound("Whiteboard");

    // Broadcast to all collaborators via WebSocket (using whiteboardId as the channel key)
    emitToChannel(id, WB_EVENTS.UPDATED, {
      whiteboardId: id,
      state,
      version: updated.version,
      updatedBy: userId,
    });

    // Track canvas activity in Kafka for analytics
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "whiteboard.state_updated",
      whiteboardId: id,
      tenantId,
      updatedBy: userId,
      version: updated.version,
    });

    return updated;
  }

  // ── Live Cursor Broadcast ────────────────────────────────────────────────────

  async broadcastCursor(id, cursor, tenantId, userId) {
    const redis = getRedisClient();
    const cursorKey = `wb_cursor:${id}:${userId}`;

    // Store cursor position in Redis with short TTL (8s = 1 idle update cycle)
    await redis.set(cursorKey, JSON.stringify({ x: cursor.x, y: cursor.y, userId }), "EX", 8);

    // Fan-out to all collaborators in the channel
    emitToChannel(id, WB_EVENTS.CURSOR, {
      whiteboardId: id,
      userId,
      cursor,
    });
  }

  // ── Collaborators ───────────────────────────────────────────────────────────

  async addCollaborator(id, collaboratorId, tenantId, actorId) {
    const board = await this.getWhiteboardById(id, tenantId);

    if (board.createdBy.toString() !== actorId) {
      throw forbidden("Only the board creator can add collaborators");
    }

    const alreadyIn = (board.collaborators || []).some(
      (c) => c.toString() === collaboratorId
    );
    if (alreadyIn) return board;

    const updated = await this.updateById(
      id,
      { $addToSet: { collaborators: collaboratorId } },
      { tenantId }
    );

    emitToUser(collaboratorId, WB_EVENTS.COLLABORATOR_JOINED, {
      whiteboardId: id,
      name: board.name,
      addedBy: actorId,
    });

    return updated;
  }

  async removeCollaborator(id, collaboratorId, tenantId, actorId) {
    const board = await this.getWhiteboardById(id, tenantId);

    if (board.createdBy.toString() !== actorId) {
      throw forbidden("Only the board creator can remove collaborators");
    }

    const updated = await this.updateById(
      id,
      { $pull: { collaborators: collaboratorId } },
      { tenantId }
    );

    emitToUser(collaboratorId, WB_EVENTS.COLLABORATOR_LEFT, {
      whiteboardId: id,
      name: board.name,
    });

    return updated;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  async deleteWhiteboard(id, tenantId, userId) {
    const board = await this.getWhiteboardById(id, tenantId);

    if (board.createdBy.toString() !== userId) {
      throw forbidden("Only the board creator can delete this whiteboard");
    }

    await this.updateById(id, { deletedAt: new Date() }, { tenantId });

    emitToChannel(id, WB_EVENTS.DELETED, { whiteboardId: id, deletedBy: userId });

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "whiteboard.deleted",
      whiteboardId: id,
      tenantId,
      deletedBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "whiteboard.deleted",
      resourceType: "whiteboard",
      resourceId: id,
      actor: { id: userId },
      tenantId,
    });
  }

  // ── Thumbnail Update ─────────────────────────────────────────────────────────

  async updateThumbnail(id, thumbnailUrl, tenantId) {
    return this.updateById(id, { thumbnailUrl }, { tenantId });
  }
}

export const whiteboardService = new WhiteboardService();
