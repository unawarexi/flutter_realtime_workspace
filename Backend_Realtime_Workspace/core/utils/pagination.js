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

// ── Cursor Pagination Helpers ────────────────────────────────────────────────
// Used by BaseRepository.cursorPaginate() for infinite-scroll / real-time feeds.
// Avoids O(n) SKIP cost of offset pagination at high page numbers.

/**
 * Encode a cursor object as a URL-safe base64 string.
 * @param {{ id: string, sortValue: * }} cursorObj
 * @returns {string}
 */
export function encodeCursor(cursorObj) {
  return Buffer.from(JSON.stringify(cursorObj)).toString("base64url");
}

/**
 * Decode a cursor string back to its object form.
 * @param {string} cursor — base64url encoded
 * @returns {{ id: string, sortValue: * } | null}
 */
export function decodeCursor(cursor) {
  try {
    return JSON.parse(Buffer.from(cursor, "base64url").toString());
  } catch {
    return null;
  }
}

/**
 * Build a MongoDB filter that continues from a cursor position.
 * Compound cursor prevents duplicates on ties (sort field value collision).
 *
 * Complexity: O(log n) with compound index on (tenantId, sortField, _id)
 * vs O(n) for SKIP at high offsets.
 *
 * @param {Object} baseFilter — existing query filter
 * @param {{ id: string, sortValue: * } | null} cursor
 * @param {string} [sortField="createdAt"]
 * @param {1|-1}   [sortDir=-1]
 * @returns {Object} MongoDB filter
 */
export function buildCursorFilter(baseFilter, cursor, sortField = "createdAt", sortDir = -1) {
  if (!cursor) return baseFilter;
  const op = sortDir === -1 ? "$lt" : "$gt";
  return {
    ...baseFilter,
    $or: [
      { [sortField]: { [op]: cursor.sortValue } },
      { [sortField]: cursor.sortValue, _id: { [op]: cursor.id } },
    ],
  };
}

export default { parsePagination, paginationMeta, parseSort, encodeCursor, decodeCursor, buildCursorFilter };
