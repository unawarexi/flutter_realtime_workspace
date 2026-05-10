import { body, param } from "express-validator";

export const updateSubscriptionSchema = [
  body("plan").optional().isIn(["free", "starter", "professional", "enterprise"]),
  body("billingCycle").optional().isIn(["monthly", "annual"]),
];

export const processWebhookSchema = [
  // Webhooks are usually validated via stripe signatures, so body validation here is minimal
  body("type").notEmpty().withMessage("Event type is required"),
];
