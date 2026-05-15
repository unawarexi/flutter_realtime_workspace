// ============================================================================
// TeamSpot — Referral / Invite Code Service
// Organization invite code generation, validation, and usage
// ============================================================================

import crypto from "crypto";
import { shortCode } from "../../core/utils/id-generator.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("Referral");

// ============================================================================
// CODE GENERATION
// ============================================================================

/** Generate a referral code using the shared id-generator utility */
export function generateReferralCode() {
  return shortCode(8);
}

/** Set expiry for 7 days from now */
export function getExpiryDate(days = 7) {
  const expiry = new Date();
  expiry.setDate(expiry.getDate() + days);
  return expiry;
}

// ============================================================================
// ASSIGN / VALIDATE / USE
// ============================================================================

/**
 * Assign a referral code to a user.
 * @param {Object} user — Mongoose user document
 * @param {Object} options — { ignorePermissions: boolean }
 */
export async function assignReferralCode(user, options = {}) {
  const role = user.permissionsLevel;

  if (!options.ignorePermissions) {
    if (user.invitePermissions && user.invitePermissions[role] === false) {
      throw new Error("You do not have permission to generate invite codes.");
    }
  }

  const code = generateReferralCode();
  user.inviteCode = code;
  user.inviteCodeExpiry = getExpiryDate();
  await user.save();

  log.info("Referral code assigned", { userId: user._id, code });
  return code;
}

/**
 * Validate a referral code.
 * @param {string} code
 * @param {Object} UserModel — Mongoose User model
 */
export async function validateReferralCode(code, UserModel) {
  const user = await UserModel.findOne({ inviteCode: code });
  if (!user) return { valid: false, reason: "Code not found" };

  if (user.inviteCodeExpiry && user.inviteCodeExpiry < new Date()) {
    try {
      await assignReferralCode(user, { ignorePermissions: true });
      return { valid: false, reason: "Code expired, regenerated", regenerated: user.inviteCode };
    } catch (err) {
      return { valid: false, reason: "Code expired", error: err.message };
    }
  }

  return { valid: true, owner: user };
}

/**
 * Use a referral code when a new user joins.
 * @param {Object} params — { memberUser, code, UserModel }
 */
export async function useReferralCode({ memberUser, code, UserModel }) {
  const validation = await validateReferralCode(code, UserModel);
  if (!validation.valid) {
    return { success: false, reason: validation.reason, regenerated: validation.regenerated };
  }

  const owner = validation.owner;

  // Initialize arrays if missing
  if (!Array.isArray(memberUser.invitedBy)) memberUser.invitedBy = [];
  if (!Array.isArray(owner.referredTo)) owner.referredTo = [];

  // Prevent duplicates
  const alreadyInvitedBy = memberUser.invitedBy.some((i) => i.inviterCode === code);
  if (!alreadyInvitedBy) {
    memberUser.invitedBy.push({
      email: owner.email,
      name: owner.fullName || owner.displayName || owner.email,
      inviterCode: code,
    });
  }

  const alreadyReferred = owner.referredTo.some((r) => r.email === memberUser.email);
  if (!alreadyReferred) {
    owner.referredTo.push({
      email: memberUser.email,
      name: memberUser.fullName || memberUser.displayName || memberUser.email,
    });
  }

  // Inherit company name
  if (owner.companyName && !memberUser.companyName) {
    memberUser.companyName = owner.companyName;
  }

  // Generate code for new member
  try {
    await assignReferralCode(memberUser, { ignorePermissions: true });
  } catch { /* continue */ }

  await Promise.all([memberUser.save(), owner.save()]);

  log.info("Referral code used", { member: memberUser.email, owner: owner.email });
  return { success: true, owner, newMemberCode: memberUser.inviteCode };
}

/** Revoke a referral code */
export async function revokeReferralCode(user) {
  user.inviteCode = null;
  user.inviteCodeExpiry = null;
  await user.save();
  log.info("Referral code revoked", { userId: user._id });
}

/** Get referral stats for a user */
export async function getReferralStats(userId, UserModel) {
  const user = await UserModel.findById(userId);
  if (!user) return null;

  return {
    userEmail: user.email,
    inviteCode: user.inviteCode,
    inviteCodeExpiry: user.inviteCodeExpiry,
    directReferrals: user.referredTo?.length || 0,
    invitedBy: user.invitedBy || [],
    referredTo: user.referredTo || [],
  };
}

export default {
  generateReferralCode,
  getExpiryDate,
  assignReferralCode,
  validateReferralCode,
  useReferralCode,
  revokeReferralCode,
  getReferralStats,
};
