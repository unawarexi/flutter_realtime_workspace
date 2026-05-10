// ============================================================================
// TeamSpot — Auth Service
// Dual-path: Email/Password (bcryptjs + JWT) + Social (Firebase ID token → JWT)
// Features: refresh tokens, session management, 2FA (TOTP + email OTP + SMS OTP),
//           email verification OTP, forgot/reset password, device tracking
// ============================================================================

import bcryptjs from "bcryptjs";
import jwt from "jsonwebtoken";
import speakeasy from "speakeasy";
import qrcode from "qrcode";
import crypto from "crypto";
import { v4 as uuidv4 } from "uuid";
import admin from "firebase-admin";

import User from "../users/models/user.model.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { createLogger } from "../../observability/logger.js";
import { env } from "../../config/env.config.js";
import { AppError, badRequest, unauthorized, notFound, conflict, forbidden } from "../../core/errors/app-error.js";
import { HttpStatus, ErrorCodes } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { calculateProfileCompletion } from "../users/profile-completion.js";

const log = createLogger("AuthService");

// ─── Constants ───────────────────────────────────────────────────────────────
const BCRYPT_ROUNDS = 12;
const ACCESS_TOKEN_TTL = "15m";
const REFRESH_TOKEN_TTL_S = 60 * 60 * 24 * 30; // 30 days in seconds
const EMAIL_OTP_TTL_S = 300;   // 5 min
const SMS_OTP_TTL_S   = 300;
const VERIFY_OTP_TTL_S = 600;  // 10 min for email verification
const RESET_OTP_TTL_S  = 900;  // 15 min for password reset
const MAX_SESSIONS_PER_USER = 5;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function generateSecureOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

function generateAccessToken(user) {
  return jwt.sign(
    {
      sub: user._id.toString(),
      uid: user.firebaseUid || null,
      email: user.email,
      tenantId: user.tenantId?.toString() || null,
      orgId: user.orgId?.toString() || null,
      role: user.permissionsLevel,
    },
    env.JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_TTL, issuer: "teamspot", audience: "teamspot-api" }
  );
}

function verifyAccessToken(token) {
  return jwt.verify(token, env.JWT_SECRET, {
    issuer: "teamspot",
    audience: "teamspot-api",
  });
}

function getRedis() {
  return getRedisClient();
}

// ─── Redis key namespaces ─────────────────────────────────────────────────────
const K = {
  refreshToken:  (id)    => `auth:rt:${id}`,
  sessions:      (uid)   => `auth:sessions:${uid}`,
  emailOtp:      (uid)   => `auth:2fa:email:${uid}`,
  smsOtp:        (uid)   => `auth:2fa:sms:${uid}`,
  verifyOtp:     (email) => `auth:verify:${email}`,
  resetOtp:      (email) => `auth:reset:${email}`,
  blacklist:     (jti)   => `auth:bl:${jti}`,
  loginAttempts: (email) => `auth:attempts:${email}`,
};

// ─── Session helpers ──────────────────────────────────────────────────────────

async function createSession(userId, deviceInfo = {}) {
  const redis = getRedis();
  const sessionId = uuidv4();
  const sessionData = {
    sessionId,
    userId,
    deviceName: deviceInfo.deviceName || "Unknown Device",
    userAgent: deviceInfo.userAgent || "",
    ip: deviceInfo.ip || "",
    createdAt: Date.now(),
    lastUsed: Date.now(),
  };

  // Store refresh token mapped to session
  const refreshToken = uuidv4();
  await redis.set(
    K.refreshToken(refreshToken),
    JSON.stringify({ ...sessionData, refreshToken }),
    "EX",
    REFRESH_TOKEN_TTL_S
  );

  // Track sessions per user (capped at MAX_SESSIONS_PER_USER)
  const sessionsKey = K.sessions(userId);
  await redis.lpush(sessionsKey, JSON.stringify({ sessionId, refreshToken, ...sessionData }));
  await redis.ltrim(sessionsKey, 0, MAX_SESSIONS_PER_USER - 1);
  await redis.expire(sessionsKey, REFRESH_TOKEN_TTL_S);

  return { refreshToken, sessionId };
}

async function revokeRefreshToken(refreshToken) {
  const redis = getRedis();
  const raw = await redis.get(K.refreshToken(refreshToken));
  if (!raw) return false;

  const session = JSON.parse(raw);

  // Remove from sessions list
  const sessionsKey = K.sessions(session.userId);
  const sessions = await redis.lrange(sessionsKey, 0, -1);
  for (const s of sessions) {
    const parsed = JSON.parse(s);
    if (parsed.refreshToken === refreshToken) {
      await redis.lrem(sessionsKey, 0, s);
      break;
    }
  }

  await redis.del(K.refreshToken(refreshToken));
  return true;
}

async function revokeAllSessions(userId) {
  const redis = getRedis();
  const sessions = await redis.lrange(K.sessions(userId), 0, -1);
  const pipeline = redis.pipeline();
  for (const s of sessions) {
    const { refreshToken } = JSON.parse(s);
    pipeline.del(K.refreshToken(refreshToken));
  }
  pipeline.del(K.sessions(userId));
  await pipeline.exec();
}

// ─── Login brute-force protection ────────────────────────────────────────────

async function checkLoginAttempts(email) {
  const redis = getRedis();
  const key = K.loginAttempts(email);
  const count = await redis.get(key);
  if (count && parseInt(count) >= 10) {
    const ttl = await redis.ttl(key);
    throw new AppError(
      `Account temporarily locked. Try again in ${Math.ceil(ttl / 60)} minutes.`,
      HttpStatus.TOO_MANY_REQUESTS,
      ErrorCodes.RATE_LIMIT_EXCEEDED
    );
  }
}

async function recordFailedLogin(email) {
  const redis = getRedis();
  const key = K.loginAttempts(email);
  const count = await redis.incr(key);
  if (count === 1) await redis.expire(key, 900); // 15 min window
}

async function clearLoginAttempts(email) {
  await getRedis().del(K.loginAttempts(email));
}

// ─── Email helpers ────────────────────────────────────────────────────────────

async function sendOtpEmail(email, otp, subject, purpose) {
  await publishToQueue("teamspot.email.send", {
    channel: "email",
    to: email,
    templateName: "otpCode",
    templateData: {
      subject,
      purpose,
      otp,
      expiryMinutes: purpose === "email verification" ? 10 : 5
    }
  });
}

// ============================================================================
// AUTH SERVICE
// ============================================================================

export class AuthService {
  // ── 1. Email/Password Registration ────────────────────────────────────────
  static async register({ email, password, fullName, inviteCode, deviceInfo }) {
    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) throw conflict("An account with this email already exists");

    const passwordHash = await bcryptjs.hash(password, BCRYPT_ROUNDS);

    const user = await User.create({
      email: email.toLowerCase().trim(),
      fullName: fullName?.trim(),
      displayName: fullName?.trim() || email.split("@")[0],
      passwordHash,
      authProvider: "email",
      status: "pending", // pending until email verified
      emailVerified: false,
      profileCompletion: 0,
      inviteCode: inviteCode || null,
    });

    // Send verification OTP
    const otp = generateSecureOTP();
    await getRedis().set(K.verifyOtp(user.email), JSON.stringify({ otp, userId: user._id.toString(), attempts: 0 }), "EX", VERIFY_OTP_TTL_S);
    await sendOtpEmail(user.email, otp, "Verify your TeamSpot email", "email verification");

    log.info("User registered", { userId: user._id, email: user.email });

    await publishEvent("teamspot.user.events", user._id.toString(), {
      type: "user.registered",
      userId: user._id,
      email: user.email,
      timestamp: new Date().toISOString(),
    });

    return {
      message: "Account created. Please check your email for a verification code.",
      email: user.email,
      userId: user._id,
    };
  }

  // ── 2. Verify Email (OTP) ─────────────────────────────────────────────────
  static async verifyEmail({ email, otp, deviceInfo }) {
    const redis = getRedis();
    const raw = await redis.get(K.verifyOtp(email.toLowerCase().trim()));
    if (!raw) throw badRequest("Verification code expired or not found. Please request a new one.");

    const data = JSON.parse(raw);

    if (data.attempts >= 5) {
      await redis.del(K.verifyOtp(email.toLowerCase().trim()));
      throw badRequest("Too many failed attempts. Please request a new verification code.");
    }

    if (data.otp !== otp.trim()) {
      data.attempts += 1;
      await redis.set(K.verifyOtp(email.toLowerCase().trim()), JSON.stringify(data), "KEEPTTL");
      throw badRequest("Invalid verification code.");
    }

    // Mark verified
    const user = await User.findByIdAndUpdate(
      data.userId,
      { emailVerified: true, status: "active", $set: { "twoFactorSettings.emailVerified": true } },
      { new: true }
    );
    if (!user) throw notFound("User");

    await redis.del(K.verifyOtp(email.toLowerCase().trim()));

    // Issue tokens
    const accessToken = generateAccessToken(user);
    const { refreshToken, sessionId } = await createSession(user._id.toString(), deviceInfo);

    log.info("Email verified", { userId: user._id });

    return { accessToken, refreshToken, sessionId, user: AuthService._safeUser(user) };
  }

  // ── 3. Resend Email Verification ──────────────────────────────────────────
  static async resendVerification({ email }) {
    const redis = getRedis();
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) throw notFound("User");
    if (user.emailVerified) throw badRequest("Email already verified.");

    // Rate-limit resends
    const existing = await redis.get(K.verifyOtp(user.email));
    if (existing) {
      const ttl = await redis.ttl(K.verifyOtp(user.email));
      if (ttl > 540) throw badRequest(`Please wait before requesting another code (${Math.ceil((ttl - 540) / 60)} min)`);
    }

    const otp = generateSecureOTP();
    await redis.set(K.verifyOtp(user.email), JSON.stringify({ otp, userId: user._id.toString(), attempts: 0 }), "EX", VERIFY_OTP_TTL_S);
    await sendOtpEmail(user.email, otp, "Verify your TeamSpot email", "email verification");

    return { message: "Verification code resent. Please check your email." };
  }

  // ── 4. Email/Password Login ───────────────────────────────────────────────
  static async loginWithPassword({ email, password, deviceInfo }) {
    await checkLoginAttempts(email);

    const user = await User.findOne({ email: email.toLowerCase().trim() }).select("+passwordHash");
    if (!user || !user.passwordHash) {
      await recordFailedLogin(email);
      throw unauthorized("Invalid email or password.");
    }

    if (user.authProvider && user.authProvider !== "email") {
      throw badRequest(`This account uses ${user.authProvider} sign-in. Please use that method.`);
    }

    if (user.status === "suspended") {
      throw new AppError("Account suspended. Contact support.", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_SUSPENDED);
    }

    if (user.status === "deactivated") {
      throw new AppError("Account deactivated.", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_DEACTIVATED);
    }

    const valid = await bcryptjs.compare(password, user.passwordHash);
    if (!valid) {
      await recordFailedLogin(email);
      throw unauthorized("Invalid email or password.");
    }

    if (!user.emailVerified) {
      throw new AppError(
        "Email not verified. Please check your inbox for a verification code.",
        HttpStatus.FORBIDDEN,
        ErrorCodes.FORBIDDEN
      );
    }

    await clearLoginAttempts(email);

    // Update last login
    await User.findByIdAndUpdate(user._id, {
      lastLoginAt: new Date(),
      lastLoginIp: deviceInfo?.ip || "",
      $inc: { loginCount: 1 },
    });

    // If 2FA enabled, issue a short-lived challenge token instead of full access
    if (user.totpEnabled || user.twoFactorSettings?.preferredMethod !== "totp") {
      if (user.totpEnabled) {
        // Return 2FA challenge — client must complete TOTP verification
        const challengeToken = jwt.sign(
          { sub: user._id.toString(), purpose: "2fa_challenge" },
          env.JWT_SECRET,
          { expiresIn: "5m" }
        );
        return { requires2FA: true, method: "totp", challengeToken };
      }
    }

    const accessToken = generateAccessToken(user);
    const { refreshToken, sessionId } = await createSession(user._id.toString(), deviceInfo);

    log.info("User logged in (password)", { userId: user._id });

    return { accessToken, refreshToken, sessionId, user: AuthService._safeUser(user) };
  }

  // ── 5. Social Auth (Firebase token → JWT) ────────────────────────────────
  static async loginWithSocial({ idToken, inviteCode, deviceInfo }) {
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      log.warn("Firebase token verification failed", { error: err.message });
      throw unauthorized("Invalid or expired social auth token.");
    }

    const { uid, email, name, picture, firebase } = decoded;
    const provider = firebase?.sign_in_provider || "unknown";

    let user = await User.findOne({ $or: [{ firebaseUid: uid }, { email: email?.toLowerCase() }] });

    if (!user) {
      // Auto-create on first social login
      user = await User.create({
        firebaseUid: uid,
        email: email?.toLowerCase(),
        fullName: name || email?.split("@")[0],
        displayName: name || email?.split("@")[0],
        profilePicture: picture || null,
        authProvider: provider,
        emailVerified: true,
        status: "active",
        inviteCode: inviteCode || null,
        profileCompletion: calculateProfileCompletion({ email, fullName: name }),
      });

      await publishEvent("teamspot.user.events", user._id.toString(), {
        type: "user.registered",
        userId: user._id,
        email: user.email,
        provider,
        timestamp: new Date().toISOString(),
      });
    } else if (!user.firebaseUid) {
      // Link Firebase UID to existing email account
      await User.findByIdAndUpdate(user._id, { firebaseUid: uid, authProvider: provider, emailVerified: true });
      user.firebaseUid = uid;
    }

    if (user.status === "suspended") {
      throw new AppError("Account suspended.", HttpStatus.FORBIDDEN, ErrorCodes.ACCOUNT_SUSPENDED);
    }

    await User.findByIdAndUpdate(user._id, {
      lastLoginAt: new Date(),
      lastLoginIp: deviceInfo?.ip || "",
      $inc: { loginCount: 1 },
    });

    const accessToken = generateAccessToken(user);
    const { refreshToken, sessionId } = await createSession(user._id.toString(), deviceInfo);

    log.info("User logged in (social)", { userId: user._id, provider });

    return { accessToken, refreshToken, sessionId, user: AuthService._safeUser(user) };
  }

  // ── 6. Refresh Access Token ───────────────────────────────────────────────
  static async refreshToken({ refreshToken, deviceInfo }) {
    const redis = getRedis();
    const raw = await redis.get(K.refreshToken(refreshToken));
    if (!raw) throw unauthorized("Refresh token invalid or expired. Please log in again.");

    const session = JSON.parse(raw);

    const user = await User.findById(session.userId);
    if (!user) throw notFound("User");

    if (user.status === "suspended" || user.status === "deactivated") {
      await revokeRefreshToken(refreshToken);
      throw unauthorized("Account inactive.");
    }

    // Rotate refresh token
    await revokeRefreshToken(refreshToken);
    const { refreshToken: newRefreshToken, sessionId } = await createSession(user._id.toString(), {
      ...deviceInfo,
      deviceName: session.deviceName,
    });

    // Update lastUsed
    const newRaw = await redis.get(K.refreshToken(newRefreshToken));
    if (newRaw) {
      const newSession = JSON.parse(newRaw);
      newSession.lastUsed = Date.now();
      await redis.set(K.refreshToken(newRefreshToken), JSON.stringify(newSession), "KEEPTTL");
    }

    const accessToken = generateAccessToken(user);

    return { accessToken, refreshToken: newRefreshToken, sessionId };
  }

  // ── 7. Logout ─────────────────────────────────────────────────────────────
  static async logout({ refreshToken }) {
    await revokeRefreshToken(refreshToken);
    return { message: "Logged out successfully." };
  }

  // ── 8. Logout All Sessions ────────────────────────────────────────────────
  static async logoutAll({ userId }) {
    await revokeAllSessions(userId);
    return { message: "All sessions revoked." };
  }

  // ── 9. Get Active Sessions ────────────────────────────────────────────────
  static async getSessions({ userId }) {
    const redis = getRedis();
    const raw = await redis.lrange(K.sessions(userId), 0, -1);
    return raw.map((s) => {
      const { refreshToken: _rt, ...safe } = JSON.parse(s);
      return safe;
    });
  }

  // ── 10. Revoke Specific Session ───────────────────────────────────────────
  static async revokeSession({ userId, sessionId }) {
    const redis = getRedis();
    const sessions = await redis.lrange(K.sessions(userId), 0, -1);
    let found = false;
    for (const s of sessions) {
      const parsed = JSON.parse(s);
      if (parsed.sessionId === sessionId) {
        await revokeRefreshToken(parsed.refreshToken);
        found = true;
        break;
      }
    }
    if (!found) throw notFound("Session");
    return { message: "Session revoked." };
  }

  // ── 11. Forgot Password ───────────────────────────────────────────────────
  static async forgotPassword({ email }) {
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    // Always return success to prevent email enumeration
    if (!user || !user.passwordHash) {
      return { message: "If an account exists with this email, you will receive a reset code." };
    }

    const otp = generateSecureOTP();
    await getRedis().set(
      K.resetOtp(user.email),
      JSON.stringify({ otp, userId: user._id.toString(), attempts: 0 }),
      "EX",
      RESET_OTP_TTL_S
    );

    await sendOtpEmail(user.email, otp, "Reset your TeamSpot password", "password reset");

    log.info("Password reset OTP sent", { userId: user._id });

    return { message: "If an account exists with this email, you will receive a reset code." };
  }

  // ── 12. Reset Password ────────────────────────────────────────────────────
  static async resetPassword({ email, otp, newPassword }) {
    const redis = getRedis();
    const raw = await redis.get(K.resetOtp(email.toLowerCase().trim()));
    if (!raw) throw badRequest("Reset code expired or not found. Please request a new one.");

    const data = JSON.parse(raw);

    if (data.attempts >= 5) {
      await redis.del(K.resetOtp(email.toLowerCase().trim()));
      throw badRequest("Too many failed attempts. Please request a new reset code.");
    }

    if (data.otp !== otp.trim()) {
      data.attempts += 1;
      await redis.set(K.resetOtp(email.toLowerCase().trim()), JSON.stringify(data), "KEEPTTL");
      throw badRequest("Invalid reset code.");
    }

    const passwordHash = await bcryptjs.hash(newPassword, BCRYPT_ROUNDS);
    await User.findByIdAndUpdate(data.userId, { passwordHash });

    await redis.del(K.resetOtp(email.toLowerCase().trim()));

    // Revoke all sessions for security
    await revokeAllSessions(data.userId);

    log.info("Password reset successful", { userId: data.userId });

    return { message: "Password reset successfully. Please log in with your new password." };
  }

  // ── 13. Change Password (authenticated) ──────────────────────────────────
  static async changePassword({ userId, currentPassword, newPassword }) {
    const user = await User.findById(userId).select("+passwordHash");
    if (!user) throw notFound("User");
    if (!user.passwordHash) throw badRequest("Password change not available for social auth accounts.");

    const valid = await bcryptjs.compare(currentPassword, user.passwordHash);
    if (!valid) throw badRequest("Current password is incorrect.");

    const passwordHash = await bcryptjs.hash(newPassword, BCRYPT_ROUNDS);
    await User.findByIdAndUpdate(userId, { passwordHash });

    // Revoke all other sessions
    await revokeAllSessions(userId);

    return { message: "Password changed. Please log in again." };
  }

  // ── 14. TOTP Setup ────────────────────────────────────────────────────────
  static async setupTotp({ userId }) {
    const user = await User.findById(userId);
    if (!user) throw notFound("User");
    if (user.totpEnabled) throw conflict("TOTP is already enabled.");

    const secret = speakeasy.generateSecret({
      name: `TeamSpot (${user.email})`,
      issuer: "TeamSpot",
      length: 32,
    });

    // Store unconfirmed secret temporarily in Redis (not in DB yet)
    await getRedis().set(
      `auth:totp:pending:${userId}`,
      secret.base32,
      "EX",
      600 // 10 min to confirm
    );

    const qrCodeDataUrl = await qrcode.toDataURL(secret.otpauth_url);

    return {
      secret: secret.base32,
      qrCode: qrCodeDataUrl,
      otpauthUrl: secret.otpauth_url,
    };
  }

  // ── 15. Confirm TOTP Setup ────────────────────────────────────────────────
  static async confirmTotp({ userId, token }) {
    const redis = getRedis();
    const pendingSecret = await redis.get(`auth:totp:pending:${userId}`);
    if (!pendingSecret) throw badRequest("TOTP setup session expired. Please restart setup.");

    const valid = speakeasy.totp.verify({
      secret: pendingSecret,
      encoding: "base32",
      token: token.trim(),
      window: 2,
    });

    if (!valid) throw badRequest("Invalid TOTP code. Please try again.");

    // Generate backup codes
    const backupCodes = Array.from({ length: 8 }, () => ({
      code: crypto.randomBytes(5).toString("hex").toUpperCase(),
      used: false,
    }));

    // Encrypt TOTP secret before storing
    await User.findByIdAndUpdate(userId, {
      totpSecret: pendingSecret,
      totpEnabled: true,
      totpSetupAt: new Date(),
      backupCodes,
      "twoFactorSettings.preferredMethod": "totp",
    });

    await redis.del(`auth:totp:pending:${userId}`);

    log.info("TOTP enabled", { userId });

    return {
      message: "TOTP 2FA enabled successfully.",
      backupCodes: backupCodes.map((b) => b.code),
    };
  }

  // ── 16. Verify TOTP (login challenge) ────────────────────────────────────
  static async verifyTotp({ challengeToken, token, deviceInfo }) {
    let payload;
    try {
      payload = jwt.verify(challengeToken, env.JWT_SECRET);
    } catch {
      throw unauthorized("Challenge token invalid or expired.");
    }

    if (payload.purpose !== "2fa_challenge") throw unauthorized("Invalid challenge token.");

    const user = await User.findById(payload.sub).select("+totpSecret");
    if (!user || !user.totpEnabled || !user.totpSecret) {
      throw badRequest("TOTP not configured.");
    }

    const valid = speakeasy.totp.verify({
      secret: user.totpSecret,
      encoding: "base32",
      token: token.trim(),
      window: 2,
    });

    if (!valid) {
      // Check backup codes
      const backupIndex = user.backupCodes?.findIndex(
        (b) => !b.used && b.code === token.trim().toUpperCase()
      );
      if (backupIndex !== undefined && backupIndex >= 0) {
        user.backupCodes[backupIndex].used = true;
        user.backupCodes[backupIndex].usedAt = new Date();
        await user.save();
        log.warn("Backup code used", { userId: user._id, backupIndex });
      } else {
        throw badRequest("Invalid TOTP code.");
      }
    }

    const accessToken = generateAccessToken(user);
    const { refreshToken, sessionId } = await createSession(user._id.toString(), deviceInfo);

    return { accessToken, refreshToken, sessionId, user: AuthService._safeUser(user) };
  }

  // ── 17. Disable TOTP ──────────────────────────────────────────────────────
  static async disableTotp({ userId, token }) {
    const user = await User.findById(userId).select("+totpSecret");
    if (!user || !user.totpEnabled) throw badRequest("TOTP is not enabled.");

    const valid = speakeasy.totp.verify({
      secret: user.totpSecret,
      encoding: "base32",
      token: token.trim(),
      window: 2,
    });
    if (!valid) throw badRequest("Invalid TOTP code.");

    await User.findByIdAndUpdate(userId, {
      totpSecret: null,
      totpEnabled: false,
      totpDisabledAt: new Date(),
      backupCodes: [],
    });

    return { message: "TOTP 2FA disabled." };
  }

  // ── 18. Send Email 2FA OTP ────────────────────────────────────────────────
  static async sendEmail2FA({ userId }) {
    const user = await User.findById(userId);
    if (!user) throw notFound("User");

    const otp = generateSecureOTP();
    await getRedis().set(K.emailOtp(userId), JSON.stringify({ otp, attempts: 0 }), "EX", EMAIL_OTP_TTL_S);
    await sendOtpEmail(user.email, otp, "Your TeamSpot 2FA code", "two-factor authentication");

    return { message: "2FA code sent to your email.", expiresIn: EMAIL_OTP_TTL_S };
  }

  // ── 19. Verify Email 2FA OTP ──────────────────────────────────────────────
  static async verifyEmail2FA({ userId, otp }) {
    const redis = getRedis();
    const raw = await redis.get(K.emailOtp(userId));
    if (!raw) throw badRequest("2FA code expired. Please request a new one.");

    const data = JSON.parse(raw);
    if (data.attempts >= 5) {
      await redis.del(K.emailOtp(userId));
      throw badRequest("Too many attempts. Please request a new 2FA code.");
    }

    if (data.otp !== otp.trim()) {
      data.attempts += 1;
      await redis.set(K.emailOtp(userId), JSON.stringify(data), "KEEPTTL");
      throw badRequest("Invalid 2FA code.");
    }

    await redis.del(K.emailOtp(userId));
    return { verified: true, message: "2FA verified." };
  }

  // ── 20. Send SMS 2FA OTP ──────────────────────────────────────────────────
  static async sendSms2FA({ userId, phoneNumber }) {
    const user = await User.findById(userId);
    if (!user) throw notFound("User");

    const otp = generateSecureOTP();
    await getRedis().set(
      K.smsOtp(userId),
      JSON.stringify({ otp, phoneNumber, attempts: 0 }),
      "EX",
      SMS_OTP_TTL_S
    );

    // SMS delivery via notification worker queue (RabbitMQ)
    // Published as a job — notification.worker.js picks it up
    const { publishToQueue } = await import("../../infrastructure/rabbitmq/rabbitmq.service.js");
    await publishToQueue("teamspot.sms.send", {
      to: phoneNumber,
      body: `Your TeamSpot 2FA code is: ${otp}. Expires in 5 minutes.`,
    });

    return { message: "2FA code sent via SMS.", expiresIn: SMS_OTP_TTL_S };
  }

  // ── 21. Verify SMS 2FA OTP ────────────────────────────────────────────────
  static async verifySms2FA({ userId, otp }) {
    const redis = getRedis();
    const raw = await redis.get(K.smsOtp(userId));
    if (!raw) throw badRequest("2FA code expired. Please request a new one.");

    const data = JSON.parse(raw);
    if (data.attempts >= 5) {
      await redis.del(K.smsOtp(userId));
      throw badRequest("Too many attempts.");
    }

    if (data.otp !== otp.trim()) {
      data.attempts += 1;
      await redis.set(K.smsOtp(userId), JSON.stringify(data), "KEEPTTL");
      throw badRequest("Invalid 2FA code.");
    }

    await redis.del(K.smsOtp(userId));
    return { verified: true, message: "2FA verified." };
  }

  // ── 22. Get 2FA Status ────────────────────────────────────────────────────
  static async get2FAStatus({ userId }) {
    const user = await User.findById(userId);
    if (!user) throw notFound("User");

    return {
      totpEnabled: user.totpEnabled || false,
      emailVerified: user.twoFactorSettings?.emailVerified || false,
      phoneVerified: user.twoFactorSettings?.phoneVerified || false,
      preferredMethod: user.twoFactorSettings?.preferredMethod || "email",
      backupCodesRemaining: user.backupCodes?.filter((b) => !b.used).length || 0,
    };
  }

  // ── 23. Verify JWT (internal utility) ────────────────────────────────────
  static verifyToken(token) {
    return verifyAccessToken(token);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static _safeUser(user) {
    const obj = user.toObject ? user.toObject() : { ...user };
    delete obj.passwordHash;
    delete obj.totpSecret;
    delete obj.backupCodes;
    delete obj.__v;
    return obj;
  }
}

export default AuthService;
