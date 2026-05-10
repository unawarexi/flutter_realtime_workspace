import { body, param } from "express-validator";

export const createTicketSchema = [
  body("title").trim().notEmpty().withMessage("Ticket title is required").isLength({ max: 200 }),
  body("description").optional().isString(),
  body("type").optional().isIn(["bug", "feature", "support", "question", "incident"]),
  body("priority").optional().isIn(["critical", "high", "medium", "low"]),
  body("category").optional().isString(),
];

export const updateTicketSchema = [
  param("id").isMongoId().withMessage("Invalid ticket ID"),
  body("title").optional().trim().notEmpty().isLength({ max: 200 }),
  body("description").optional().isString(),
  body("assignee").optional().isMongoId(),
  body("status").optional().isIn(["open", "in_progress", "waiting", "resolved", "closed"]),
  body("type").optional().isIn(["bug", "feature", "support", "question", "incident"]),
  body("priority").optional().isIn(["critical", "high", "medium", "low"]),
  body("category").optional().isString(),
];
