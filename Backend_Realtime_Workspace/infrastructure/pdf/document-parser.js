// ============================================================================
// TeamSpot — Document Parser
// Extracts plain text from various file formats for RAG ingestion
// Supports: PDF, DOCX, XLSX/CSV, Markdown, plain text
// ============================================================================

import path from "path";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("DocumentParser");

/**
 * Parse any supported document buffer/path into {text, metadata}.
 * @param {{ buffer: Buffer, mimetype: string, originalname: string, path?: string }} file
 * @returns {Promise<{ text: string, metadata: object }>}
 */
export async function parseDocument(file) {
  const { buffer, mimetype, originalname, path: filePath } = file;
  const ext = path.extname(originalname || "").toLowerCase();

  log.info("Parsing document", { originalname, mimetype, ext });

  try {
    if (mimetype === "application/pdf" || ext === ".pdf") {
      return await parsePDF(buffer, originalname);
    }
    if (
      mimetype === "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
      ext === ".docx"
    ) {
      return await parseDOCX(buffer || filePath, originalname);
    }
    if (
      mimetype === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
      mimetype === "application/vnd.ms-excel" ||
      ext === ".xlsx" ||
      ext === ".xls" ||
      ext === ".csv"
    ) {
      return await parseSpreadsheet(buffer, originalname);
    }
    if (mimetype === "text/markdown" || ext === ".md") {
      const text = parseMarkdown(buffer.toString("utf8"));
      return { text, metadata: { source: originalname, type: "markdown" } };
    }
    if (mimetype === "text/plain" || ext === ".txt") {
      const text = buffer.toString("utf8").trim();
      return { text, metadata: { source: originalname, type: "text" } };
    }
    // Fallback: try to decode as UTF-8 text
    log.warn("Unknown mimetype, attempting UTF-8 decode", { mimetype, ext });
    const text = buffer.toString("utf8").replace(/[\x00-\x08\x0B-\x1F\x7F]/g, " ").trim();
    return { text, metadata: { source: originalname, type: "unknown" } };
  } catch (err) {
    log.error("Document parsing failed", { error: err.message, originalname });
    throw err;
  }
}

/**
 * Extract text from a PDF buffer using pdf-parse.
 */
export async function extractTextFromPDF(buffer) {
  const pdfParse = (await import("pdf-parse")).default;
  const data = await pdfParse(buffer);
  return data.text || "";
}

async function parsePDF(buffer, name) {
  const text = await extractTextFromPDF(buffer);
  return {
    text: text.trim(),
    metadata: {
      source: name,
      type: "pdf",
      charCount: text.length,
    },
  };
}

/**
 * Extract text from a DOCX file using mammoth.
 * @param {Buffer|string} bufferOrPath - Buffer or file path
 */
export async function extractTextFromDocx(bufferOrPath) {
  const mammoth = (await import("mammoth")).default;
  const opts = Buffer.isBuffer(bufferOrPath)
    ? { buffer: bufferOrPath }
    : { path: bufferOrPath };
  const result = await mammoth.extractRawText(opts);
  return result.value || "";
}

async function parseDOCX(bufferOrPath, name) {
  const text = await extractTextFromDocx(bufferOrPath);
  return {
    text: text.trim(),
    metadata: {
      source: name,
      type: "docx",
      charCount: text.length,
    },
  };
}

/**
 * Parse a spreadsheet (XLSX/XLS/CSV) into tab-separated plain text.
 */
export async function parseSpreadsheet(buffer, name) {
  const XLSX = (await import("xlsx")).default;
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
  const text = lines.join("\n");
  return {
    text: text.trim(),
    metadata: {
      source: name || "spreadsheet",
      type: "spreadsheet",
      sheets: wb.SheetNames,
      charCount: text.length,
    },
  };
}

/**
 * Strip Markdown syntax and return clean readable plain text.
 */
export function parseMarkdown(markdownText) {
  return markdownText
    .replace(/^#{1,6}\s+/gm, "")           // Remove headings
    .replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1") // Bold/italic
    .replace(/`{1,3}[^`]*`{1,3}/g, "")        // Code blocks/inline
    .replace(/!\[[^\]]*\]\([^)]*\)/g, "")   // Images
    .replace(/\[[^\]]*\]\([^)]*\)/g, "$1")   // Links -> link text
    .replace(/^[-*+]\s+/gm, "")              // Unordered lists
    .replace(/^\d+\.\s+/gm, "")             // Ordered lists
    .replace(/^>\s?/gm, "")                  // Blockquotes
    .replace(/---|===/g, "")                   // Horizontal rules
    .replace(/\n{3,}/g, "\n\n")             // Collapse blank lines
    .trim();
}
