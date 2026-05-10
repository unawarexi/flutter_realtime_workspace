import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import { Subscription, Invoice } from "./models/subscription.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";

class SubscriptionRepository extends BaseRepository {
  constructor() {
    super(Subscription, { tenantScoped: true });
  }
}

class InvoiceRepository extends BaseRepository {
  constructor() {
    super(Invoice, { tenantScoped: true });
  }
}

class BillingService extends BaseService {
  constructor() {
    super(new SubscriptionRepository(), {
      name: "BillingService",
      cachePrefix: "billing",
      cacheTTL: 1800,
    });
    this.invoiceRepository = new InvoiceRepository();
  }

  async getSubscription(tenantId, orgId) {
    let sub = await this.repository.findOne({ tenantId });
    if (!sub) {
        // Initialize free subscription by default
        sub = await this.repository.create({
            tenantId,
            orgId,
            plan: "free",
            status: "active",
            currentPeriodStart: new Date(),
            currentPeriodEnd: new Date(new Date().setFullYear(new Date().getFullYear() + 10)) // 10 years free
        });
    }
    return sub;
  }

  async updateSubscription(updates, tenantId, orgId) {
    let sub = await this.getSubscription(tenantId, orgId);
    
    // In a real implementation, this would trigger Stripe API calls
    const updated = await this.updateById(sub._id, updates, { tenantId });
    this.emit("billing.subscription_updated", { tenantId, plan: updated.plan });
    return updated;
  }

  async getInvoices(filter, pagination, tenantId) {
    return this.invoiceRepository.paginate(filter, {
        tenantId,
        page: pagination.page,
        limit: pagination.limit,
        sort: pagination.sort || { createdAt: -1 }
    });
  }

  async getInvoiceById(id, tenantId) {
    const invoice = await this.invoiceRepository.findById(id, { tenantId });
    if (!invoice) throw new AppError(HttpStatus.NOT_FOUND, "Invoice not found", "E3016");
    return invoice;
  }

  async getUsageStats(tenantId) {
    // Stub for usage statistics (e.g. seats used, storage used)
    const sub = await this.repository.findOne({ tenantId });
    return {
        seats: sub ? sub.seats : { purchased: 10, used: 1 },
        storage: { limit: 100 * 1024 * 1024 * 1024, used: 10 * 1024 * 1024 }, // 100GB limit, 10MB used
        periodEnd: sub ? sub.currentPeriodEnd : null
    };
  }
}

export const billingService = new BillingService();
