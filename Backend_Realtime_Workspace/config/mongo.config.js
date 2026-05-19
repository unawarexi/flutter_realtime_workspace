// ============================================================================
// TeamSpot — MongoDB Configuration
// Mongoose connection with pooling, replica set support, and health checks
// ============================================================================

import mongoose from "mongoose";
import { env } from "./env.config.js";
import { createLogger } from "../observability/logger.js";


// The local network DNS server often fails to resolve TXT records for
// mongodb+srv:// URIs (queryTxt ETIMEOUT). Force Google public DNS so that
// both SRV and TXT lookups succeed regardless of the local resolver.
// dns.setServers(["8.8.8.8", "8.8.4.4", "1.1.1.1"]);

const log = createLogger("MongoDB");

let isConnected = false;

// ============================================================================
// CONNECTION
// ============================================================================

export async function connectDB() {
  if (isConnected) return mongoose.connection;

  const options = {
    maxPoolSize: env.MONGO_POOL_SIZE,
    minPoolSize: 2,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    family: 4, // Use IPv4
    autoIndex: env.NODE_ENV !== "production", // Disable auto-indexing in prod
  };

  try {
    await mongoose.connect(env.MONGO_URI, options);
    isConnected = true;

    mongoose.connection.on("error", (err) => {
      log.error("MongoDB connection error", { error: err });
      isConnected = false;
    });

    mongoose.connection.on("disconnected", () => {
      log.warn("MongoDB disconnected");
      isConnected = false;
    });

    mongoose.connection.on("reconnected", () => {
      log.info("MongoDB reconnected");
      isConnected = true;
    });

    log.info("MongoDB connected", {
      host: mongoose.connection.host,
      db: mongoose.connection.name,
      poolSize: env.MONGO_POOL_SIZE,
    });

    return mongoose.connection;
  } catch (error) {
    log.error("MongoDB connection failed", { error });
    throw error;
  }
}

// ============================================================================
// HEALTH CHECK
// ============================================================================

export async function healthCheck() {
  try {
    const adminDb = mongoose.connection.db.admin();
    const result = await adminDb.ping();
    const serverStatus = await adminDb.serverStatus();

    return {
      connected: isConnected,
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host,
      name: mongoose.connection.name,
      latencyMs: result?.ok === 1 ? 0 : -1,
      connections: {
        current: serverStatus.connections?.current || 0,
        available: serverStatus.connections?.available || 0,
      },
    };
  } catch {
    return { connected: false, readyState: mongoose.connection.readyState };
  }
}

// ============================================================================
// DISCONNECT
// ============================================================================

export async function disconnectDB() {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
    isConnected = false;
    log.info("MongoDB disconnected gracefully");
  }
}

export function getIsConnected() {
  return isConnected;
}

export default { connectDB, disconnectDB, healthCheck, getIsConnected };
