// ============================================================================
// TeamSpot — Video Controller
// LiveKit room and token HTTP handlers
// ============================================================================

import { VideoService } from "./video.service.js";
import { success, created } from "../../core/utils/api-response.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const videoService = new VideoService();

// POST /communication/rooms/token
export const generateRoomToken = asyncHandler(async (req, res) => {
  const { roomName, identity, displayName, permissions } = req.body;
  const result = await videoService.generateRoomToken({
    roomName,
    identity: identity || req.user.uid,
    displayName: displayName || req.user.displayName,
    tenantId: req.tenant?.tenantId,
    permissions,
  });
  return success(res, result, "Room token generated");
});

// POST /communication/rooms
export const createRoom = asyncHandler(async (req, res) => {
  const { roomName, maxParticipants, emptyTimeout, metadata } = req.body;
  const room = await videoService.createManagedRoom({
    roomName,
    maxParticipants,
    emptyTimeout,
    metadata,
    tenantId: req.tenant?.tenantId,
  });
  return created(res, room, "Room created");
});

// GET /communication/rooms
export const getRooms = asyncHandler(async (req, res) => {
  const rooms = await videoService.listManagedRooms({ tenantId: req.tenant?.tenantId });
  return success(res, rooms);
});

// DELETE /communication/rooms/:name
export const removeRoom = asyncHandler(async (req, res) => {
  await videoService.deleteManagedRoom({
    roomName: req.params.name,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, null, "Room deleted");
});

// GET /communication/rooms/:name/participants
export const getParticipants = asyncHandler(async (req, res) => {
  const participants = await videoService.getRoomParticipants({
    roomName: req.params.name,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, participants);
});

// POST /communication/rooms/:name/remove-participant
export const kickParticipant = asyncHandler(async (req, res) => {
  const { identity } = req.body;
  await videoService.removeRoomParticipant({
    roomName: req.params.name,
    identity,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, null, "Participant removed");
});
