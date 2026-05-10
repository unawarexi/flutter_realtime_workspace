// ============================================================================
// TeamSpot — RabbitMQ Service
// Task queue producer/consumer for delayed jobs and retries
// ============================================================================

import amqplib from "amqplib";
import { env } from "../../config/env.config.js";
import { QueueNames } from "../../config/constants.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("RabbitMQ");

let connection = null;
let channel = null;
let isConnected = false;

export async function initRabbitMQ() {
  if (connection) return channel;

  connection = await amqplib.connect(env.RABBITMQ_URL);
  channel = await connection.createChannel();
  await channel.prefetch(10);

  // Assert all queues with dead-letter exchange
  const dlx = "teamspot.dlx";
  await channel.assertExchange(dlx, "direct", { durable: true });
  await channel.assertQueue("teamspot.dead-letter", { durable: true });
  await channel.bindQueue("teamspot.dead-letter", dlx, "");

  for (const queueName of Object.values(QueueNames)) {
    await channel.assertQueue(queueName, {
      durable: true,
      arguments: {
        "x-dead-letter-exchange": dlx,
        "x-dead-letter-routing-key": "",
      },
    });
  }

  connection.on("close", () => { isConnected = false; log.warn("RabbitMQ connection closed"); });
  connection.on("error", (err) => { log.error("RabbitMQ error", { error: err }); });

  isConnected = true;
  log.success("RabbitMQ initialized", { queues: Object.keys(QueueNames).length });
  return channel;
}

export async function publishToQueue(queueName, payload, options = {}) {
  if (!channel) throw new Error("RabbitMQ not initialized");

  const message = Buffer.from(JSON.stringify({
    id: crypto.randomUUID(),
    timestamp: Date.now(),
    data: payload,
  }));

  channel.sendToQueue(queueName, message, {
    persistent: true,
    ...options,
  });
}

export async function publishDelayed(queueName, payload, delayMs) {
  if (!channel) throw new Error("RabbitMQ not initialized");

  const delayedQueue = `${queueName}.delayed.${delayMs}`;
  await channel.assertQueue(delayedQueue, {
    durable: true,
    arguments: {
      "x-dead-letter-exchange": "",
      "x-dead-letter-routing-key": queueName,
      "x-message-ttl": delayMs,
    },
  });

  const message = Buffer.from(JSON.stringify({
    id: crypto.randomUUID(),
    timestamp: Date.now(),
    data: payload,
  }));

  channel.sendToQueue(delayedQueue, message, { persistent: true });
}

export function consumeQueue(queueName, handler) {
  if (!channel) throw new Error("RabbitMQ not initialized");

  channel.consume(queueName, async (msg) => {
    if (!msg) return;

    try {
      const payload = JSON.parse(msg.content.toString());
      await handler(payload);
      channel.ack(msg);
    } catch (err) {
      log.error(`Queue processing error: ${queueName}`, { error: err });
      channel.nack(msg, false, false); // Send to DLQ
    }
  });
}

export async function healthCheck() {
  return { connected: isConnected };
}

export async function disconnectRabbitMQ() {
  if (channel) await channel.close();
  if (connection) await connection.close();
  isConnected = false;
  log.info("RabbitMQ disconnected");
}

export default {
  initRabbitMQ, publishToQueue, publishDelayed, consumeQueue,
  healthCheck, disconnectRabbitMQ,
};
