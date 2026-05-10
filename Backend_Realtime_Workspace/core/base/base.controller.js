// ============================================================================
// TeamSpot — Base Controller
// Async handler wrapper, standardized request parsing, error catching
// ============================================================================

import { HttpStatus } from "../../config/constants.js";
import { success, created, paginated, noContent } from "../utils/api-response.js";

// ============================================================================
// ASYNC HANDLER — wraps controller methods to catch async errors
// ============================================================================

export function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// ============================================================================
// BASE CONTROLLER CLASS
// ============================================================================

export class BaseController {
  /**
   * Extract common request context (user, tenant, pagination, etc.)
   */
  static getContext(req) {
    return {
      user: req.user || null,
      userId: req.user?.uid || req.user?.id || null,
      tenantId: req.tenantId || req.user?.tenantId || null,
      orgId: req.orgId || req.user?.orgId || null,
      workspaceId: req.workspaceId || req.query?.workspaceId || null,
      requestId: req.requestId || null,
      traceId: req.traceId || null,
      ip: req.ip,
      userAgent: req.get("user-agent"),
    };
  }

  /**
   * Extract pagination params from query string
   */
  static getPagination(req) {
    return {
      page: parseInt(req.query.page, 10) || 1,
      limit: parseInt(req.query.limit, 10) || 20,
      sort: req.query.sort || "-createdAt",
      search: req.query.search || "",
      cursor: req.query.cursor || null,
    };
  }

  /**
   * Parse sort string "-createdAt" → { createdAt: -1 }
   */
  static parseSort(sortStr) {
    if (!sortStr) return { createdAt: -1 };
    const direction = sortStr.startsWith("-") ? -1 : 1;
    const field = sortStr.replace(/^[-+]/, "");
    return { [field]: direction };
  }

  // Response helpers (bound to res for convenience)
  static sendSuccess(res, data, message) {
    return success(res, data, message);
  }

  static sendCreated(res, data, message) {
    return created(res, data, message);
  }

  static sendPaginated(res, result, message) {
    return paginated(res, {
      data: result.data,
      page: result.pagination.page,
      limit: result.pagination.limit,
      total: result.pagination.total,
      message,
    });
  }

  static sendNoContent(res) {
    return noContent(res);
  }
}

export default BaseController;
