// ============================================================================
// TeamSpot — Environment Configuration
// ============================================================================

import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getEnvString(key, defaultValue) {
  const value = process.env[key];
  if (value === undefined) {
    if (defaultValue !== undefined) return defaultValue;
    console.warn(`[Config] Missing environment variable: ${key}`);
    return "";
  }
  return value;
}

function getEnvNumber(key, defaultValue) {
  const value = process.env[key];
  if (value === undefined) {
    if (defaultValue !== undefined) return defaultValue;
    console.warn(`[Config] Missing environment variable: ${key}`);
    return 0;
  }
  const parsed = parseInt(value, 10);
  if (isNaN(parsed)) {
    console.warn(`[Config] Environment variable ${key} must be a number, got: ${value}`);
    return defaultValue || 0;
  }
  return parsed;
}

function getEnvBoolean(key, defaultValue = false) {
  const value = process.env[key];
  if (value === undefined) return defaultValue;
  return value === "true" || value === "1";
}

// ============================================================================
// CONFIGURATION OBJECT
// ============================================================================

export const env = {
  // --------------------------------------------------------------------------
  // App
  // --------------------------------------------------------------------------
  NODE_ENV: getEnvString("NODE_ENV", "development"),
  PORT: getEnvNumber("PORT", 5000),
  HOST: getEnvString("HOST", "0.0.0.0"),
  BASE_URL: getEnvString("BASE_URL", "http://localhost:5000"),
  API_VERSION: getEnvString("API_VERSION", "v1"),

  // --------------------------------------------------------------------------
  // Security
  // --------------------------------------------------------------------------
  FRONTEND_URL: getEnvString("FRONTEND_URL", ""),
  CORS_ORIGINS: process.env.CORS_ORIGINS
    ? process.env.CORS_ORIGINS.split(",").map((s) => s.trim())
    : [],
  TRUST_PROXY: process.env.TRUST_PROXY === "true" || process.env.NODE_ENV === "production",
  DISABLE_HELMET: process.env.DISABLE_HELMET === "true",
  JWT_SECRET: getEnvString("JWT_SECRET", "change-me-in-production"),
  JWT_EXPIRY: getEnvString("JWT_EXPIRY", "7d"),
  ENCRYPTION_KEY: getEnvString("ENCRYPTION_KEY", ""),

  // --------------------------------------------------------------------------
  // MongoDB
  // --------------------------------------------------------------------------
  MONGO_URI: getEnvString("MONGO_URI", "mongodb://localhost:27017/teamspot"),

  // --------------------------------------------------------------------------
  // Firebase Admin SDK
  // --------------------------------------------------------------------------
  FIREBASE_SERVICE_ACCOUNT: getEnvString("FIREBASE_SERVICE_ACCOUNT", ""),

  // --------------------------------------------------------------------------
  // Redis
  // --------------------------------------------------------------------------
  REDIS_URL: getEnvString("REDIS_URL", ""),
  REDIS_HOST: getEnvString("REDIS_HOST", "localhost"),
  REDIS_PORT: getEnvNumber("REDIS_PORT", 6379),
  REDIS_PASSWORD: getEnvString("REDIS_PASSWORD", ""),
  REDIS_DB: getEnvNumber("REDIS_DB", 0),

  // --------------------------------------------------------------------------
  // Kafka
  // --------------------------------------------------------------------------
  KAFKA_BROKERS: getEnvString("KAFKA_BROKERS", "localhost:9092"),
  KAFKA_CLIENT_ID: getEnvString("KAFKA_CLIENT_ID", "teamspot-api"),
  KAFKA_GROUP_ID: getEnvString("KAFKA_GROUP_ID", "teamspot-consumer"),
  KAFKA_SSL: getEnvBoolean("KAFKA_SSL", false),
  KAFKA_SASL_USERNAME: getEnvString("KAFKA_SASL_USERNAME", ""),
  KAFKA_SASL_PASSWORD: getEnvString("KAFKA_SASL_PASSWORD", ""),

  // --------------------------------------------------------------------------
  // RabbitMQ
  // --------------------------------------------------------------------------
  RABBITMQ_URL: getEnvString("RABBITMQ_URL", "amqp://localhost:5672"),

  // --------------------------------------------------------------------------
  // LiveKit (WebRTC SFU)
  // --------------------------------------------------------------------------
  LIVEKIT_API_KEY: getEnvString("LIVEKIT_API_KEY", ""),
  LIVEKIT_API_SECRET: getEnvString("LIVEKIT_API_SECRET", ""),
  LIVEKIT_HOST: getEnvString("LIVEKIT_HOST", ""),

  // --------------------------------------------------------------------------
  // Cloudinary (Media Storage)
  // --------------------------------------------------------------------------
  CLOUDINARY_CLOUD_NAME: getEnvString("CLOUDINARY_CLOUD_NAME", ""),
  CLOUDINARY_API_KEY: getEnvString("CLOUDINARY_API_KEY", ""),
  CLOUDINARY_API_SECRET: getEnvString("CLOUDINARY_API_SECRET", ""),

  // --------------------------------------------------------------------------
  // SMTP / Email
  // --------------------------------------------------------------------------
  SMTP_HOST: getEnvString("SMTP_HOST", ""),
  SMTP_PORT: getEnvNumber("SMTP_PORT", 587),
  SMTP_USER: getEnvString("SMTP_USER", ""),
  SMTP_PASS: getEnvString("SMTP_PASS", ""),
  SMTP_FROM: getEnvString("SMTP_FROM", "noreply@teamspot.app"),
  SMTP_SECURE: getEnvBoolean("SMTP_SECURE", false),

  // --------------------------------------------------------------------------
  // Stripe (Billing)
  // --------------------------------------------------------------------------
  STRIPE_SECRET_KEY: getEnvString("STRIPE_SECRET_KEY", ""),
  STRIPE_WEBHOOK_SECRET: getEnvString("STRIPE_WEBHOOK_SECRET", ""),
  STRIPE_PUBLISHABLE_KEY: getEnvString("STRIPE_PUBLISHABLE_KEY", ""),

  // --------------------------------------------------------------------------
  // AI — LLM Providers
  // --------------------------------------------------------------------------
  OPENAI_API_KEY: getEnvString("OPENAI_API_KEY", ""),
  ANTHROPIC_API_KEY: getEnvString("ANTHROPIC_API_KEY", ""),
  GOOGLE_AI_API_KEY: getEnvString("GOOGLE_AI_API_KEY", ""),
  HUGGINGFACE_API_KEY: getEnvString("HUGGINGFACE_API_KEY", ""),

  // --------------------------------------------------------------------------
  // AI — Embedding Providers
  // --------------------------------------------------------------------------
  COHERE_API_KEY: getEnvString("COHERE_API_KEY", ""),

  // --------------------------------------------------------------------------
  // AI — Internal Service Communication
  // --------------------------------------------------------------------------
  AI_SERVICE_URL: getEnvString("AI_SERVICE_URL", "http://localhost:8000/api/v1"),
  AI_INTERNAL_API_KEY: getEnvString("AI_INTERNAL_API_KEY", ""),

  // --------------------------------------------------------------------------
  // Vector Database (Qdrant or Pinecone)
  // --------------------------------------------------------------------------
  QDRANT_URL: getEnvString("QDRANT_URL", "http://localhost:6333"),
  QDRANT_API_KEY: getEnvString("QDRANT_API_KEY", ""),
  PINECONE_API_KEY: getEnvString("PINECONE_API_KEY", ""),
  PINECONE_INDEX: getEnvString("PINECONE_INDEX", ""),

  // --------------------------------------------------------------------------
  // OpenSearch / Elasticsearch
  // --------------------------------------------------------------------------
  OPENSEARCH_URL: getEnvString("OPENSEARCH_URL", "http://localhost:9200"),
  OPENSEARCH_USERNAME: getEnvString("OPENSEARCH_USERNAME", ""),
  OPENSEARCH_PASSWORD: getEnvString("OPENSEARCH_PASSWORD", ""),

  // --------------------------------------------------------------------------
  // Observability
  // --------------------------------------------------------------------------
  LOG_LEVEL: getEnvString("LOG_LEVEL", "info"),
  SENTRY_DSN: getEnvString("SENTRY_DSN", ""),
  PROMETHEUS_METRICS_ENABLED: getEnvBoolean("PROMETHEUS_METRICS_ENABLED", true),
  OTEL_EXPORTER_OTLP_ENDPOINT: getEnvString("OTEL_EXPORTER_OTLP_ENDPOINT", ""),
};

// ============================================================================
// ENVIRONMENT CHECKS
// ============================================================================

export function isProduction() {
  return env.NODE_ENV === "production";
}

export function isDevelopment() {
  return env.NODE_ENV === "development";
}

export function isTest() {
  return env.NODE_ENV === "test";
}

export function validateEnv() {
  const required = ["MONGO_URI", "JWT_SECRET", "FIREBASE_SERVICE_ACCOUNT"];
  const recommended = [
    "REDIS_URL",
    "KAFKA_BROKERS",
    "RABBITMQ_URL",
    "LIVEKIT_API_KEY",
    "LIVEKIT_API_SECRET",
    "CLOUDINARY_CLOUD_NAME",
    "STRIPE_SECRET_KEY",
    "OPENAI_API_KEY",
    "SENTRY_DSN",
    "ENCRYPTION_KEY",
  ];

  const missing = required.filter((key) => !process.env[key]);
  const missingRecommended = recommended.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error(`[Config] Missing REQUIRED env vars: ${missing.join(", ")}`);
  }

  if (missingRecommended.length > 0 && env.NODE_ENV === "production") {
    console.warn(`[Config] Missing recommended env vars: ${missingRecommended.join(", ")}`);
  }

  return { valid: missing.length === 0, missing };
}

export default env;
