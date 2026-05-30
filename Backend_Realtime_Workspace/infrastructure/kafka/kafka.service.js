// ============================================================================
// TeamSpot — Kafka Service
// Producer/consumer with topic management and health checks
// ============================================================================

import { Kafka, logLevel } from "kafkajs";
import { env } from "../../config/env.config.js";
import { KafkaTopics } from "../../config/constants.js";
import { createLogger } from "../../observability/logger.js";
import { retryWithBackoff } from "../../core/utils/retry.js";
import { getRedisClient } from "../redis/redis.service.js";

const log = createLogger("Kafka");

let kafka = null;
let producer = null;
let consumer = null;
let isConnected = false;

export async function initKafka() {
  const brokers = env.KAFKA_BROKERS.split(",").map((b) => b.trim());

  const config = {
    clientId: env.KAFKA_CLIENT_ID,
    brokers,
    logLevel: logLevel.WARN,
    retry: { initialRetryTime: 300, retries: 10 },
  };

  if (env.KAFKA_SSL) config.ssl = true;
  if (env.KAFKA_SASL_USERNAME && env.KAFKA_SASL_PASSWORD) {
    config.sasl = {
      mechanism: "plain",
      username: env.KAFKA_SASL_USERNAME,
      password: env.KAFKA_SASL_PASSWORD,
    };
  }

  kafka = new Kafka(config);
  producer = kafka.producer();
  consumer = kafka.consumer({ groupId: env.KAFKA_GROUP_ID });

  await retryWithBackoff(() => producer.connect(), {
    label: "Kafka producer connect",
    maxRetries: 5,
    baseDelay: 1000,
  });
  isConnected = true;
  log.success("Kafka producer connected", { brokers, clientId: env.KAFKA_CLIENT_ID });
  return { kafka, producer, consumer };
}

const LEADER_ELECTION_ERROR = "There is no leader for this topic-partition as we are in the middle of a leadership election";
const MAX_LEADER_RETRIES = 5;
const LEADER_RETRY_DELAY_MS = 1500;

async function _sendWithLeaderRetry(payload) {
  for (let attempt = 1; attempt <= MAX_LEADER_RETRIES; attempt++) {
    try {
      await producer.send(payload);
      return;
    } catch (err) {
      const isLeaderElection =
        err.message?.includes("leadership election") ||
        err.message?.includes("LEADER_NOT_AVAILABLE") ||
        err.type === "LEADER_NOT_AVAILABLE";
      if (isLeaderElection && attempt < MAX_LEADER_RETRIES) {
        log.warn("Kafka leader election in progress, retrying...", {
          attempt,
          topic: payload.topic,
          retryInMs: LEADER_RETRY_DELAY_MS,
        });
        await new Promise((r) => setTimeout(r, LEADER_RETRY_DELAY_MS));
      } else {
        throw err;
      }
    }
  }
}

export async function publishEvent(topic, key, value, headers = {}) {
  if (!producer) throw new Error("Kafka producer not initialized");
  const message = {
    topic,
    messages: [{
      key: typeof key === "string" ? key : JSON.stringify(key),
      value: typeof value === "string" ? value : JSON.stringify(value),
      headers,
      timestamp: Date.now().toString(),
    }],
  };
  await _sendWithLeaderRetry(message);
}

export async function publishBatch(topic, messages) {
  if (!producer) throw new Error("Kafka producer not initialized");
  const payload = {
    topic,
    messages: messages.map((msg) => ({
      key: typeof msg.key === "string" ? msg.key : JSON.stringify(msg.key),
      value: typeof msg.value === "string" ? msg.value : JSON.stringify(msg.value),
      headers: msg.headers || {},
      timestamp: Date.now().toString(),
    })),
  };
  await _sendWithLeaderRetry(payload);
}

export async function subscribeToTopics(topics, handler) {
  if (!consumer) throw new Error("Kafka consumer not initialized");
  for (const topic of topics) {
    await consumer.subscribe({ topic, fromBeginning: false });
  }
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const key = message.key?.toString();
        const value = JSON.parse(message.value.toString());

        // ── Idempotency guard (Redis setnx, 24h TTL) ──────────────────────
        // Kafka guarantees at-least-once delivery. The eventId field (a ULID
        // set by publishEvent callers via event-contracts) lets us deduplicate
        // redeliveries without processing the same event twice.
        const eventId = value?.eventId || value?.id;
        if (eventId) {
          const redis = getRedisClient();
          if (redis) {
            const idempotencyKey = `idempotency:kafka:${topic}:${eventId}`;
            const isNew = await redis.set(idempotencyKey, "1", "EX", 86400, "NX");
            if (!isNew) {
              log.info("Duplicate Kafka event skipped", { topic, eventId });
              return;
            }
          }
        }

        await handler({ topic, partition, key, value, timestamp: message.timestamp, headers: message.headers });
      } catch (err) {
        log.error("Kafka message processing error", { error: err, topic });
      }
    },
  });
  log.info("Kafka consumer subscribed", { topics });
}

export async function createTopics() {
  if (!kafka) throw new Error("Kafka not initialized");
  const admin = kafka.admin();
  await admin.connect();
  const topics = Object.values(KafkaTopics).map((topic) => ({
    topic, numPartitions: 3, replicationFactor: 1,
  }));
  await admin.createTopics({ topics, waitForLeaders: true });
  await admin.disconnect();
  log.info("Kafka topics created", { count: topics.length });
}

export async function healthCheck() {
  if (!kafka) return { connected: false };
  const admin = kafka.admin();
  await admin.connect();
  const topics = await admin.listTopics();
  const cluster = await admin.describeCluster();
  await admin.disconnect();
  return { connected: isConnected, brokers: cluster.brokers.length, topics };
}

export function getKafkaInstance() {
  if (!kafka) throw new Error("Kafka not initialized. Call initKafka() first.");
  return kafka;
}

export async function disconnectKafka() {
  if (producer) await producer.disconnect();
  if (consumer) await consumer.disconnect();
  isConnected = false;
  log.info("Kafka disconnected");
}

export default {
  initKafka, getKafkaInstance, publishEvent, publishBatch, subscribeToTopics,
  createTopics, healthCheck, disconnectKafka,
};