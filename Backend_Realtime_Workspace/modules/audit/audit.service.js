import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import AuditLog from "./models/audit-log.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const { Parser } = require("json2csv");

class AuditRepository extends BaseRepository {
  constructor() {
    super(AuditLog, { tenantScoped: true });
  }
}

class AuditService extends BaseService {
  constructor() {
    super(new AuditRepository(), {
      name: "AuditService",
      cachePrefix: "audit",
      cacheTTL: 0, // No caching for audit logs to ensure truthfulness
    });
  }

  // Custom create wrapper to enforce immutability pattern
  async logAction(data, tenantId, reqContext = {}) {
    // We intentionally bypass BaseRepository's standard emit to avoid noise,
    // and just write directly to the DB.
    const newLog = new this.repository.model({
      ...data,
      tenantId,
      actor: {
        userId: reqContext.userId || "system",
        email: reqContext.email,
        role: reqContext.role,
        ip: reqContext.ip,
        userAgent: reqContext.userAgent,
      },
      requestId: reqContext.requestId
    });
    return newLog.save();
  }

  // Prevent updates and deletes at the service level
  async updateById() {
    throw new AppError(HttpStatus.FORBIDDEN, "Audit logs are append-only and cannot be updated", "E4030");
  }

  async deleteById() {
    throw new AppError(HttpStatus.FORBIDDEN, "Audit logs are append-only and cannot be deleted", "E4031");
  }

  async exportLogs(filter, tenantId) {
    const logs = await this.repository.model.find({ tenantId, ...filter }).sort({ createdAt: -1 }).lean();
    
    // Flatten for CSV
    const flatLogs = logs.map(log => ({
      date: log.createdAt,
      action: log.action,
      category: log.category,
      actorId: log.actor?.userId,
      actorEmail: log.actor?.email,
      targetType: log.target?.type,
      targetId: log.target?.id,
      status: log.status,
      errorMessage: log.errorMessage || ''
    }));

    const parser = new Parser();
    const csv = parser.parse(flatLogs);
    return csv;
  }
}

export const auditService = new AuditService();
