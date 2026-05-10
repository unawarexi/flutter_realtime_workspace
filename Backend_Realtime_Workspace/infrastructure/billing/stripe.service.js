// ============================================================================
// TeamSpot — Stripe Billing Service
// Subscription management, checkout, webhooks, billing portal
// ============================================================================

import Stripe from "stripe";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("Billing");

let stripe = null;

// ============================================================================
// INITIALIZATION
// ============================================================================

export function initBilling() {
  if (!env.STRIPE_SECRET_KEY) {
    log.warn("Stripe not configured — missing STRIPE_SECRET_KEY");
    return false;
  }

  stripe = new Stripe(env.STRIPE_SECRET_KEY, { apiVersion: "2024-12-18.acacia" });
  log.success("Stripe initialized");
  return true;
}

function ensureStripe() {
  if (!stripe) throw new Error("Stripe not initialized. Call initBilling() first.");
}

// ============================================================================
// CUSTOMERS
// ============================================================================

export async function createCustomer({ email, name, userId, orgId }) {
  ensureStripe();
  const customer = await stripe.customers.create({
    email,
    name,
    metadata: { userId, orgId },
  });
  log.info("Stripe customer created", { customerId: customer.id, userId });
  return customer;
}

export async function getCustomer(customerId) {
  ensureStripe();
  return stripe.customers.retrieve(customerId);
}

export async function updateCustomer(customerId, updates) {
  ensureStripe();
  return stripe.customers.update(customerId, updates);
}

// ============================================================================
// SUBSCRIPTIONS
// ============================================================================

export async function createSubscription(customerId, priceId, options = {}) {
  ensureStripe();
  const subscription = await stripe.subscriptions.create({
    customer: customerId,
    items: [{ price: priceId }],
    payment_behavior: "default_incomplete",
    expand: ["latest_invoice.payment_intent"],
    ...options,
  });
  log.info("Subscription created", { subscriptionId: subscription.id, customerId });
  return subscription;
}

export async function cancelSubscription(subscriptionId, options = {}) {
  ensureStripe();
  const subscription = await stripe.subscriptions.cancel(subscriptionId, options);
  log.info("Subscription cancelled", { subscriptionId });
  return subscription;
}

export async function getSubscription(subscriptionId) {
  ensureStripe();
  return stripe.subscriptions.retrieve(subscriptionId);
}

export async function updateSubscription(subscriptionId, updates) {
  ensureStripe();
  return stripe.subscriptions.update(subscriptionId, updates);
}

export async function listSubscriptions(customerId) {
  ensureStripe();
  return stripe.subscriptions.list({ customer: customerId });
}

// ============================================================================
// CHECKOUT SESSION
// ============================================================================

export async function createCheckoutSession({ customerId, priceId, successUrl, cancelUrl, metadata = {} }) {
  ensureStripe();
  return stripe.checkout.sessions.create({
    customer: customerId,
    payment_method_types: ["card"],
    line_items: [{ price: priceId, quantity: 1 }],
    mode: "subscription",
    success_url: successUrl,
    cancel_url: cancelUrl,
    metadata,
  });
}

// ============================================================================
// WEBHOOK VERIFICATION
// ============================================================================

export function constructWebhookEvent(body, signature) {
  ensureStripe();
  return stripe.webhooks.constructEvent(body, signature, env.STRIPE_WEBHOOK_SECRET);
}

// ============================================================================
// BILLING PORTAL
// ============================================================================

export async function createPortalSession(customerId, returnUrl) {
  ensureStripe();
  return stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  });
}

// ============================================================================
// INVOICES
// ============================================================================

export async function listInvoices(customerId, limit = 10) {
  ensureStripe();
  return stripe.invoices.list({ customer: customerId, limit });
}

export async function getInvoice(invoiceId) {
  ensureStripe();
  return stripe.invoices.retrieve(invoiceId);
}

// ============================================================================
// USAGE REPORTING (for metered billing)
// ============================================================================

export async function reportUsage(subscriptionItemId, quantity, timestamp) {
  ensureStripe();
  return stripe.subscriptionItems.createUsageRecord(subscriptionItemId, {
    quantity,
    timestamp: timestamp || Math.floor(Date.now() / 1000),
    action: "increment",
  });
}

export default {
  initBilling,
  createCustomer,
  getCustomer,
  updateCustomer,
  createSubscription,
  cancelSubscription,
  getSubscription,
  updateSubscription,
  listSubscriptions,
  createCheckoutSession,
  constructWebhookEvent,
  createPortalSession,
  listInvoices,
  getInvoice,
  reportUsage,
};
