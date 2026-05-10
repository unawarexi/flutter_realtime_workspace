// ============================================================================
// TeamSpot — Tenant Middleware
// Multi-tenant context extraction and validation
// ============================================================================

import { AppError } from "../errors/app-error.js";
import { HttpStatus, ErrorCodes } from "../../config/constants.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("TenantMiddleware");

/**
 * Extracts tenantId/orgId/workspaceId from request headers or user context.
 * Sets req.tenantId, req.orgId, req.workspaceId for downstream use.
 */
export function tenantMiddleware(req, _res, next) {
  // Priority: header → query → user context
  req.tenantId =
    req.headers["x-tenant-id"] ||
    req.query.tenantId ||
    req.user?.tenantId ||
    null;

  req.orgId =
    req.headers["x-org-id"] ||
    req.query.orgId ||
    req.user?.orgId ||
    null;

  req.workspaceId =
    req.headers["x-workspace-id"] ||
    req.query.workspaceId ||
    req.user?.workspaceId ||
    null;

  next();
}

/**
 * Requires a valid tenantId — blocks requests without one.
 * Use on routes that must be tenant-scoped.
 */
export function requireTenant(req, _res, next) {
  if (!req.tenantId) {
    return next(new AppError(
      "Tenant context required. Provide x-tenant-id header or tenantId query parameter.",
      HttpStatus.BAD_REQUEST,
      ErrorCodes.TENANT_NOT_FOUND
    ));
  }
  next();
}

/**
 * Requires a valid orgId — blocks requests without one.
 */
export function requireOrg(req, _res, next) {
  if (!req.orgId) {
    return next(new AppError(
      "Organization context required. Provide x-org-id header or orgId query parameter.",
      HttpStatus.BAD_REQUEST,
      ErrorCodes.ORGANIZATION_NOT_FOUND
    ));
  }
  next();
}

export default { tenantMiddleware, requireTenant, requireOrg };
