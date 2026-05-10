// ============================================================================
// TeamSpot — Video Service
// LiveKit room and token orchestration
// ============================================================================

import {
  initLiveKit,
  generateToken,
  listRooms,
  deleteRoom,
  listParticipants,
  removeParticipant,
} from "../../infrastructure/livekit/livekit.service.js";
import { AppError } from "../../core/errors/app-error.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("VideoService");

export class VideoService {
  async generateRoomToken({ roomName, identity, displayName, tenantId, permissions = {} }) {
    if (!roomName || !identity) throw AppError.badRequest("roomName and identity are required");
    const token = await generateToken(roomName, identity, {
      name: displayName || identity,
      roomAdmin: permissions.canAdminRoom || false,
      roomRecord: permissions.canRecord || false,
    });
    log.info("Room token generated", { roomName, identity, tenantId });
    return { token, roomName, identity };
  }

  async createManagedRoom({ roomName, maxParticipants, emptyTimeout, metadata, tenantId }) {
    if (!roomName) throw AppError.badRequest("roomName is required");
    const { RoomServiceClient } = await import("livekit-server-sdk");
    const { env } = await import("../../config/env.config.js");
    const svc = new RoomServiceClient(env.LIVEKIT_HOST, env.LIVEKIT_API_KEY, env.LIVEKIT_API_SECRET);
    const opts = {
      name: roomName,
      emptyTimeout: emptyTimeout || 300,
      maxParticipants: maxParticipants || 100,
      metadata: metadata ? JSON.stringify(metadata) : undefined,
    };
    const room = await svc.createRoom(opts);
    log.info("Room created", { roomName, tenantId });
    return room;
  }

  async listManagedRooms({ tenantId } = {}) {
    const rooms = await listRooms();
    log.info("Rooms listed", { count: rooms.length, tenantId });
    return rooms;
  }

  async deleteManagedRoom({ roomName, tenantId }) {
    if (!roomName) throw AppError.badRequest("roomName is required");
    await deleteRoom(roomName);
    log.info("Room deleted", { roomName, tenantId });
  }

  async getRoomParticipants({ roomName, tenantId }) {
    if (!roomName) throw AppError.badRequest("roomName is required");
    const participants = await listParticipants(roomName);
    return participants;
  }

  async removeRoomParticipant({ roomName, identity, tenantId }) {
    if (!roomName || !identity) throw AppError.badRequest("roomName and identity are required");
    await removeParticipant(roomName, identity);
    log.info("Participant removed", { roomName, identity, tenantId });
  }
}

export default VideoService;
