import BaseController from "../../core/base/base.controller.js";
import { billingService } from "./billing.service.js";

class BillingController extends BaseController {
  
  getSubscription = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const sub = await billingService.getSubscription(tenantId, orgId);
    return BaseController.sendSuccess(res, sub, "Subscription details retrieved");
  };

  updateSubscription = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const sub = await billingService.updateSubscription(req.body, tenantId, orgId);
    return BaseController.sendSuccess(res, sub, "Subscription updated");
  };

  getInvoices = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const pagination = BaseController.getPagination(req);
    const result = await billingService.getInvoices({ orgId }, pagination, tenantId);
    return BaseController.sendPaginated(res, result, "Invoices retrieved");
  };

  getInvoiceById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const invoice = await billingService.getInvoiceById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, invoice, "Invoice retrieved");
  };

  getUsageStats = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const stats = await billingService.getUsageStats(tenantId);
    return BaseController.sendSuccess(res, stats, "Usage stats retrieved");
  };
}

export const billingController = new BillingController();
