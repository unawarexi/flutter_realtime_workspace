// ============================================================================
// TeamSpot — Kafka Topic Registry
// All topic names with partition and retention configuration
// ============================================================================

import { KafkaTopics } from "../../config/constants.js";

/**
 * Topic configuration for production deployment.
 * Use this when creating topics with kafka-admin.
 */
export const TopicConfig = Object.entries(KafkaTopics).map(([key, topic]) => {
  // High-throughput topics get more partitions
  const highThroughput = ["CHAT_MESSAGES", "ANALYTICS_EVENTS", "AUDIT_EVENTS", "ACTIVITY_FEED"];
  const numPartitions = highThroughput.includes(key) ? 6 : 3;

  // Audit/compliance topics get longer retention
  const longRetention = ["AUDIT_EVENTS", "NOTIFICATION_EVENTS"];
  const retentionMs = longRetention.includes(key)
    ? 30 * 24 * 60 * 60 * 1000 // 30 days
    : 7 * 24 * 60 * 60 * 1000;  // 7 days

  return {
    topic,
    numPartitions,
    replicationFactor: 1,
    configEntries: [
      { name: "retention.ms", value: retentionMs.toString() },
      { name: "cleanup.policy", value: "delete" },
    ],
  };
});

export default TopicConfig;
