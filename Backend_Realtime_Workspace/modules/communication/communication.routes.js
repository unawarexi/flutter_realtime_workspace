// ============================================================================
// TeamSpot — Communication Routes
// LiveKit video/voice + VoIP calls + direct messages
// ============================================================================

import express from "express";
import { firebaseAuthMiddleware } from "../../core/auth/firebase-auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { generateRoomToken, createRoom, getRooms, removeRoom, getParticipants, kickParticipant } from "./video.controller.js";
import { initiateCall, acceptCall, endCall, rejectCall, getCallHistory } from "./voip-call.controller.js";
import { sendMessage, getMessages, deleteMessage, searchMessages } from "./chat.controller.js";

const router = express.Router();
router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// --------------------------------------------------------------------------
// Video rooms (LiveKit)
// --------------------------------------------------------------------------
router.post("/rooms/token", generateRoomToken);
router.post("/rooms", createRoom);
router.get("/rooms", getRooms);
router.delete("/rooms/:name", removeRoom);
router.get("/rooms/:name/participants", getParticipants);
router.post("/rooms/:name/remove-participant", kickParticipant);

// --------------------------------------------------------------------------
// VoIP calls (Redis state machine + LiveKit audio room)
// --------------------------------------------------------------------------
router.post("/calls/initiate", initiateCall);
router.put("/calls/:id/accept", acceptCall);
router.put("/calls/:id/end", endCall);
router.put("/calls/:id/reject", rejectCall);
router.get("/calls/history", getCallHistory);

// --------------------------------------------------------------------------
// Direct messages
// --------------------------------------------------------------------------
router.post("/messages", sendMessage);
router.get("/messages", getMessages);
router.get("/messages/search", searchMessages);
router.delete("/messages/:id", deleteMessage);

export default router;
