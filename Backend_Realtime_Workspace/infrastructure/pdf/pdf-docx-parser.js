import { PDF } from "@libpdf/core";
import mammoth from "mammoth";
import * as csvParser from "csv-parse/sync";
import * as XLSX from "xlsx";
import { parseQuestionsFromExtractedText } from "./helper.js";

/**
 * Randomize options and correct answer for a question object.
 * Ensures correctAnswer is updated to match the new option text.
 */
function randomizeOptionsAndAnswer(question) {
  if (!Array.isArray(question.options) || question.options.length < 2)
    return question;

  // Pair each option with its original index
  const optionPairs = question.options.map((opt, idx) => ({ opt, idx }));

  // Shuffle options
  for (let i = optionPairs.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [optionPairs[i], optionPairs[j]] = [optionPairs[j], optionPairs[i]];
  }

  // Find the new index of the correct answer
  const originalCorrect = question.correctAnswer;
  let newCorrectAnswer = originalCorrect;

  // If correctAnswer is a letter (A/B/C/D), convert to text
  if (
    typeof originalCorrect === "string" &&
    originalCorrect.length === 1 &&
    /[A-D]/i.test(originalCorrect)
  ) {
    const idx = originalCorrect.toUpperCase().charCodeAt(0) - 65;
    newCorrectAnswer = question.options[idx] || originalCorrect;
  }

  // Find the new option text for the correct answer
  const shuffledOptions = optionPairs.map((pair) => pair.opt);
  const correctIdx = optionPairs.findIndex(
    (pair) => pair.opt === newCorrectAnswer,
  );

  return {
    ...question,
    options: shuffledOptions,
    correctAnswer: shuffledOptions[correctIdx] || shuffledOptions[0],
  };
}

/**
 * Extract text from PDF buffer using @libpdf/core
 */
export async function extractTextFromPDFBuffer(buffer) {
  const pdf = await PDF.load(buffer);
  const pages = pdf.getPages();
  let fullText = "";

  for (const page of pages) {
    const pageText = page.extractText();
    fullText += pageText.text + "\n";
  }

  return fullText.trim();
}

/**
 * Extract text from DOCX buffer
 */
export async function extractTextFromDocxBuffer(buffer) {
  const result = await mammoth.extractRawText({ buffer });
  return result.value.trim();
}

/**
 * Extract text from DOCX file path
 */
export async function extractTextFromDocxPath(path) {
  const result = await mammoth.extractRawText({ path });
  return result.value.trim();
}

/**
 * Extract questions from uploaded file (CSV, XLSX, DOCX, PDF)
 * Returns array of question objects
 */
export async function extractQuestionsFromFile(file) {
  const fileType = file.mimetype;
  const ext = file.originalname.split(".").pop().toLowerCase();
  let questions = [];

  // CSV
  if (fileType === "text/csv" || ext === "csv") {
    const csvText = file.buffer.toString("utf-8");
    let rows;
    try {
      rows = csvParser.parse(csvText, {
        columns: true,
        skip_empty_lines: true,
      });
    } catch {
      rows = [];
    }
    // If rows are empty or only one column, treat as plain text
    const isPlainText =
      !rows.length || (rows.length && Object.keys(rows[0]).length === 1);
    if (isPlainText) {
      // Fallback: parse as plain text using helper
      const questions = parseQuestionsFromExtractedText(csvText);
      // Only return questions that have at least 2 options and a correct answer
      return questions.filter(
        (q) => q.question && q.options.length >= 2 && q.correctAnswer,
      );
    }
    // Otherwise, treat as table
    questions = rows
      .map((row) => ({
        question: row.question || row.Question || "",
        options: [
          row.optionA || row.OptionA || row.A || "",
          row.optionB || row.OptionB || row.B || "",
          row.optionC || row.OptionC || row.C || "",
          row.optionD || row.OptionD || row.D || "",
        ].filter(Boolean),
        correctAnswer: row.correctAnswer || row.CorrectAnswer || "",
        marks: parseInt(row.marks || row.Marks || 1),
        difficulty: row.difficulty || row.Difficulty || "medium",
        topic: row.topic || row.Topic || "",
      }))
      .filter((q) => q.question && q.options.length >= 2 && q.correctAnswer)
      .map(randomizeOptionsAndAnswer);
  }
  // XLSX/XLS
  else if (
    fileType ===
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
    fileType === "application/vnd.ms-excel" ||
    ext === "xlsx" ||
    ext === "xls"
  ) {
    const workbook = XLSX.read(file.buffer, { type: "buffer" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 });
    const [header, ...body] = rows;
    const idx = (key) =>
      header.findIndex((h) => h?.toLowerCase().includes(key));
    questions = body
      .map((row) => ({
        question: row[idx("question")] || "",
        options: [
          row[idx("optiona")] || "",
          row[idx("optionb")] || "",
          row[idx("optionc")] || "",
          row[idx("optiond")] || "",
        ].filter(Boolean),
        correctAnswer: row[idx("correctanswer")] || "",
        marks: parseInt(row[idx("marks")] || 1),
        difficulty: row[idx("difficulty")] || "medium",
        topic: row[idx("topic")] || "",
      }))
      .filter((q) => q.question && q.options.length >= 2)
      .map(randomizeOptionsAndAnswer);
  }
  // DOCX - Extract text and parse using helper function
  else if (
    fileType ===
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
    ext === "docx"
  ) {
    const extractedText = await extractTextFromDocxBuffer(file.buffer);
    questions = parseQuestionsFromExtractedText(extractedText)
      .filter((q) => q.question && q.options.length >= 2 && q.correctAnswer)
      .map(randomizeOptionsAndAnswer);
  }
  // PDF - Extract text and parse using helper function
  else if (fileType === "application/pdf" || ext === "pdf") {
    const extractedText = await extractTextFromPDFBuffer(file.buffer);
    questions = parseQuestionsFromExtractedText(extractedText)
      .filter((q) => q.question && q.options.length >= 2 && q.correctAnswer)
      .map(randomizeOptionsAndAnswer);
  } else {
    throw new Error(
      "Unsupported file type. Please upload CSV, Excel, DOCX, or PDF.",
    );
  }

  // Filter valid questions (already filtered above)
  return questions;
}