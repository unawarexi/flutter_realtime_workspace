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

export async function processNotification(job) {
  const { data } = job;

  try {
    switch (data.channel) {
      case "email":
        let html = data.html;
        let subject = data.subject;
        
        // If templateName is provided, generate HTML using our centralized templates
        if (data.templateName && typeof emailGenerator[data.templateName] === "function") {
          const templateData = emailGenerator[data.templateName](data.templateData || {});
          subject = templateData.EMAIL_TITLE || data.subject;
          html = render(templateData);
        }

        await sendEmail({
          to: data.to,
          subject: subject,
          html: html,
          text: data.text,
        });
        log.info("Email sent via RabbitMQ job", { to: data.to, subject: subject });
        break;

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
