// ============================================================================
// TeamSpot — Permission Middleware
// Hybrid RBAC + ABAC + ReBAC guard for route-level access control
// ============================================================================

import { AppError } from "../errors/app-error.js";
import { HttpStatus, ErrorCodes } from "../../config/constants.js";
import { evaluatePermission } from "./permission-engine.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("PermissionGuard");

/**
 * RBAC role check — user must have one of the allowed roles
 * @param {...string} allowedRoles
 */
export function requireRole(...allowedRoles) {
  return (req, _res, next) => {
    const userRole = req.user?.role || req.user?.permissionsLevel;

    if (!userRole || !allowedRoles.includes(userRole)) {
      return next(new AppError(
        `Role '${userRole}' is not authorized. Required: ${allowedRoles.join(", ")}`,
        HttpStatus.FORBIDDEN,
        ErrorCodes.ROLE_NOT_ALLOWED
      ));
    }

    next();
  };
}

/**
 * Permission check — evaluates action + resource against user context
 * @param {string} action — e.g. "create", "read", "update", "delete", "manage"
 * @param {string} resource — e.g. "project", "task", "channel"
 * @param {Object} [options]
 * @param {Function} [options.getResourceOwnerId] — (req) => ownerId for ownership check
 */
export function requirePermission(action, resource, options = {}) {
  return async (req, _res, next) => {
    try {
      const context = {
        userId: req.user?.uid,
        userRole: req.user?.role || req.user?.permissionsLevel,
        tenantId: req.tenantId,
        orgId: req.orgId,
        workspaceId: req.workspaceId || req.query?.workspaceId,
        resourceId: req.params?.id,
        action,
        resource,
      };

      // Ownership check shortcut
      if (options.getResourceOwnerId) {
        const ownerId = await options.getResourceOwnerId(req);
        if (ownerId && ownerId.toString() === context.userId) {
          return next(); // Owner always has access
        }
      }

      const allowed = await evaluatePermission(context);

      if (!allowed) {
        return next(new AppError(
          `Insufficient permissions: ${action} on ${resource}`,
          HttpStatus.FORBIDDEN,
          ErrorCodes.INSUFFICIENT_PERMISSIONS
        ));
      }

      next();
    } catch (err) {
      log.error("Permission evaluation failed", { error: err });
      next(err);
    }
  };
}

/**
 * Self-only access — user can only access their own resources
 * @param {string} [paramName='id'] — route param containing the user ID
 */
export function requireSelf(paramName = "id") {
  return (req, _res, next) => {
    const targetId = req.params[paramName];
    const userId = req.user?.uid;

    if (targetId && targetId !== userId) {
      return next(new AppError(
        "You can only access your own resources",
        HttpStatus.FORBIDDEN,
        ErrorCodes.RESOURCE_ACCESS_DENIED
      ));
    }

    next();
  };
}

export default { requireRole, requirePermission, requireSelf };
