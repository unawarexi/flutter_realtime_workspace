// ============================================================================
// TeamSpot — AI Kafka Consumer
// Consumes AI result events and broadcasts via WebSocket to relevant users
// ============================================================================

import { Kafka, logLevel } from "kafkajs";
import { env } from "../../config/env.config.js";
import { KafkaTopics, SocketEvents } from "../../config/constants.js";
import { emitToUser, emitToWorkspace, emitToChannel } from "../../infrastructure/websocket/websocket.service.js";
import { createLogger } from "../../observability/logger.js";
import { retryWithBackoff } from "../../core/utils/retry.js";

const log = createLogger("AI-Consumer");

let consumer = null;

// ============================================================================
// HANDLER MAP
// Each AI result event type is routed to the appropriate WebSocket event
// and delivery scope (user / workspace / channel).
// ============================================================================

async function handleAIResult(payload) {
  const { type, userId, workspaceId, channelId, workflowId, ...data } = payload;

  switch (type) {
    case "task_progress":
      if (userId) {
        emitToUser(userId, SocketEvents.AI_TASK_PROGRESS, { workflowId, ...data });
      }
      break;

    case "workflow_status":
      if (userId) {
        emitToUser(userId, SocketEvents.AI_WORKFLOW_STATUS, { workflowId, ...data });
      }
      break;

    case "tool_result":
      if (userId) {
        emitToUser(userId, SocketEvents.AI_TOOL_RESULT, { workflowId, ...data });
      }
      break;

    case "typing":
      if (channelId) {
        emitToChannel(channelId, SocketEvents.AI_TYPING, { channelId, ...data });
      } else if (userId) {
        emitToUser(userId, SocketEvents.AI_TYPING, data);
      }
      break;

    default:
      log.debug("Unhandled AI result type", { type, workflowId });
  }
}

// ============================================================================
// INITIALIZATION
// ============================================================================

export async function initAIConsumer() {
  const brokers = env.KAFKA_BROKERS.split(",").map((b) => b.trim());

  const config = {
    clientId: `${env.KAFKA_CLIENT_ID}-ai-consumer`,
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

  const kafka = new Kafka(config);
  consumer = kafka.consumer({
    groupId: `${env.KAFKA_GROUP_ID}-ai-relay`,
    retry: { initialRetryTime: 500, retries: 15 },
  });

  await retryWithBackoff(() => consumer.connect(), { label: "AI consumer connect" });

  // Subscribe to AI result topic
  await consumer.subscribe({ topic: KafkaTopics.AI_RESULTS, fromBeginning: false });
  // Also subscribe to general analytics for AI-triggered events
  await consumer.subscribe({ topic: KafkaTopics.AI_TASKS, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const value = JSON.parse(message.value.toString());
        await handleAIResult(value);
      } catch (err) {
        log.error("AI message processing error", { error: err.message, topic });
      }
    },
  });

  log.success("AI Kafka consumer started", {
    topics: [KafkaTopics.AI_RESULTS, KafkaTopics.AI_TASKS],
  });
}

// ============================================================================
// DISCONNECT
// ============================================================================

export async function disconnectAIConsumer() {
  if (consumer) {
    await consumer.disconnect();
    log.info("AI Kafka consumer disconnected");
  }
}

export default { initAIConsumer, disconnectAIConsumer };
