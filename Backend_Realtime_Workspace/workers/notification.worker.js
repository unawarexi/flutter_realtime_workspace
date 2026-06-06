// ============================================================================
// TeamSpot — Notification Worker
// Processes email, push, and SMS delivery jobs
// ============================================================================

import { sendEmail } from "../infrastructure/mailer/mailer.service.js";
import { sendPushNotification, sendMulticast } from "../infrastructure/push/fcm.service.js";
import { createLogger } from "../observability/logger.js";
import EmailContentGenerator from "../infrastructure/mailer/mail-content.js";
import { render } from "../infrastructure/mailer/mail-render.js";

const log = createLogger("NotificationWorker");
const emailGenerator = new EmailContentGenerator();

/** Resolve email address from userId when `to` is null/empty. */
async function resolveEmailAddress(data) {
  if (data.to) return data.to;
  const userId = data.userId || data._meta?.userId;
  if (!userId) return null;
  try {
    const User = (await import("../modules/users/models/user.model.js")).default;
    const user = await User.findById(userId).select("email").lean();
    return user?.email || null;
  } catch {
    return null;
  }
}

export async function processNotification(job) {
  const { data } = job;

  try {
    switch (data.channel) {
      case "email": {
        // Resolve recipient email (some modules pass userId instead of to)
        const recipient = await resolveEmailAddress(data);
        if (!recipient) {
          log.warn("Email skipped — no recipient address", { templateName: data.templateName });
          break;
        }

        let html = data.html;
        let subject = data.subject;

        // Generate HTML from named template when available
        if (data.templateName && typeof emailGenerator[data.templateName] === "function") {
          const templateData = emailGenerator[data.templateName](data.templateData || {});
          subject = templateData.EMAIL_TITLE || data.subject;
          html = render(templateData);
        }

        if (!html) {
          log.warn("Email skipped — no HTML content", { templateName: data.templateName });
          break;
        }

        await sendEmail({ to: recipient, subject, html, text: data.text });
        log.info("Email sent via RabbitMQ job", { to: recipient, subject });
        break;
      }

      case "push":
        if (data.tokens && data.tokens.length > 1) {
          await sendMulticast({
            tokens: data.tokens,
            title: data.title,
            body: data.body,
            data: data.payload,
          });
        } else if (data.token) {
          await sendPushNotification({
            token: data.token,
            title: data.title,
            body: data.body,
            data: data.payload,
          });
        }
        log.info("Push notification sent", { title: data.title });
        break;

      case "sms":
        // SMS integration placeholder
        log.info("SMS delivery placeholder", { to: data.to });
        break;

      default:
        log.warn("Unknown notification channel", { channel: data.channel });
    }
  } catch (err) {
    log.error("Notification delivery failed", {
      error: err,
      channel: data.channel,
      to: data.to || data.token,
    });
    throw err; // Re-throw for DLQ
  }
}

export default { processNotification };
