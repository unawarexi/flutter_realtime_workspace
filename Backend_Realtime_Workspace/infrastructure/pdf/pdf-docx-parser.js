// ============================================================================
// TeamSpot — Document Parser (unified)
// Parses any supported file for RAG ingestion:
//   parseDocument(file) → { text, metadata }
// Supports: PDF, DOCX, XLSX/XLS, CSV, Markdown, plain text
// ============================================================================

import mammoth from "mammoth";
import * as XLSX from "xlsx";
import path from "path";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("DocumentParser");

// ─────────────────────────────────────────────────────────────────────────────
// LOW-LEVEL TEXT EXTRACTORS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Extract plain text from a PDF buffer via pdf-parse (lazy-loaded).
 * Returns { text, numPages }.
 */
export async function extractTextFromPDFBuffer(buffer) {
  const pdfParse = (await import("pdf-parse")).default;
  const data = await pdfParse(buffer);
  return { text: (data.text || "").trim(), numPages: data.numpages || 0 };
}

/**
 * Extract plain text from a DOCX buffer.
 */
export async function extractTextFromDocxBuffer(buffer) {
  const result = await mammoth.extractRawText({ buffer });
  return result.value.trim();
}

/**
 * Extract plain text from a DOCX file path.
 */
export async function extractTextFromDocxPath(filePath) {
  const result = await mammoth.extractRawText({ path: filePath });
  return result.value.trim();
}

/**
 * Strip Markdown syntax and return readable plain text.
 */
export function parseMarkdown(markdownText) {
  return markdownText
    .replace(/^#{1,6}\s+/gm, "")
    .replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1")
    .replace(/`{1,3}[^`]*`{1,3}/g, "")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, "")
    .replace(/\[[^\]]*\]\(([^)]*)\)/g, "$1")
    .replace(/^[-*+]\s+/gm, "")
    .replace(/^\d+\.\s+/gm, "")
    .replace(/^>\s?/gm, "")
    .replace(/---|===/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED ENTRY POINT — for RAG pipeline / AI ingestion
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Parse any supported document into { text, metadata }.
 * @param {{ buffer: Buffer, mimetype: string, originalname: string, path?: string }} file
 * @returns {Promise<{ text: string, metadata: object }>}
 */
export async function parseDocument(file) {
  const { buffer, mimetype, originalname, path: filePath } = file;
  const ext = path.extname(originalname || "").toLowerCase();

  log.info("Parsing document", { originalname, mimetype, ext });

  try {
    if (mimetype === "application/pdf" || ext === ".pdf") {
      const { text, numPages } = await extractTextFromPDFBuffer(buffer);
      return { text, metadata: { source: originalname, type: "pdf", numPages, charCount: text.length } };
    }

    if (
      mimetype === "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
      ext === ".docx"
    ) {
      const raw = buffer
        ? await extractTextFromDocxBuffer(buffer)
        : await extractTextFromDocxPath(filePath);
      return { text: raw, metadata: { source: originalname, type: "docx", charCount: raw.length } };
    }

    if (
      mimetype === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
      mimetype === "application/vnd.ms-excel" ||
      ext === ".xlsx" || ext === ".xls" || ext === ".csv"
    ) {
      return await parseSpreadsheet(buffer, originalname);
    }

    if (mimetype === "text/markdown" || ext === ".md") {
      const text = parseMarkdown(buffer.toString("utf8"));
      return { text, metadata: { source: originalname, type: "markdown", charCount: text.length } };
    }

    if (mimetype === "text/plain" || ext === ".txt") {
      const text = buffer.toString("utf8").trim();
      return { text, metadata: { source: originalname, type: "text", charCount: text.length } };
    }

    log.warn("Unknown mimetype, attempting UTF-8 decode", { mimetype, ext });
    const text = buffer.toString("utf8").replace(/[\x00-\x08\x0B-\x1F\x7F]/g, " ").trim();
    return { text, metadata: { source: originalname, type: "unknown", charCount: text.length } };
  } catch (err) {
    log.error("Document parsing failed", { error: err.message, originalname });
    throw err;
  }
}

/**
 * Parse a spreadsheet (XLSX/XLS/CSV) into CSV-formatted plain text.
 * Returns { text, metadata } suitable for RAG ingestion.
 */
export async function parseSpreadsheet(buffer, name) {
  const wb = XLSX.read(buffer, { type: "buffer" });
  const lines = [];
  for (const sheetName of wb.SheetNames) {
    const ws = wb.Sheets[sheetName];
    const csv = XLSX.utils.sheet_to_csv(ws);
    if (csv.trim()) {
      lines.push(`## Sheet: ${sheetName}`);
      lines.push(csv);
    }
  }
  const text = lines.join("\n").trim();
  return {
    text,
    metadata: {
      source: name || "spreadsheet",
      type: "spreadsheet",
      sheets: wb.SheetNames,
      charCount: text.length,
    },
  };
}

export default {
  parseDocument,
  parseSpreadsheet,
  parseMarkdown,
  extractTextFromPDFBuffer,
  extractTextFromDocxBuffer,
  extractTextFromDocxPath,
};
