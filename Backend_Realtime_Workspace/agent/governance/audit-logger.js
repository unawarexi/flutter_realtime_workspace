// ============================================================================
// TeamSpot — AI Audit Logger
// Tracks all AI agent actions for compliance and traceability
// ============================================================================

import { createLogger } from "../../observability/logger.js";
const log = createLogger("AIAudit");

const auditBuffer = [];
const MAX_BUFFER = 1000;

export class AIAuditLogger {
  static log(entry) {
    const record = {
      timestamp: new Date().toISOString(),
      eventId: `ai_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      ...entry,
    };
    auditBuffer.push(record);
    if (auditBuffer.length > MAX_BUFFER) auditBuffer.shift();
    log.debug("AI audit entry", { eventId: record.eventId, action: record.action });
    return record;
  }

  static logQuery({ userId, tenantId, query, toolsUsed, responseLength }) {
    return this.log({ action: "agent_query", userId, tenantId, query: query?.slice(0, 200), toolsUsed, responseLength });
  }

  static logToolExecution({ userId, tenantId, tool, args, result, duration }) {
    return this.log({ action: "tool_execution", userId, tenantId, tool, args, resultSummary: typeof result === "string" ? result.slice(0, 200) : "object", duration });
  }

  static logGuardBlock({ userId, reason, input }) {
    return this.log({ action: "guard_block", userId, reason, inputPreview: input?.slice(0, 100) });
  }

  static getRecent(limit = 50) {
    return auditBuffer.slice(-limit);
  }
}

export default AIAuditLogger;
