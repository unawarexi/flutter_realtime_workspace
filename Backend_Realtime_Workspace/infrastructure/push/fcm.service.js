// ============================================================================
// TeamSpot — Firebase Cloud Messaging (FCM) Service
// Push notification delivery via Firebase Admin SDK
// ============================================================================

import admin from "firebase-admin";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("FCM");

export async function sendPushNotification({ token, title, body, data = {}, imageUrl }) {
  const message = {
    token,
    notification: { title, body, ...(imageUrl && { imageUrl }) },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    android: { priority: "high", notification: { channelId: "teamspot_default" } },
    apns: { payload: { aps: { badge: 1, sound: "default" } } },
  };

  const result = await admin.messaging().send(message);
  log.debug("Push sent", { token: token.slice(0, 10), messageId: result });
  return result;
}

export async function sendMulticast({ tokens, title, body, data = {} }) {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0 };

  const message = {
    tokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
  };

  const result = await admin.messaging().sendEachForMulticast(message);
  log.info("Multicast sent", { success: result.successCount, failure: result.failureCount });
  return result;
}

export async function sendToTopic({ topic, title, body, data = {} }) {
  const message = {
    topic,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
  };

  const result = await admin.messaging().send(message);
  log.info("Topic notification sent", { topic, messageId: result });
  return result;
}

export async function subscribeToTopic(tokens, topic) {
  return admin.messaging().subscribeToTopic(tokens, topic);
}

export async function unsubscribeFromTopic(tokens, topic) {
  return admin.messaging().unsubscribeFromTopic(tokens, topic);
}

export async function validateToken(token) {
  try {
    await admin.messaging().send({ token, data: { test: "true" } }, true);
    return true;
  } catch {
    return false;
  }
}

export default {
  sendPushNotification, sendMulticast, sendToTopic,
  subscribeToTopic, unsubscribeFromTopic, validateToken,
};
