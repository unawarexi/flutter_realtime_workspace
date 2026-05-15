// ============================================================================
// TeamSpot — Document Worker
// Consumes RabbitMQ queues for distributed document processing:
//   • PDF_RENDER    → generate PDFs via pdf-renderer
//   • AI_RAG_INGEST → parse documents into text for RAG ingestion
//   • ANALYTICS     → export tabular reports (CSV/XLSX/DOCX)
//   • AUDIT         → export audit logs
//
// Concurrency: 10 (matches channel.prefetch(10) in rabbitmq.service.js)
// Results are uploaded to Cloudinary and cached in Redis.
// WebSocket events notify the requesting user when a job completes.
// ============================================================================

import { createLogger } from "../observability/logger.js";
import { markJobDone, markJobFailed } from "../infrastructure/pdf/document-job.service.js";

const log = createLogger("DocumentWorker");

// ─────────────────────────────────────────────────────────────────────────────
// RENDER HANDLER — PDF generation
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Handle a PDF render job from the PDF_RENDER queue.
 * Payload: { jobId, templateName, data, branding, pdfOptions, tenantId, userId, documentId, label }
 */
export async function handleRenderJob(msg) {
  const payload = msg.data ?? msg;
  const { jobId, templateName, data, branding, pdfOptions, tenantId, userId, documentId, label } = payload;

  log.info("Handling render job", { jobId, label });

  try {
    const { generatePDFFromTemplate } = await import("../infrastructure/pdf/pdf-renderer.js");
    const { uploadBuffer } = await import("../infrastructure/storage/cloudinary.service.js")
      .catch(() => null) ?? {};

    const pdfBuffer = await generatePDFFromTemplate({ templateName, data, branding, pdfOptions });

    // Upload rendered PDF to Cloudinary
    let resultUrl = null;
    if (uploadBuffer) {
      const uploaded = await uploadBuffer(pdfBuffer, {
        folder: `tenants/${tenantId}/documents/rendered`,
        public_id: jobId,
        resource_type: "raw",
        format: "pdf",
      }).catch((err) => {
        log.warn("Upload failed, skipping", { error: err.message });
        return null;
      });
      resultUrl = uploaded?.url ?? null;
    }

    const result = { url: resultUrl, jobId, label, documentId, pdfSize: pdfBuffer.length };
    await markJobDone(jobId, result);

    // WebSocket notification
    await _notifyUser(userId, tenantId, "DOCUMENT_RENDER_READY", result);

    log.info("Render job complete", { jobId, url: resultUrl });
  } catch (err) {
    log.error("Render job failed", { jobId, error: err.message });
    await markJobFailed(jobId, err);
    await _notifyUser(payload.userId, payload.tenantId, "DOCUMENT_RENDER_FAILED", { jobId, error: err.message });
    throw err; // re-throw so RabbitMQ can nack and route to DLX
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PARSE HANDLER — RAG text extraction
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Handle a document parse job from the AI_RAG_INGEST queue.
 * Payload: { jobId, documentId, tenantId, orgId, url, filename, mimeType, docType, userId }
 */
export async function handleParseJob(msg) {
  const payload = msg.data ?? msg;
  const { jobId, documentId, tenantId, orgId, url, filename, mimeType, userId } = payload;

  log.info("Handling parse job", { jobId, filename });

  try {
    // Download the file buffer from the URL
    const fetch = (await import("node-fetch")).default;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to fetch document: ${response.statusText}`);
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Parse text content
    const { parseDocument } = await import("../infrastructure/pdf/pdf-docx-parser.js");
    const { text, metadata } = await parseDocument({ buffer, mimetype: mimeType, originalname: filename });

    const result = {
      jobId,
      documentId,
      tenantId,
      orgId,
      text,
      metadata,
      charCount: text.length,
    };

    await markJobDone(jobId, { jobId, documentId, charCount: text.length, status: "indexed" });

    // Trigger RAG embedding via AI worker
    const { publishToQueue } = await import("../infrastructure/rabbitmq/rabbitmq.service.js");
    const { RabbitQueues } = await import("../config/constants.js");
    await publishToQueue(RabbitQueues.AI_EMBEDDING, {
      documentId,
      tenantId,
      orgId,
      text,
      metadata,
    });

    await _notifyUser(userId, tenantId, "DOCUMENT_INDEXED", { jobId, documentId, charCount: text.length });

    log.info("Parse job complete", { jobId, documentId, charCount: text.length });
  } catch (err) {
    log.error("Parse job failed", { jobId, error: err.message });
    await markJobFailed(jobId, err);
    await _notifyUser(payload.userId, payload.tenantId, "DOCUMENT_INDEX_FAILED", { jobId, error: err.message });
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORT HANDLER — CSV / XLSX / DOCX tabular data
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Handle a data export job from the ANALYTICS or AUDIT queue.
 * Payload: { jobId, type:"export", format, source, data, columns, title, tenantId, userId }
 */
export async function handleExportJob(msg) {
  const payload = msg.data ?? msg;
  if (payload.type !== "export") return; // queue may carry non-export messages

  const { jobId, format, data, columns, title, tenantId, userId } = payload;

  log.info("Handling export job", { jobId, format, title });

  try {
    let fileBuffer;
    let contentType;
    let fileExt;

    const reportGen = await import("../modules/analytics/report-gen-analytics.controller.js");

    switch (format) {
      case "csv":
        fileBuffer = reportGen.generateCSV(data, columns);
        contentType = "text/csv";
        fileExt = "csv";
        break;
      case "xlsx":
        fileBuffer = reportGen.generateXLSX(data, columns, title);
        contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        fileExt = "xlsx";
        break;
      case "docx":
        fileBuffer = await reportGen.generateDOCX(data, columns, title, "");
        contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        fileExt = "docx";
        break;
      case "pdf": {
        const { generateTablePDF } = await import("../infrastructure/pdf/pdf-renderer.js");
        fileBuffer = await generateTablePDF({ title, data, columns });
        contentType = "application/pdf";
        fileExt = "pdf";
        break;
      }
      default:
        throw new Error(`Unsupported export format: ${format}`);
    }

    // Upload to Cloudinary
    const { uploadBuffer } = await import("../infrastructure/storage/cloudinary.service.js")
      .catch(() => null) ?? {};

    let resultUrl = null;
    if (uploadBuffer) {
      const uploaded = await uploadBuffer(fileBuffer, {
        folder: `tenants/${tenantId}/exports`,
        public_id: `${jobId}.${fileExt}`,
        resource_type: "raw",
      }).catch((err) => {
        log.warn("Upload failed", { error: err.message });
        return null;
      });
      resultUrl = uploaded?.url ?? null;
    }

    const result = { url: resultUrl, jobId, format, title, fileSize: fileBuffer.length };
    await markJobDone(jobId, result);
    await _notifyUser(userId, tenantId, "DOCUMENT_EXPORT_READY", result);

    log.info("Export job complete", { jobId, format, url: resultUrl });
  } catch (err) {
    log.error("Export job failed", { jobId, error: err.message });
    await markJobFailed(jobId, err);
    await _notifyUser(payload.userId, payload.tenantId, "DOCUMENT_EXPORT_FAILED", { jobId, error: err.message });
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Emit a WebSocket event to the requesting user (best-effort, non-blocking).
 */
async function _notifyUser(userId, tenantId, event, data) {
  if (!userId) return;
  try {
    const { emitToUser } = await import("../infrastructure/websocket/websocket.service.js");
    emitToUser(userId, event, { ...data, tenantId });
  } catch {
    // WebSocket is optional — do not let it crash the worker
  }
}

export default { handleRenderJob, handleParseJob, handleExportJob };
