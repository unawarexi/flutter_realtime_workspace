// ============================================================================
// TeamSpot — Permission Engine
// Zanzibar-inspired permission evaluation (RBAC + ABAC + ReBAC)
// ============================================================================

import { Roles } from "../../config/constants.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("PermissionEngine");

// ============================================================================
// ROLE HIERARCHY — higher roles inherit all lower permissions
// ============================================================================

const ROLE_HIERARCHY = {
  [Roles.SUPER_ADMIN]: 100,
  [Roles.ORG_OWNER]: 90,
  [Roles.ORG_ADMIN]: 80,
  [Roles.WORKSPACE_ADMIN]: 70,
  [Roles.MANAGER]: 50,
  [Roles.MEMBER]: 30,
  [Roles.GUEST]: 10,
};

// ============================================================================
// PERMISSION MATRIX — role → resource → actions
// ============================================================================

const PERMISSION_MATRIX = {
  [Roles.SUPER_ADMIN]: { "*": ["*"] },
  [Roles.ORG_OWNER]: { "*": ["create", "read", "update", "delete", "manage", "invite", "export"] },
  [Roles.ORG_ADMIN]: {
    organization: ["read", "update", "invite", "export"],
    workspace: ["create", "read", "update", "delete", "manage"],
    project: ["create", "read", "update", "delete", "manage"],
    task: ["create", "read", "update", "delete"],
    issue: ["create", "read", "update", "delete"],
    ticket: ["create", "read", "update", "delete"],
    team: ["create", "read", "update", "delete", "manage", "invite"],
    channel: ["create", "read", "update", "delete"],
    meeting: ["create", "read", "update", "delete"],
    document: ["create", "read", "update", "delete"],
    user: ["read", "update"],
    role: ["read", "update"],
    billing: ["read"],
    analytics: ["read", "export"],
    audit: ["read"],
    integration: ["create", "read", "update", "delete"],
    workflow: ["create", "read", "update", "delete"],
    ai_agent: ["create", "read", "update"],
    admin: ["read"],
  },
  [Roles.WORKSPACE_ADMIN]: {
    workspace: ["read", "update"],
    project: ["create", "read", "update", "delete"],
    task: ["create", "read", "update", "delete"],
    issue: ["create", "read", "update", "delete"],
    ticket: ["create", "read", "update"],
    team: ["create", "read", "update", "invite"],
    channel: ["create", "read", "update", "delete"],
    meeting: ["create", "read", "update", "delete"],
    document: ["create", "read", "update", "delete"],
    user: ["read"],
    analytics: ["read"],
    workflow: ["create", "read", "update"],
    ai_agent: ["read", "create"],
  },
  [Roles.MANAGER]: {
    project: ["create", "read", "update"],
    task: ["create", "read", "update", "delete"],
    issue: ["create", "read", "update"],
    ticket: ["create", "read", "update"],
    team: ["read", "invite"],
    channel: ["create", "read", "update"],
    meeting: ["create", "read", "update"],
    document: ["create", "read", "update"],
    user: ["read"],
    analytics: ["read"],
    workflow: ["read"],
    ai_agent: ["read"],
  },
  [Roles.MEMBER]: {
    project: ["read"],
    task: ["create", "read", "update"],
    issue: ["create", "read", "update"],
    ticket: ["create", "read"],
    team: ["read"],
    channel: ["read"],
    meeting: ["read", "create"],
    document: ["create", "read"],
    user: ["read"],
    message: ["create", "read", "update", "delete"],
    ai_agent: ["read"],
  },
  [Roles.GUEST]: {
    project: ["read"],
    task: ["read"],
    channel: ["read"],
    meeting: ["read"],
    document: ["read"],
    message: ["read"],
  },
};

// ============================================================================
// EVALUATION
// ============================================================================

/**
 * Evaluate whether a user has permission to perform an action on a resource.
 * @param {Object} context
 * @param {string} context.userId
 * @param {string} context.userRole
 * @param {string} context.action — "create", "read", "update", "delete", "manage"
 * @param {string} context.resource — "project", "task", "channel", etc.
 * @returns {Promise<boolean>}
 */
export async function evaluatePermission(context) {
  const { userRole, action, resource } = context;

  if (!userRole) return false;

  // Super admin bypass
  if (userRole === Roles.SUPER_ADMIN) return true;

  const rolePermissions = PERMISSION_MATRIX[userRole];
  if (!rolePermissions) return false;

  // Wildcard check
  if (rolePermissions["*"]?.includes("*") || rolePermissions["*"]?.includes(action)) {
    return true;
  }

  // Specific resource check
  const resourcePermissions = rolePermissions[resource];
  if (!resourcePermissions) return false;

  return resourcePermissions.includes(action) || resourcePermissions.includes("*");
}

/**
 * Check if roleA is higher than roleB in the hierarchy
 */
export function isHigherRole(roleA, roleB) {
  return (ROLE_HIERARCHY[roleA] || 0) > (ROLE_HIERARCHY[roleB] || 0);
}

/**
 * Get the numeric level of a role
 */
export function getRoleLevel(role) {
  return ROLE_HIERARCHY[role] || 0;
}

export default { evaluatePermission, isHigherRole, getRoleLevel };
