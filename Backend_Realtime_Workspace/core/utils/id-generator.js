// ============================================================================
// TeamSpot — ID Generator
// ULID-style sortable unique IDs and short codes
// ============================================================================

import { randomUUID, randomBytes } from "crypto";

/**
 * Generate a UUID v4
 */
export function uuid() {
  return randomUUID();
}

/**
 * Generate a short alphanumeric code (e.g., invite codes, meeting codes)
 * @param {number} length
 */
export function shortCode(length = 8) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // No I, O, 0, 1
  let code = "";
  const bytes = randomBytes(length);
  for (let i = 0; i < length; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

/**
 * Generate a project key like "PROJ-001"
 * @param {string} prefix
 * @param {number} sequence
 */
export function projectKey(prefix = "PROJ", sequence = 1) {
  return `${prefix}-${String(sequence).padStart(3, "0")}`;
}

/**
 * Generate a meeting code like "xxx-xxxx-xxx"
 */
export function meetingCode() {
  const seg = (len) => {
    const chars = "abcdefghijklmnopqrstuvwxyz";
    const bytes = randomBytes(len);
    return Array.from(bytes).map((b) => chars[b % chars.length]).join("");
  };
  return `${seg(3)}-${seg(4)}-${seg(3)}`;
}

/**
 * Generate a prefixed ID like "org_abc123"
 */
export function prefixedId(prefix) {
  return `${prefix}_${randomBytes(12).toString("hex")}`;
}

/**
 * Generate an invite code (12-char uppercase alphanumeric)
 */
export function generateInviteCode() {
  return shortCode(12);
}

export default { uuid, shortCode, projectKey, meetingCode, prefixedId, generateInviteCode };
