import { asyncHandler } from "../../core/base/base.controller.js";
import { auditService } from "./audit.service.js";
import { success, paginated } from "../../core/utils/api-response.js";

const ctx = (req) => ({ tenantId: req.tenant?.id || req.user?.tenantId });

export const getAuditLogs = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const result = await auditService.queryLogs({ ...req.query, tenantId });
  return paginated(res, result, "Audit logs retrieved");
});

export const getAuditLogById = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const log = await auditService.repository.findById(req.params.id, { tenantId });
  return success(res, log, "Audit log retrieved");
});

export const exportAuditLogs = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const csv = await auditService.exportLogs({ ...req.query, tenantId });
  res.setHeader("Content-Type", "text/csv");
  res.setHeader("Content-Disposition", `attachment; filename="audit_${tenantId}_${Date.now()}.csv"`);
  return res.status(200).send(csv);
});

export const auditController = { getAuditLogs, getAuditLogById, exportAuditLogs };
