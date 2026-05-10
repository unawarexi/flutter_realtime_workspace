// ============================================================================
// TeamSpot — VoIP Call Service
// Redis-backed call state machine: initiating -> ringing -> active -> ended/rejected
// ============================================================================

import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { generateToken } from "../../infrastructure/livekit/livekit.service.js";
import { AppError } from "../../core/errors/app-error.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("VoipCallService");
const CALL_TTL = 3600; // 1 hour max call duration
const CALL_PREFIX = "call:";

export class VoipCallService {
  #redis() { return getRedisClient(); }

  #callKey(callId) { return `${CALL_PREFIX}${callId}`; }

  async initiateCall({ callerId, calleeId, type = "audio", tenantId }) {
    if (!callerId || !calleeId) throw AppError.badRequest("callerId and calleeId are required");
    const callId = `${tenantId}-${callerId}-${Date.now()}`;
    const roomName = `call-${callId}`;
    const call = {
      callId,
      roomName,
      callerId,
      calleeId,
      type,
      tenantId,
      status: "initiating",
      startedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    const redis = this.#redis();
    await redis.hset(this.#callKey(callId), call);
    await redis.expire(this.#callKey(callId), CALL_TTL);
    // Generate caller token
    const callerToken = await generateToken(roomName, callerId, { name: callerId });
    log.info("Call initiated", { callId, callerId, calleeId, tenantId });
    return { ...call, callerToken };
  }

  async acceptCall({ callId, calleeId, tenantId }) {
    const redis = this.#redis();
    const call = await redis.hgetall(this.#callKey(callId));
    if (!call || !call.callId) throw AppError.notFound("Call");
    if (call.calleeId !== calleeId) throw AppError.forbidden("Not authorized to accept this call");
    if (call.status !== "initiating" && call.status !== "ringing") {
      throw AppError.conflict("Call cannot be accepted in current state");
    }
    await redis.hset(this.#callKey(callId), { status: "active", updatedAt: new Date().toISOString() });
    const calleeToken = await generateToken(call.roomName, calleeId, { name: calleeId });
    log.info("Call accepted", { callId, calleeId });
    return { callId, roomName: call.roomName, calleeToken, status: "active" };
  }

  async endCall({ callId, userId, tenantId }) {
    const redis = this.#redis();
    const call = await redis.hgetall(this.#callKey(callId));
    if (!call || !call.callId) throw AppError.notFound("Call");
    if (call.callerId !== userId && call.calleeId !== userId) {
      throw AppError.forbidden("Not authorized to end this call");
    }
    const endedAt = new Date().toISOString();
    await redis.hset(this.#callKey(callId), { status: "ended", endedAt, updatedAt: endedAt });
    await redis.expire(this.#callKey(callId), 300); // keep for 5min for history
    log.info("Call ended", { callId, userId });
    return { callId, status: "ended", endedAt };
  }

  async rejectCall({ callId, calleeId, tenantId }) {
    const redis = this.#redis();
    const call = await redis.hgetall(this.#callKey(callId));
    if (!call || !call.callId) throw AppError.notFound("Call");
    if (call.calleeId !== calleeId) throw AppError.forbidden("Not authorized to reject this call");
    await redis.hset(this.#callKey(callId), { status: "rejected", updatedAt: new Date().toISOString() });
    await redis.expire(this.#callKey(callId), 300);
    log.info("Call rejected", { callId, calleeId });
    return { callId, status: "rejected" };
  }

  async getCallHistory({ userId, tenantId, page = 1, limit = 20 }) {
    // Simple scan-based history — in production, persist call records to MongoDB
    const redis = this.#redis();
    const keys = await redis.keys(`${CALL_PREFIX}*`);
    const calls = [];
    for (const key of keys) {
      const call = await redis.hgetall(key);
      if (call && (call.callerId === userId || call.calleeId === userId) && call.tenantId === tenantId) {
        calls.push(call);
      }
    }
    calls.sort((a, b) => new Date(b.startedAt) - new Date(a.startedAt));
    const start = (page - 1) * limit;
    return calls.slice(start, start + limit);
  }
}

export default VoipCallService;
