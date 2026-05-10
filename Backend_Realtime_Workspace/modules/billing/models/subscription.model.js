// ============================================================================
// TeamSpot — Billing Models (Subscription + Invoice)
// ============================================================================

import mongoose from "mongoose";

const subscriptionSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, unique: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
  plan: { type: String, enum: ["free", "starter", "professional", "enterprise"], default: "free" },
  status: { type: String, enum: ["active", "past_due", "cancelled", "trialing"], default: "active" },
  billingCycle: { type: String, enum: ["monthly", "annual"], default: "monthly" },
  currentPeriodStart: { type: Date },
  currentPeriodEnd: { type: Date },
  cancelledAt: { type: Date },
  trialEndsAt: { type: Date },
  seats: { purchased: { type: Number, default: 10 }, used: { type: Number, default: 1 } },
  externalId: { type: String }, // Stripe subscription ID
  paymentMethodId: { type: String },
}, { timestamps: true });

export const Subscription = mongoose.model("Subscription", subscriptionSchema);

const invoiceSchema = new mongoose.Schema({
  tenantId: { type: String, required: true, index: true },
  orgId: { type: mongoose.Schema.Types.ObjectId, ref: "Organization", required: true },
  invoiceNumber: { type: String, unique: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: "USD" },
  status: { type: String, enum: ["draft", "pending", "paid", "failed", "refunded"], default: "pending" },
  description: { type: String },
  lineItems: [{ description: { type: String }, quantity: { type: Number }, unitPrice: { type: Number }, total: { type: Number } }],
  paidAt: { type: Date },
  dueDate: { type: Date },
  externalId: { type: String }, // Stripe invoice ID
  pdfUrl: { type: String },
}, { timestamps: true });

export const Invoice = mongoose.model("Invoice", invoiceSchema);
