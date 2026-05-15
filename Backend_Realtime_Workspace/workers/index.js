// ============================================================================
// TeamSpot — Worker Bootstrap
// Background job processor initialization
// ============================================================================

import { createLogger } from "../observability/logger.js";
import { initRedis } from "../infrastructure/redis/redis.service.js";

const log = createLogger("Workers");

/**
 * Initialize all background workers.
 * Workers consume from RabbitMQ queues and process jobs asynchronously.
 * Call this after infrastructure services are initialized.
 */
export async function initWorkers() {
  try {
    const { initRabbitMQ, consumeQueue } = await import("../infrastructure/rabbitmq/rabbitmq.service.js");
    await initRabbitMQ();

    // ── Notification Worker ──
    const { processNotification } = await import("./notification.worker.js");
    consumeQueue("teamspot.email.send", processNotification);
    consumeQueue("teamspot.push.notification", processNotification);
    log.info("Notification worker started");

    // ── Media Worker ──
    const { processMedia } = await import("./media.worker.js");
    consumeQueue("teamspot.media.process", processMedia);
    consumeQueue("teamspot.media.thumbnail", processMedia);
    log.info("Media worker started");

    // ── Audit Worker ──
    const { processAuditLog } = await import("./audit.worker.js");
    consumeQueue("teamspot.audit.log", processAuditLog);
    log.info("Audit worker started");

    // ── AI Worker ──
    const { processAITask } = await import("./ai.worker.js");
    consumeQueue("teamspot.ai.embedding", processAITask);
    consumeQueue("teamspot.ai.rag_ingest", processAITask);
    log.info("AI worker started");

    // ── Workflow Worker ──
    const { processWorkflow } = await import("./workflow.worker.js");
    consumeQueue("teamspot.workflow.execute", processWorkflow);
    log.info("Workflow worker started");

    // ── Analytics Worker ──
    const { processAnalytics } = await import("./analytics.worker.js");
    consumeQueue("teamspot.analytics.aggregate", processAnalytics);
    log.info("Analytics worker started");

    // ── Document Worker ──
    const { handleRenderJob, handleParseJob, handleExportJob } = await import("./document.worker.js");
    consumeQueue("teamspot.pdf.render",    handleRenderJob);
    consumeQueue("teamspot.document.parse", handleParseJob);
    consumeQueue("teamspot.analytics",     handleExportJob);
    consumeQueue("teamspot.audit",         (msg) => {
      if (msg?.data?.type === "export") return handleExportJob(msg);
    });
    log.info("Document worker started");

    log.success("All workers initialized");
  } catch (err) {
    log.warn("Workers initialization failed — background jobs disabled", { error: err.message });
  }
}

export default { initWorkers };
