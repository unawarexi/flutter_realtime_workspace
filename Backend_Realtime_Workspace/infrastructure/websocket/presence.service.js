// ============================================================================
// TeamSpot — Presence Service
// Online/offline tracking, typing indicators, active viewers via Redis
// ============================================================================

import { getRedisClient } from "../redis/redis.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("Presence");

const PRESENCE_TTL = 120; // 2 minutes
const TYPING_TTL = 5;    // 5 seconds

export async function setOnline(userId, metadata = {}) {
  const redis = getRedisClient();
  await redis.set(`presence:${userId}`, JSON.stringify({
    status: "online",
    lastSeen: Date.now(),
    ...metadata,
  }), "EX", PRESENCE_TTL);
}

export async function setOffline(userId) {
  const redis = getRedisClient();
  await redis.set(`presence:${userId}`, JSON.stringify({
    status: "offline",
    lastSeen: Date.now(),
  }), "EX", 86400); // Keep offline status for 24h
}

export async function getPresence(userId) {
  const redis = getRedisClient();
  const data = await redis.get(`presence:${userId}`);
  return data ? JSON.parse(data) : { status: "offline", lastSeen: null };
}

export async function getBulkPresence(userIds) {
  const redis = getRedisClient();
  const pipeline = redis.pipeline();
  for (const uid of userIds) pipeline.get(`presence:${uid}`);
  const results = await pipeline.exec();

  const presenceMap = {};
  userIds.forEach((uid, i) => {
    const [err, data] = results[i];
    presenceMap[uid] = data ? JSON.parse(data) : { status: "offline", lastSeen: null };
  });
  return presenceMap;
}

export async function setTyping(channelId, userId) {
  const redis = getRedisClient();
  await redis.set(`typing:${channelId}:${userId}`, "1", "EX", TYPING_TTL);
}

export async function getTypingUsers(channelId) {
  const redis = getRedisClient();
  const keys = await redis.keys(`typing:${channelId}:*`);
  return keys.map((k) => k.split(":").pop());
}

export async function addActiveViewer(resourceId, userId) {
  const redis = getRedisClient();
  await redis.sadd(`viewers:${resourceId}`, userId);
  await redis.expire(`viewers:${resourceId}`, 300);
}

export async function removeActiveViewer(resourceId, userId) {
  const redis = getRedisClient();
  await redis.srem(`viewers:${resourceId}`, userId);
}

export async function getActiveViewers(resourceId) {
  const redis = getRedisClient();
  return redis.smembers(`viewers:${resourceId}`);
}

export async function heartbeat(userId) {
  const redis = getRedisClient();
  await redis.expire(`presence:${userId}`, PRESENCE_TTL);
}

export default {
  setOnline, setOffline, getPresence, getBulkPresence,
  setTyping, getTypingUsers, addActiveViewer, removeActiveViewer,
  getActiveViewers, heartbeat,
};
