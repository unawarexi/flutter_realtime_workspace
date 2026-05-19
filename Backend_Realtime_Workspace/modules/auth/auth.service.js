
// ============================================================================
// TeamSpot — Auth Service
// Email/password + social (Firebase) auth, JWT sessions, 2FA (TOTP/email/SMS)
// Password reset, email verification, session management
// ============================================================================

import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import speakeasy from "speakeasy";
import qrcode from "qrcode";
import admin from "firebase-admin";

import User from "../users/models/user.model.js";
import { env } from "../../config/env.config.js";
import { AppError, notFound, unauthorized, conflict, badRequest, forbidden } from "../../core/errors/app-error.js";
import { HttpStatus, ErrorCodes, RabbitQueues, CacheTTL } from "../../config/constants.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { createLogger } from "../../observability/logger.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";
import { generateInviteCode } from "../../core/utils/id-generator.js";
import { calculateProfileCompletion } from "../users/profile-completion.js";

const log = createLogger("AuthService");

// ── JWT helpers ───────────────────────────────────────────────────────────────
const ACCESS_EXPIRY  = env.JWT_EXPIRY || "15m";
const REFRESH_EXPIRY = "7d";
const REFRESH_TTL_S  = 7 * 24 * 3600; // 7 days in seconds

function signAccess(payload) {
  return jwt.sign(payload, env.JWT_SECRET, { expiresIn: ACCESS_EXPIRY, algorithm: "HS256" });
}

function signRefresh(payload) {
  return jwt.sign(payload, env.JWT_SECRET, { expiresIn: REFRESH_EXPIRY, algorithm: "HS256" });
}

// ── Redis session keys ────────────────────────────────────────────────────────
const sessionKey      = (userId, sessionId) => `session:${userId}:${sessionId}`;
const refreshKey      = (refreshToken)      => `refresh:${refreshToken}`;
const otpKey          = (type, userId)      => `otp:${type}:${userId}`;
const resetKey        = (token)             => `pwreset:${token}`;
const verifyKey       = (token)             => `emailverify:${token}`;
const twoFaTempKey    = (token)             => `2fatemp:${token}`;
const rateLimitKey    = (action, id)        => `ratelimit:${action}:${id}`;

// ── Redis helpers ─────────────────────────────────────────────────────────────
// All helpers guard against null client (Redis unavailable in dev / after
// failed connection). Reads return null/[], writes/deletes are no-ops so the
// server stays functional, but rate-limiting and session features degrade.

function redis() { return getRedisClient(); }

async function rGet(k) {
  const r = redis(); if (!r) return null;
  const v = await r.get(k); return v ? JSON.parse(v) : null;
}
async function rSet(k, v, ttl) {
  const r = redis(); if (!r) return;
  await r.set(k, JSON.stringify(v), "EX", ttl);
}
async function rDel(k) {
  const r = redis(); if (!r) return;
  await r.del(k);
}
async function rKeys(pattern) {
  const r = redis(); if (!r) return [];
  return r.keys(pattern);
}
async function rIncrEx(k, ttl) {
  const r = redis();
  if (!r) { log.warn("Redis unavailable — skipping rate-limit check", { key: k }); return 0; }
  const n = await r.incr(k);
  if (n === 1) await r.expire(k, ttl);
  return n;
}

// ── Email queue helper ────────────────────────────────────────────────────────
async function queueEmail(templateName, templateData, to) {
  await publishToQueue(RabbitQueues.EMAIL, {
    channel: "email",
    to,
    templateName,
    templateData,
  });
}

// ── Brute force guard ─────────────────────────────────────────────────────────
async function checkBruteForce(action, id, maxAttempts = 10, windowSec = 900) {
  const k = rateLimitKey(action, id);
  const count = await rIncrEx(k, windowSec);
  if (count > maxAttempts) throw new AppError("Too many attempts. Try again later.", HttpStatus.TOO_MANY_REQUESTS, ErrorCodes.RATE_LIMIT_EXCEEDED);
}

// ── Session helpers ───────────────────────────────────────────────────────────
async function createSession(user, deviceInfo = {}) {
  const sessionId    = crypto.randomUUID();
  const sessionData  = {
    userId: user._id.toString(),
    firebaseUid: user.firebaseUid,
    email: user.email,
    tenantId: user.tenantId?.toString(),
    role: user.permissionsLevel,
    deviceInfo,
    createdAt: Date.now(),
  };

  const accessToken  = signAccess({ sub: user._id.toString(), uid: user.firebaseUid || null, sid: sessionId, role: user.permissionsLevel, tenantId: user.tenantId?.toString() });
  const refreshToken = crypto.randomUUID(); // opaque, maps to session in Redis

  // Store refresh token → session mapping
  await rSet(refreshKey(refreshToken), { sessionId, userId: user._id.toString() }, REFRESH_TTL_S);
  // Store session data
  await rSet(sessionKey(user._id.toString(), sessionId), sessionData, REFRESH_TTL_S);

  return { accessToken, refreshToken, sessionId };
}

// ============================================================================
// REGISTER (email/password)
// ============================================================================
export async function register({ email, password, fullName, inviteCode, termsAccepted, timezone = "UTC", ip }) {
  // Rate limit registrations per IP
  await checkBruteForce("register", ip || email, 20, 3600);

  if (!termsAccepted) throw badRequest("You must accept the Terms of Service and Privacy Policy to register.");

  const existing = await User.findOne({ email }).lean();
  if (existing) throw conflict("An account with this email already exists");

  // Hash password
  const passwordHash = await bcrypt.hash(password, 12);

  const user = await User.create({
    email,
    passwordHash,
    fullName,
    displayName: fullName,
    timezone,
    status: "pending", // until email verified
    termsAcceptedAt: termsAccepted ? new Date() : undefined,
    inviteCode: generateInviteCode(),
    usedInviteCode: inviteCode,
    profileCompletion: 0,
  });

  // Generate email verification OTP (6 digits, 30 min)
  const otp    = crypto.randomInt(100000, 999999).toString();
  const vToken = crypto.randomBytes(32).toString("hex");
  await rSet(verifyKey(vToken), { userId: user._id.toString(), email, otp }, 1800);

  await queueEmail("emailVerification", {
    recipientName: fullName || email,
    verificationCode: otp,
    expiresIn: "30 minutes",
  }, email);

  eventBus.publish(DomainEvents.USER_REGISTERED, { userId: user._id, email });

  return { message: "Registration successful. Check your email to verify your account.", userId: user._id };
}

// ============================================================================
// VERIFY EMAIL
// ============================================================================
export async function verifyEmail({ token, otp }) {
  const data = await rGet(verifyKey(token));
  if (!data) throw badRequest("Verification link expired or invalid");
  if (data.otp !== otp) throw badRequest("Invalid OTP code");

  await User.findByIdAndUpdate(data.userId, { status: "active", "twoFactorSettings.emailVerified": true });
  await rDel(verifyKey(token));

  return { message: "Email verified. You can now log in." };
}

// ============================================================================
// RESEND VERIFICATION
// ============================================================================
export async function resendVerification({ email, ip }) {
  await checkBruteForce("resend", email, 5, 900);

  const user = await User.findOne({ email }).lean();
  if (!user || user.status === "active") return { message: "If this account exists, a verification email has been sent." };

  const otp    = crypto.randomInt(100000, 999999).toString();
  const vToken = crypto.randomBytes(32).toString("hex");
  await rSet(verifyKey(vToken), { userId: user._id.toString(), email, otp }, 1800);

  await queueEmail("emailVerification", { recipientName: user.fullName || email, verificationCode: otp, expiresIn: "30 minutes" }, email);

  return { message: "Verification email sent." };
}

// ============================================================================
// LOGIN (email/password)
// ============================================================================
export async function loginPassword({ email, password, deviceInfo = {}, ip }) {
  await checkBruteForce("login", email, 10, 900);

  const user = await User.findOne({ email }).select("+passwordHash").lean();
  if (!user || !user.passwordHash) throw unauthorized("Invalid credentials");

  if (user.status === "suspended")   throw new AppError("Account suspended", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_SUSPENDED);
  if (user.status === "deactivated") throw new AppError("Account deactivated", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_DEACTIVATED);
  if (user.status === "pending")     throw badRequest("Please verify your email first");

  // Check account lock
  if (user.lockedUntil && new Date() < new Date(user.lockedUntil)) {
    throw new AppError("Account temporarily locked. Try again later.", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_SUSPENDED);
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    // Track failed attempts
    const attempts = (user.failedLoginAttempts || 0) + 1;
    const update = { failedLoginAttempts: attempts };
    if (attempts >= 10) update.lockedUntil = new Date(Date.now() + 30 * 60_000); // 30 min lock
    await User.findByIdAndUpdate(user._id, update);
    throw unauthorized("Invalid credentials");
  }

  // Reset failed attempts
  await User.findByIdAndUpdate(user._id, { failedLoginAttempts: 0, lockedUntil: null, lastLoginAt: new Date(), lastLoginIp: ip, $inc: { loginCount: 1 } });

  // 2FA check
  if (user.totpEnabled || user.twoFactorSettings?.preferredMethod !== "email") {
    const tempToken = crypto.randomBytes(32).toString("hex");
    await rSet(twoFaTempKey(tempToken), { userId: user._id.toString(), method: user.twoFactorSettings?.preferredMethod || "totp" }, 600);
    return { requires2FA: true, tempToken, method: user.twoFactorSettings?.preferredMethod || "totp" };
  }

  eventBus.publish(DomainEvents.USER_LOGGED_IN, { userId: user._id, method: "password" });
  const tokens = await createSession(user, deviceInfo);
  return { ...tokens, user: sanitizeUser(user) };
}

// ============================================================================
// SOCIAL LOGIN (Firebase ID token)
// ============================================================================
export async function loginSocial({ idToken, inviteCode, deviceInfo = {} }) {
  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch {
    throw unauthorized("Invalid Firebase token");
  }

  let user = await User.findOne({ firebaseUid: decoded.uid });

  if (!user) {
    // Auto-create on first social login
    user = await User.create({
      firebaseUid: decoded.uid,
      email: decoded.email,
      fullName: decoded.name || decoded.email?.split("@")[0],
      displayName: decoded.name || null,
      profilePicture: decoded.picture || null,
      status: "active",
      "twoFactorSettings.emailVerified": decoded.email_verified || false,
      inviteCode: generateInviteCode(),
      usedInviteCode: inviteCode,
    });
    eventBus.publish(DomainEvents.USER_REGISTERED, { userId: user._id, method: "social" });
  }

  if (user.status === "suspended")   throw new AppError("Account suspended", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_SUSPENDED);
  if (user.status === "deactivated") throw new AppError("Account deactivated", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_DEACTIVATED);

  await User.findByIdAndUpdate(user._id, { lastLoginAt: new Date(), $inc: { loginCount: 1 } });
  eventBus.publish(DomainEvents.USER_LOGGED_IN, { userId: user._id, method: "social" });

  const tokens = await createSession(user, deviceInfo);
  return { ...tokens, user: sanitizeUser(user.toObject ? user.toObject() : user) };
}

// ============================================================================
// REFRESH TOKEN
// ============================================================================
export async function refreshToken({ refreshToken: rt }) {
  const mapping = await rGet(refreshKey(rt));
  if (!mapping) throw unauthorized("Invalid or expired refresh token");

  const session = await rGet(sessionKey(mapping.userId, mapping.sessionId));
  if (!session) throw unauthorized("Session expired");

  const user = await User.findById(mapping.userId).lean();
  if (!user || user.status !== "active") throw unauthorized("User not found or inactive");

  const newAccessToken = signAccess({ sub: user._id.toString(), uid: user.firebaseUid || null, sid: mapping.sessionId, role: user.permissionsLevel, tenantId: user.tenantId?.toString() });

  return { accessToken: newAccessToken };
}

// ============================================================================
// LOGOUT
// ============================================================================
export async function logout({ userId, refreshToken: rt, sessionId }) {
  if (rt) await rDel(refreshKey(rt));
  if (sessionId && userId) await rDel(sessionKey(userId, sessionId));
  eventBus.publish(DomainEvents.USER_LOGGED_OUT, { userId });
  return { message: "Logged out successfully" };
}

// ============================================================================
// LOGOUT ALL DEVICES
// ============================================================================
export async function logoutAll({ userId }) {
  const r = await redis();
  const keys = await r.keys(`session:${userId}:*`);
  const rtKeys = await r.keys(`refresh:*`);
  // Scan refresh keys to find this user's sessions
  for (const k of rtKeys) {
    const d = await rGet(k);
    if (d?.userId === userId) await rDel(k);
  }
  if (keys.length) await r.del(...keys);
  eventBus.publish(DomainEvents.USER_LOGGED_OUT, { userId, allDevices: true });
  return { message: "Logged out from all devices" };
}

// ============================================================================
// SESSIONS
// ============================================================================
export async function getSessions({ userId }) {
  const r = await redis();
  const keys = await r.keys(`session:${userId}:*`);
  const sessions = [];
  for (const k of keys) {
    const s = await rGet(k);
    if (s) sessions.push({ sessionId: k.split(":")[2], ...s, passwordHash: undefined });
  }
  return sessions;
}

export async function revokeSession({ userId, sessionId }) {
  await rDel(sessionKey(userId, sessionId));
  // Also remove the refresh token that maps to this session
  const r = await redis();
  const rtKeys = await r.keys("refresh:*");
  for (const k of rtKeys) {
    const d = await rGet(k);
    if (d?.sessionId === sessionId) { await rDel(k); break; }
  }
  return { message: "Session revoked" };
}

// ============================================================================
// FORGOT PASSWORD
// ============================================================================
export async function forgotPassword({ email, ip }) {
  await checkBruteForce("forgot", email, 5, 3600);

  const user = await User.findOne({ email }).lean();
  // Always respond OK to prevent email enumeration
  if (!user) return { message: "If this email exists, a reset link has been sent." };

  const token  = crypto.randomBytes(32).toString("hex");
  await rSet(resetKey(token), { userId: user._id.toString(), email }, 1800); // 30 min

  await queueEmail("forgotPassword", {
    recipientName: user.fullName || email,
    resetToken: token,
    resetUrl: `${env.FRONTEND_URL}/reset-password?token=${token}`,
    expiresIn: "30 minutes",
  }, email);

  return { message: "If this email exists, a reset link has been sent." };
}

// ============================================================================
// RESET PASSWORD
// ============================================================================
export async function resetPassword({ token, password }) {
  const data = await rGet(resetKey(token));
  if (!data) throw badRequest("Reset token expired or invalid");

  const hash = await bcrypt.hash(password, 12);
  await User.findByIdAndUpdate(data.userId, { passwordHash: hash, failedLoginAttempts: 0, lockedUntil: null });
  await rDel(resetKey(token));

  // Invalidate all sessions
  await logoutAll({ userId: data.userId });

  await queueEmail("passwordChanged", { recipientName: data.email }, data.email);
  return { message: "Password reset successfully. Please log in." };
}

// ============================================================================
// CHANGE PASSWORD (authenticated)
// ============================================================================
export async function changePassword({ userId, currentPassword, newPassword }) {
  const user = await User.findById(userId).select("+passwordHash").lean();
  if (!user) throw notFound("User");

  if (user.passwordHash) {
    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) throw unauthorized("Current password is incorrect");
  }

  const hash = await bcrypt.hash(newPassword, 12);
  await User.findByIdAndUpdate(userId, { passwordHash: hash });
  await logoutAll({ userId });

  await queueEmail("passwordChanged", { recipientName: user.fullName || user.email }, user.email);
  return { message: "Password changed. Please log in again." };
}

// ============================================================================
// 2FA — TOTP
// ============================================================================
export async function setupTotp({ userId }) {
  const user = await User.findById(userId).lean();
  if (!user) throw notFound("User");
  if (user.totpEnabled) throw conflict("TOTP is already enabled");

  const secret = speakeasy.generateSecret({
    name: `TeamSpot (${user.email})`,
    issuer: "TeamSpot",
    length: 32,
  });

  // Store pending secret in Redis (10 min to confirm)
  await rSet(`totp:setup:${userId}`, { secret: secret.base32 }, 600);

  const qrCode = await qrcode.toDataURL(secret.otpauth_url);
  return { secret: secret.base32, qrCode, otpauthUrl: secret.otpauth_url };
}

export async function confirmTotp({ userId, token }) {
  const setup = await rGet(`totp:setup:${userId}`);
  if (!setup) throw badRequest("TOTP setup session expired. Start setup again.");

  const valid = speakeasy.totp.verify({ secret: setup.secret, encoding: "base32", token, window: 2 });
  if (!valid) throw badRequest("Invalid TOTP code");

  const backupCodes = Array.from({ length: 8 }, () => crypto.randomBytes(4).toString("hex"));
  const hashedCodes = await Promise.all(backupCodes.map(c => bcrypt.hash(c, 10)));

  await User.findByIdAndUpdate(userId, {
    totpSecret: setup.secret,
    totpEnabled: true,
    totpSetupAt: new Date(),
    backupCodes: hashedCodes.map(code => ({ code, used: false })),
    "twoFactorSettings.preferredMethod": "totp",
  });
  await rDel(`totp:setup:${userId}`);

  eventBus.publish(DomainEvents.USER_2FA_ENABLED, { userId, method: "totp" });
  return { message: "TOTP enabled successfully", backupCodes };
}

export async function verifyTotp({ tempToken, token }) {
  const temp = await rGet(twoFaTempKey(tempToken));
  if (!temp) throw unauthorized("Challenge expired. Log in again.");

  const user = await User.findById(temp.userId).select("+totpSecret").lean();
  if (!user) throw notFound("User");

  const valid = speakeasy.totp.verify({ secret: user.totpSecret, encoding: "base32", token, window: 2 });
  if (!valid) {
    // Check backup codes
    let backupValid = false;
    for (const bc of user.backupCodes || []) {
      if (!bc.used && await bcrypt.compare(token, bc.code)) {
        backupValid = true;
        await User.updateOne({ _id: user._id, "backupCodes.code": bc.code }, { $set: { "backupCodes.$.used": true, "backupCodes.$.usedAt": new Date() } });
        break;
      }
    }
    if (!backupValid) throw unauthorized("Invalid TOTP code");
  }

  await rDel(twoFaTempKey(tempToken));
  const tokens = await createSession(user);
  eventBus.publish(DomainEvents.USER_2FA_VERIFIED, { userId: user._id, method: "totp" });
  return { ...tokens, user: sanitizeUser(user) };
}

export async function disableTotp({ userId, token }) {
  const user = await User.findById(userId).select("+totpSecret").lean();
  if (!user || !user.totpEnabled) throw badRequest("TOTP is not enabled");

  const valid = speakeasy.totp.verify({ secret: user.totpSecret, encoding: "base32", token, window: 2 });
  if (!valid) throw unauthorized("Invalid TOTP code");

  await User.findByIdAndUpdate(userId, { totpEnabled: false, totpSecret: null, totpDisabledAt: new Date(), backupCodes: [] });
  return { message: "TOTP disabled" };
}

// ============================================================================
// 2FA — EMAIL OTP
// ============================================================================
export async function sendEmail2FA({ userId }) {
  await checkBruteForce("otp_email", userId, 5, 300);

  const user = await User.findById(userId).lean();
  if (!user) throw notFound("User");

  const otp = crypto.randomInt(100000, 999999).toString();
  await rSet(otpKey("email2fa", userId), { otp, attempts: 0 }, 300);

  await queueEmail("twoFACode", { recipientName: user.fullName || user.email, code: otp, expiresIn: "5 minutes", method: "Email" }, user.email);
  return { message: "OTP sent to your email" };
}

export async function verifyEmail2FA({ userId, otp, tempToken }) {
  // Support both authenticated (userId) and pre-auth (tempToken) flows
  let uid = userId;
  if (tempToken && !uid) {
    const temp = await rGet(twoFaTempKey(tempToken));
    if (!temp) throw unauthorized("Challenge expired");
    uid = temp.userId;
  }

  const stored = await rGet(otpKey("email2fa", uid));
  if (!stored) throw badRequest("OTP expired. Request a new one.");

  stored.attempts = (stored.attempts || 0) + 1;
  if (stored.attempts > 5) { await rDel(otpKey("email2fa", uid)); throw badRequest("Too many failed attempts"); }
  await rSet(otpKey("email2fa", uid), stored, 300);

  if (stored.otp !== otp) throw badRequest("Invalid OTP");

  await rDel(otpKey("email2fa", uid));
  if (tempToken) await rDel(twoFaTempKey(tempToken));

  const user = await User.findById(uid).lean();
  const tokens = await createSession(user);
  eventBus.publish(DomainEvents.USER_2FA_VERIFIED, { userId: uid, method: "email" });
  return { ...tokens, user: sanitizeUser(user) };
}

// ============================================================================
// 2FA — SMS OTP
// ============================================================================
export async function sendSms2FA({ userId, phoneNumber }) {
  await checkBruteForce("otp_sms", userId, 5, 300);

  const otp = crypto.randomInt(100000, 999999).toString();
  await rSet(otpKey("sms2fa", userId), { otp, phoneNumber, attempts: 0 }, 300);

  // SMS is dispatched via notification worker — currently via push/email fallback
  await publishToQueue(RabbitQueues.NOTIFICATION, {
    channel: "sms",
    to: phoneNumber,
    text: `Your TeamSpot verification code is: ${otp}. Expires in 5 minutes.`,
    userId,
  });

  return { message: "SMS OTP sent" };
}

export async function verifySms2FA({ userId, otp, tempToken }) {
  let uid = userId;
  if (tempToken && !uid) {
    const temp = await rGet(twoFaTempKey(tempToken));
    if (!temp) throw unauthorized("Challenge expired");
    uid = temp.userId;
  }

  const stored = await rGet(otpKey("sms2fa", uid));
  if (!stored) throw badRequest("OTP expired");

  stored.attempts = (stored.attempts || 0) + 1;
  if (stored.attempts > 5) { await rDel(otpKey("sms2fa", uid)); throw badRequest("Too many attempts"); }
  await rSet(otpKey("sms2fa", uid), stored, 300);

  if (stored.otp !== otp) throw badRequest("Invalid OTP");

  await rDel(otpKey("sms2fa", uid));
  if (tempToken) await rDel(twoFaTempKey(tempToken));

  const user = await User.findById(uid).lean();
  const tokens = await createSession(user);
  eventBus.publish(DomainEvents.USER_2FA_VERIFIED, { userId: uid, method: "sms" });
  return { ...tokens, user: sanitizeUser(user) };
}

// ============================================================================
// 2FA STATUS
// ============================================================================
export async function get2FAStatus({ userId }) {
  const user = await User.findById(userId).lean();
  if (!user) throw notFound("User");
  return {
    totpEnabled: user.totpEnabled || false,
    preferredMethod: user.twoFactorSettings?.preferredMethod || "email",
    emailVerified: user.twoFactorSettings?.emailVerified || false,
    phoneVerified: user.twoFactorSettings?.phoneVerified || false,
    backupCodesRemaining: (user.backupCodes || []).filter(c => !c.used).length,
  };
}

// ── Sanitize user for response (strip secrets) ────────────────────────────────
function sanitizeUser(user) {
  const { passwordHash, totpSecret, backupCodes, ...safe } = user;
  return safe;
}

export default {
  register, verifyEmail, resendVerification,
  loginPassword, loginSocial,
  refreshToken, logout, logoutAll,
  getSessions, revokeSession,
  forgotPassword, resetPassword, changePassword,
  setupTotp, confirmTotp, verifyTotp, disableTotp,
  sendEmail2FA, verifyEmail2FA,
  sendSms2FA, verifySms2FA,
  get2FAStatus,
};
