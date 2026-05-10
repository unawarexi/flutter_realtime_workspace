// ============================================================================
// TeamSpot — WebSocket Service
// Socket.IO with Redis adapter for real-time communication
// ============================================================================

import { Server } from "socket.io";
import { createAdapter } from "@socket.io/redis-adapter";
import { getRedisClient, getRedisSubscriber } from "../redis/redis.service.js";
import { SocketEvents } from "../../config/constants.js";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("WebSocket");

let io = null;

export function initWebSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGINS.length > 0
        ? [env.FRONTEND_URL, ...env.CORS_ORIGINS].filter(Boolean)
        : "*",
      methods: ["GET", "POST"],
      credentials: true,
    },
    pingTimeout: 30000,
    pingInterval: 25000,
    transports: ["websocket", "polling"],
    maxHttpBufferSize: 1e6,
  });

  // Attach Redis adapter for horizontal scaling
  try {
    const pubClient = getRedisClient();
    const subClient = getRedisSubscriber();
    io.adapter(createAdapter(pubClient, subClient));
    log.info("Socket.IO Redis adapter attached");
  } catch (err) {
    log.warn("Socket.IO running without Redis adapter (single-instance mode)", { error: err });
  }

  io.on(SocketEvents.CONNECTION, (socket) => {
    log.debug("Client connected", { socketId: socket.id });

    // Auth registration
    socket.on(SocketEvents.AUTH_REGISTER, (userId) => {
      if (userId) {
        socket.join(`user:${userId}`);
        socket.data.userId = userId;
        log.debug("User registered", { socketId: socket.id, userId });
      }
    });

    // Meeting rooms
    socket.on(SocketEvents.JOIN_ROOM, ({ meetingId, userId }) => {
      socket.join(`meeting:${meetingId}`);
      socket.data.meetingId = meetingId;
      socket.to(`meeting:${meetingId}`).emit(SocketEvents.MEETING_PARTICIPANT_JOINED, { userId, socketId: socket.id });
    });

    socket.on(SocketEvents.LEAVE_ROOM, ({ meetingId, userId }) => {
      socket.leave(`meeting:${meetingId}`);
      socket.to(`meeting:${meetingId}`).emit(SocketEvents.MEETING_PARTICIPANT_LEFT, { userId, socketId: socket.id });
    });

    // Chat
    socket.on(SocketEvents.CHANNEL_MESSAGE, (data) => {
      const { meetingId, channelId, ...message } = data;
      const room = channelId ? `channel:${channelId}` : `meeting:${meetingId}`;
      socket.to(room).emit(SocketEvents.CHANNEL_MESSAGE, message);
    });

    socket.on(SocketEvents.CHANNEL_TYPING, ({ meetingId, channelId, userId }) => {
      const room = channelId ? `channel:${channelId}` : `meeting:${meetingId}`;
      socket.to(room).emit(SocketEvents.CHANNEL_TYPING, { userId });
    });

    // Participant media state events
    const mediaEvents = [
      SocketEvents.PARTICIPANT_MUTED, SocketEvents.PARTICIPANT_UNMUTED,
      SocketEvents.PARTICIPANT_VIDEO_ON, SocketEvents.PARTICIPANT_VIDEO_OFF,
      SocketEvents.PARTICIPANT_SCREEN_SHARE_ON, SocketEvents.PARTICIPANT_SCREEN_SHARE_OFF,
      SocketEvents.PARTICIPANT_HAND_RAISED, SocketEvents.PARTICIPANT_HAND_LOWERED,
    ];
    for (const event of mediaEvents) {
      socket.on(event, (data) => {
        socket.to(`meeting:${data.meetingId}`).emit(event, data);
      });
    }

    // Disconnect
    socket.on(SocketEvents.DISCONNECT, (reason) => {
      const { meetingId, userId } = socket.data;
      if (meetingId && userId) {
        socket.to(`meeting:${meetingId}`).emit(SocketEvents.MEETING_PARTICIPANT_LEFT, { userId, socketId: socket.id, reason });
      }
      log.debug("Client disconnected", { socketId: socket.id, reason });
    });
  });

  log.success("WebSocket server initialized");
  return io;
}

// Emitters
export function emitToMeeting(meetingId, event, data) {
  if (io) io.to(`meeting:${meetingId}`).emit(event, data);
}

export function emitToUser(userId, event, data) {
  if (io) io.to(`user:${userId}`).emit(event, data);
}

export function emitToChannel(channelId, event, data) {
  if (io) io.to(`channel:${channelId}`).emit(event, data);
}

export function emitToWorkspace(workspaceId, event, data) {
  if (io) io.to(`workspace:${workspaceId}`).emit(event, data);
}

export function getIO() {
  if (!io) throw new Error("WebSocket not initialized");
  return io;
}

export function getConnectedCount() {
  return io ? io.engine.clientsCount : 0;
}

export async function disconnectWebSocket() {
  if (io) { io.close(); log.info("WebSocket server closed"); }
}

export default {
  initWebSocket, emitToMeeting, emitToUser, emitToChannel,
  emitToWorkspace, getIO, getConnectedCount, disconnectWebSocket,
};
