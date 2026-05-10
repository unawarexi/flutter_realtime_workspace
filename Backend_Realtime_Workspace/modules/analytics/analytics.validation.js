import { query } from "express-validator";

export const getAnalyticsSchema = [
  query("startDate").optional().isISO8601().toDate(),
  query("endDate").optional().isISO8601().toDate(),
  query("type").optional().isIn(["tasks", "projects", "users", "meetings", "financial"]),
];

export const generateReportSchema = [
  query("type").isIn(["tasks", "projects", "users", "meetings", "financial"]).withMessage("Report type is required"),
  query("format").isIn(["pdf", "csv", "xlsx"]).withMessage("Format must be pdf, csv, or xlsx"),
];
