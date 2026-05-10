import BaseController from "../../core/base/base.controller.js";
import { auditService } from "./audit.service.js";

class AuditController extends BaseController {
  
  getAuditLogs = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const { action, category, userId, startDate, endDate } = req.query;
    
    const filter = { orgId };
    if (action) filter.action = action;
    if (category) filter.category = category;
    if (userId) filter["actor.userId"] = userId;
    
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }
    
    const pagination = BaseController.getPagination(req);
    const result = await auditService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort || { createdAt: -1 })
    });

    return BaseController.sendPaginated(res, result, "Audit logs retrieved");
  };

  getAuditLogById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const log = await auditService.findById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, log, "Audit log retrieved");
  };

  exportAuditLogs = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const { action, category, userId, startDate, endDate } = req.query;
    
    const filter = { orgId };
    if (action) filter.action = action;
    if (category) filter.category = category;
    if (userId) filter["actor.userId"] = userId;
    
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    const csvData = await auditService.exportLogs(filter, tenantId);
    
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="audit_logs_${orgId}_${Date.now()}.csv"`);
    res.status(200).send(csvData);
  };
}

export const auditController = new AuditController();
