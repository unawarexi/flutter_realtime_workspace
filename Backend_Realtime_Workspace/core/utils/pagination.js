// ============================================================================
// TeamSpot — Pagination Utilities
// Cursor-based + offset pagination helpers
// ============================================================================

import { PaginationDefaults } from "../../config/constants.js";

/**
 * Parse pagination params from query string
 */
export function parsePagination(query = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || PaginationDefaults.PAGE);
  const limit = Math.min(
    Math.max(1, parseInt(query.limit, 10) || PaginationDefaults.LIMIT),
    PaginationDefaults.MAX_LIMIT
  );
  return { page, limit, skip: (page - 1) * limit };
}

/**
 * Build pagination metadata for response
 */
export function paginationMeta(page, limit, total) {
  const totalPages = Math.ceil(total / limit);
  return {
    page,
    limit,
    total,
    totalPages,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
}

/**
 * Parse sort string "-createdAt,name" → { createdAt: -1, name: 1 }
 */
export function parseSort(sortStr, allowedFields = []) {
  if (!sortStr) return { createdAt: -1 };

  const sort = {};
  const parts = sortStr.split(",").map((s) => s.trim());

  for (const part of parts) {
    const direction = part.startsWith("-") ? -1 : 1;
    const field = part.replace(/^[-+]/, "");
    if (allowedFields.length === 0 || allowedFields.includes(field)) {
      sort[field] = direction;
    }
  }

  return Object.keys(sort).length > 0 ? sort : { createdAt: -1 };
}

export default { parsePagination, paginationMeta, parseSort };
