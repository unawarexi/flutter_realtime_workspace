// ============================================================================
// TeamSpot — Mailer Service
// Nodemailer SMTP with HTML template rendering
// ============================================================================

import nodemailer from "nodemailer";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("Mailer");

let transporter = null;

export function initMailer() {
  transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_SECURE,
    auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASS } : undefined,
    pool: true,
    maxConnections: 5,
    maxMessages: 100,
    rateLimit: 10,
  });
  log.info("Mailer initialized", { host: env.SMTP_HOST, port: env.SMTP_PORT });
}

export async function verifyMailer() {
  if (!transporter) initMailer();
  await transporter.verify();
  log.success("SMTP connection verified");
}

export async function sendEmail({ to, subject, html, text, from, attachments }) {
  if (!transporter) initMailer();

  const result = await transporter.sendMail({
    from: from || env.SMTP_FROM,
    to,
    subject,
    html,
    text,
    attachments,
  });

  log.info("Email sent", { to, subject, messageId: result.messageId });
  return result;
}

export async function sendBulkEmails(emails) {
  const results = [];
  for (const email of emails) {
    try {
      const result = await sendEmail(email);
      results.push({ success: true, to: email.to, messageId: result.messageId });
    } catch (err) {
      log.error("Bulk email failed", { to: email.to, error: err });
      results.push({ success: false, to: email.to, error: err.message });
    }
  }
  return results;
}

export default { initMailer, verifyMailer, sendEmail, sendBulkEmails };
