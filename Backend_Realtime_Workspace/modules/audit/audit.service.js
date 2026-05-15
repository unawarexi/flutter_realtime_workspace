// ============================================================================
// TeamSpot — Audit Service (append-only audit log with export + query)
// Consumed by: RabbitMQ AUDIT queue consumer (workers/audit.worker.js)
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import AuditLog from "./models/audit-log.model.js";
import { forbidden, badRequest } from "../../core/errors/app-error.js";
import { createRequire } from "module";
import { dispatchExportJob } from "../../infrastructure/pdf/document-job.service.js";

const require = createRequire(import.meta.url);
const { Parser } = require("json2csv");

class AuditRepository extends BaseRepository {
  constructor() { super(AuditLog, { tenantScoped: true }); }
}

class AuditService extends BaseService {
  constructor() {
    super(new AuditRepository(), {
      name: "AuditService",
      cachePrefix: "audit",
      cacheTTL: 0, // Audit logs are never cached
    });
  }

  // ── Write (called by audit.worker.js via RabbitMQ AUDIT queue) ──────────────
  async logAction(data, tenantId, reqContext = {}) {
    const doc = new this.repository.model({
      ...data,
      tenantId,
      actor: {
        userId: reqContext.userId || data.actor?.id || "system",
        email:  reqContext.email  || data.actor?.email,
        role:   reqContext.role   || data.actor?.role,
        ip:     reqContext.ip,
        userAgent: reqContext.userAgent,
      },
      requestId: reqContext.requestId,
      timestamp: new Date(),
    });
    return doc.save();
  }

  // ── Immutability guards ───────────────────────────────────────────────────────
  async updateById() { throw forbidden("Audit logs are append-only"); }
  async deleteById() { throw forbidden("Audit logs are append-only"); }

  // ── Query ─────────────────────────────────────────────────────────────────────
  async queryLogs({ tenantId, action, category, actorId, resourceType, from, to, severity, page = 1, limit = 50 }) {
    const filter = {};
    if (action)       filter.action       = new RegExp(action, "i");
    if (category)     filter.category     = category;
    if (resourceType) filter.resourceType = resourceType;
    if (severity)     filter.severity     = severity;
    if (actorId)      filter["actor.userId"] = actorId;
    if (from || to) {
      filter.timestamp = {};
      if (from) filter.timestamp.$gte = new Date(from);
      if (to)   filter.timestamp.$lte = new Date(to);
    }
    return this.repository.paginate({ filter, page: +page, limit: +limit, sort: { timestamp: -1 } }, { tenantId });
  }

  // ── Export to CSV ─────────────────────────────────────────────────────────────
  async exportLogs({ tenantId, from, to, category }) {
    const filter = { tenantId };
    if (category) filter.category = category;
    if (from || to) {
      filter.timestamp = {};
      if (from) filter.timestamp.$gte = new Date(from);
      if (to)   filter.timestamp.$lte = new Date(to);
    }

    const logs = await this.repository.model.find(filter).sort({ timestamp: -1 }).limit(10000).lean();
    const flat = logs.map(l => ({
      date:        l.timestamp || l.createdAt,
      action:      l.action,
      category:    l.category,
      severity:    l.severity || "info",
      actorId:     l.actor?.userId,
      actorEmail:  l.actor?.email,
      actorRole:   l.actor?.role,
      resourceType: l.resourceType,
      resourceId:  l.resourceId,
      status:      l.status,
      ip:          l.actor?.ip,
    }));

    const parser = new Parser();
    return parser.parse(flat);
  }

  // ── Async distributed export (CSV / XLSX / PDF) via job queue ────────────────
  async queueExport({ tenantId, from, to, category, format = "csv", userId }) {
    const filter = { tenantId };
    if (category) filter.category = category;
    if (from || to) {
      filter.timestamp = {};
      if (from) filter.timestamp.$gte = new Date(from);
      if (to)   filter.timestamp.$lte = new Date(to);
    }

    const logs = await this.repository.model.find(filter).sort({ timestamp: -1 }).limit(10000).lean();
    const rows = logs.map(l => ({
      date:         l.timestamp || l.createdAt,
      action:       l.action,
      category:     l.category,
      severity:     l.severity || "info",
      actorId:      l.actor?.userId,
      actorEmail:   l.actor?.email,
      actorRole:    l.actor?.role,
      resourceType: l.resourceType,
      resourceId:   l.resourceId,
      status:       l.status,
      ip:           l.actor?.ip,
    }));

    const columns = [
      { key: "date",         header: "Date" },
      { key: "action",       header: "Action" },
      { key: "category",     header: "Category" },
      { key: "severity",     header: "Severity" },
      { key: "actorId",      header: "Actor ID" },
      { key: "actorEmail",   header: "Actor Email" },
      { key: "actorRole",    header: "Role" },
      { key: "resourceType", header: "Resource Type" },
      { key: "resourceId",   header: "Resource ID" },
      { key: "status",       header: "Status" },
      { key: "ip",           header: "IP" },
    ];

    return dispatchExportJob(
      format,
      { data: rows, columns, title: "Audit Log Export" },
      { tenantId, userId, source: "audit" },
    );
  }
}

export const auditService = new AuditService();
