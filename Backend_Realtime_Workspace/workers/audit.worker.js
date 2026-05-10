// ============================================================================
// TeamSpot — Audit Worker
// Persists audit log entries asynchronously
// ============================================================================

import { createLogger } from "../observability/logger.js";

const log = createLogger("AuditWorker");

export async function processAuditLog(job) {
  const { data } = job;

  try {
    const AuditLog = (await import("../modules/audit/models/audit-log.model.js")).default;

    await AuditLog.create({
      tenantId: data.tenantId,
      orgId: data.orgId,
      action: data.action,
      category: data.category || "system",
      actor: data.actor,
      target: data.target,
      changes: data.changes,
      metadata: data.metadata,
      requestId: data.requestId,
      traceId: data.traceId,
      status: data.status || "success",
      errorMessage: data.errorMessage,
    });

    log.debug("Audit log persisted", { action: data.action, tenantId: data.tenantId });
  } catch (err) {
    log.error("Audit log persistence failed", { error: err, action: data.action });
    throw err;
  }
}

export default { processAuditLog };
