// ============================================================================
// TeamSpot — Document Job Service
// Distributed document processing via RabbitMQ + Kafka + Redis
//
// Three job types:
//   1. PARSE  — extract text for RAG ingestion (AI_RAG_INGEST queue)
//   2. RENDER — generate PDF from template   (PDF_RENDER queue)
//   3. EXPORT — CSV / XLSX / DOCX export     (ANALYTICS / AUDIT queue)
//
// Results are cached in Redis with configurable TTL.
// Kafka is used for event fan-out to analytics / audit / storage topics.
// ============================================================================

import { nanoid } from "nanoid";
import { createLogger } from "../../observability/logger.js";
import { publishToQueue } from "../rabbitmq/rabbitmq.service.js";
import { publishEvent } from "../kafka/kafka.service.js";
import { getCache, setCache } from "../redis/redis.service.js";
import { KafkaTopics, RabbitQueues } from "../../config/constants.js";

const log = createLogger("DocumentJobService");

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const JOB_STATUS = {
  PENDING:    "pending",
  PROCESSING: "processing",
  DONE:       "done",
  FAILED:     "failed",
};

const DEFAULT_TTL  = 3600;   // 1 hour — cached parse/render results
const STATUS_TTL   = 86400;  // 24 hours — job status records

// ─────────────────────────────────────────────────────────────────────────────
// REDIS KEY HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const jobKey    = (id) => `docjob:${id}`;
const resultKey = (id) => `docjob:result:${id}`;

// ─────────────────────────────────────────────────────────────────────────────
// JOB STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Persist job status to Redis.
 * @param {string} jobId
 * @param {string} status  — one of JOB_STATUS values
 * @param {object} [meta]  — extra fields merged into the record
 */
export async function setJobStatus(jobId, status, meta = {}) {
  await setCache(
    jobKey(jobId),
    JSON.stringify({ jobId, status, updatedAt: new Date().toISOString(), ...meta }),
    STATUS_TTL,
  );
}

/**
 * Read job status from Redis.
 * @returns {{ jobId, status, updatedAt, ...meta } | null}
 */
export async function getJobStatus(jobId) {
  const raw = await getCache(jobKey(jobId));
  return raw ? JSON.parse(raw) : null;
}

/**
 * Store a serialisable result in Redis.
 * @param {string} jobId
 * @param {object} result  — must be JSON-serialisable (use urls / references for buffers)
 * @param {number} [ttl]   — seconds
 */
export async function cacheResult(jobId, result, ttl = DEFAULT_TTL) {
  await setCache(resultKey(jobId), JSON.stringify(result), ttl);
}

/**
 * Retrieve a previously cached result.
 * @returns {object | null}
 */
export async function getCachedResult(jobId) {
  const raw = await getCache(resultKey(jobId));
  return raw ? JSON.parse(raw) : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// DISPATCH — PARSE (RAG ingestion)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Dispatch a document-parse job for RAG / AI ingestion.
 *
 * @param {{ documentId, tenantId, orgId, url, filename, mimeType, docType }} fileInfo
 * @param {{ priority?: number, userId?: string }}                             [opts]
 * @returns {Promise<string>} jobId
 */
export async function dispatchParseJob(fileInfo, opts = {}) {
  const jobId = `parse_${nanoid(12)}`;

  const payload = {
    jobId,
    type: "parse",
    ...fileInfo,
    userId:    opts.userId,
    createdAt: new Date().toISOString(),
  };

  await Promise.all([
    publishToQueue(RabbitQueues.AI_RAG_INGEST, payload),
    setJobStatus(jobId, JOB_STATUS.PENDING, { type: "parse", documentId: fileInfo.documentId }),
  ]);

  // Fan-out: notify storage / AI topics
  await publishEvent(KafkaTopics.DOCUMENT_EVENTS, fileInfo.tenantId, {
    type:       "document.parse.queued",
    jobId,
    documentId: fileInfo.documentId,
    tenantId:   fileInfo.tenantId,
  }).catch((err) => log.warn("Kafka fan-out failed", { error: err.message }));

  log.info("Parse job dispatched", { jobId, documentId: fileInfo.documentId });
  return jobId;
}

// ─────────────────────────────────────────────────────────────────────────────
// DISPATCH — RENDER (PDF generation)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Dispatch a PDF render job.
 *
 * @param {{ templateName?: string, data: object, branding?: object }} renderOptions
 * @param {{ tenantId, userId, documentId?, label? }}                  [opts]
 * @returns {Promise<string>} jobId
 */
export async function dispatchRenderJob(renderOptions, opts = {}) {
  const jobId = `render_${nanoid(12)}`;

  const payload = {
    jobId,
    type: "render",
    templateName: renderOptions.templateName || "pdf-base",
    data:         renderOptions.data,
    branding:     renderOptions.branding || {},
    pdfOptions:   renderOptions.pdfOptions || {},
    tenantId:     opts.tenantId,
    userId:       opts.userId,
    documentId:   opts.documentId,
    label:        opts.label,
    createdAt:    new Date().toISOString(),
  };

  await Promise.all([
    publishToQueue(RabbitQueues.PDF_RENDER, payload),
    setJobStatus(jobId, JOB_STATUS.PENDING, { type: "render", tenantId: opts.tenantId }),
  ]);

  await publishEvent(KafkaTopics.DOCUMENT_EVENTS, opts.tenantId, {
    type:     "document.render.queued",
    jobId,
    tenantId: opts.tenantId,
    label:    opts.label,
  }).catch((err) => log.warn("Kafka fan-out failed", { error: err.message }));

  log.info("Render job dispatched", { jobId, label: opts.label });
  return jobId;
}

// ─────────────────────────────────────────────────────────────────────────────
// DISPATCH — EXPORT (CSV / XLSX / DOCX)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Dispatch a tabular-data export job.
 *
 * @param {"csv"|"xlsx"|"docx"|"pdf"} format
 * @param {{ data: any[], columns: object[], title?: string }}         exportData
 * @param {{ tenantId, userId, source?: "analytics"|"audit"|"report" }} opts
 * @returns {Promise<string>} jobId
 */
export async function dispatchExportJob(format, exportData, opts = {}) {
  const jobId = `export_${nanoid(12)}`;
  const source = opts.source || "report";

  // Route to the appropriate queue based on source
  const queue = source === "audit"
    ? RabbitQueues.AUDIT
    : RabbitQueues.ANALYTICS;

  const kafkaTopic = source === "audit"
    ? KafkaTopics.AUDIT_EVENTS
    : KafkaTopics.ANALYTICS_EVENTS;

  const payload = {
    jobId,
    type:      "export",
    format,
    source,
    data:      exportData.data,
    columns:   exportData.columns,
    title:     exportData.title || "Export",
    tenantId:  opts.tenantId,
    userId:    opts.userId,
    createdAt: new Date().toISOString(),
  };

  await Promise.all([
    publishToQueue(queue, payload),
    setJobStatus(jobId, JOB_STATUS.PENDING, { type: "export", format, source, tenantId: opts.tenantId }),
  ]);

  await publishEvent(kafkaTopic, opts.tenantId, {
    type:     "document.export.queued",
    jobId,
    format,
    source,
    tenantId: opts.tenantId,
  }).catch((err) => log.warn("Kafka fan-out failed", { error: err.message }));

  log.info("Export job dispatched", { jobId, format, source });
  return jobId;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK COMPLETE / FAILED  (called by workers after processing)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Mark a job as done and cache its result.
 * @param {string} jobId
 * @param {{ url?: string, cloudinaryId?: string, [key: string]: any }} result
 */
export async function markJobDone(jobId, result) {
  await Promise.all([
    setJobStatus(jobId, JOB_STATUS.DONE, { result }),
    cacheResult(jobId, result),
  ]);
}

/**
 * Mark a job as failed.
 * @param {string} jobId
 * @param {string|Error} error
 */
export async function markJobFailed(jobId, error) {
  const message = error instanceof Error ? error.message : String(error);
  await setJobStatus(jobId, JOB_STATUS.FAILED, { error: message });
}

export { JOB_STATUS };

export default {
  dispatchParseJob,
  dispatchRenderJob,
  dispatchExportJob,
  getJobStatus,
  getCachedResult,
  cacheResult,
  markJobDone,
  markJobFailed,
  JOB_STATUS,
};
