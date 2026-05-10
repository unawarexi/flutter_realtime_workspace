// ============================================================================
// TeamSpot — LiveKit Service
// Video/voice token generation, room management
// ============================================================================

import { AccessToken, RoomServiceClient } from "livekit-server-sdk";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("LiveKit");

let roomService = null;

export function initLiveKit() {
  if (!env.LIVEKIT_HOST || !env.LIVEKIT_API_KEY) {
    log.warn("LiveKit not configured — video/voice features disabled");
    return;
  }
  roomService = new RoomServiceClient(env.LIVEKIT_HOST, env.LIVEKIT_API_KEY, env.LIVEKIT_API_SECRET);
  log.success("LiveKit initialized", { host: env.LIVEKIT_HOST });
}

export async function generateToken(roomName, participantIdentity, options = {}) {
  const token = new AccessToken(env.LIVEKIT_API_KEY, env.LIVEKIT_API_SECRET, {
    identity: participantIdentity,
    ttl: options.ttl || "6h",
    name: options.displayName || participantIdentity,
  });

  token.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: options.canPublish ?? true,
    canSubscribe: options.canSubscribe ?? true,
    canPublishData: options.canPublishData ?? true,
  });

  return await token.toJwt();
}

export async function listRooms() {
  if (!roomService) return [];
  return roomService.listRooms();
}

export async function deleteRoom(roomName) {
  if (!roomService) return;
  await roomService.deleteRoom(roomName);
}

export async function removeParticipant(roomName, identity) {
  if (!roomService) return;
  await roomService.removeParticipant(roomName, identity);
}

export async function listParticipants(roomName) {
  if (!roomService) return [];
  return roomService.listParticipants(roomName);
}

export default {
  initLiveKit, generateToken, listRooms, deleteRoom,
  removeParticipant, listParticipants,
};
