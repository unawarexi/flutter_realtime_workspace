// ============================================================================
// TeamSpot — Auth Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created } from "../../core/utils/api-response.js";
import { validationResult } from "express-validator";
import { badRequest } from "../../core/errors/app-error.js";
import AuthService from "./auth.service.js";

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw badRequest("Validation failed", errors.array());
}

function deviceInfo(req) {
  return {
    ip: req.ip || req.headers["x-forwarded-for"] || "",
    userAgent: req.headers["user-agent"] || "",
    deviceName: req.headers["x-device-name"] || "Unknown Device",
  };
}

// ── Registration & Email Verification ────────────────────────────────────────

export const register = asyncHandler(async (req, res) => {
  validate(req);
  const { email, password, fullName, inviteCode } = req.body;
  const result = await AuthService.register({ email, password, fullName, inviteCode, deviceInfo: deviceInfo(req) });
  created(res, result, result.message);
});

export const verifyEmail = asyncHandler(async (req, res) => {
  validate(req);
  const { email, otp } = req.body;
  const result = await AuthService.verifyEmail({ email, otp, deviceInfo: deviceInfo(req) });
  success(res, result, "Email verified. Welcome to TeamSpot!");
});

export const resendVerification = asyncHandler(async (req, res) => {
  validate(req);
  const { email } = req.body;
  const result = await AuthService.resendVerification({ email });
  success(res, null, result.message);
});

// ── Login ─────────────────────────────────────────────────────────────────────

export const loginPassword = asyncHandler(async (req, res) => {
  validate(req);
  const { email, password } = req.body;
  const result = await AuthService.loginWithPassword({ email, password, deviceInfo: deviceInfo(req) });
  success(res, result, result.requires2FA ? "2FA required." : "Login successful.");
});

export const loginSocial = asyncHandler(async (req, res) => {
  validate(req);
  const { idToken, inviteCode } = req.body;
  const result = await AuthService.loginWithSocial({ idToken, inviteCode, deviceInfo: deviceInfo(req) });
  success(res, result, "Login successful.");
});

// ── Token Management ──────────────────────────────────────────────────────────

export const refreshToken = asyncHandler(async (req, res) => {
  validate(req);
  const { refreshToken: rt } = req.body;
  const result = await AuthService.refreshToken({ refreshToken: rt, deviceInfo: deviceInfo(req) });
  success(res, result, "Token refreshed.");
});

export const logout = asyncHandler(async (req, res) => {
  validate(req);
  const { refreshToken: rt } = req.body;
  const result = await AuthService.logout({ refreshToken: rt });
  success(res, null, result.message);
});

export const logoutAll = asyncHandler(async (req, res) => {
  const result = await AuthService.logoutAll({ userId: req.user._id.toString() });
  success(res, null, result.message);
});

// ── Session Management ────────────────────────────────────────────────────────

export const getSessions = asyncHandler(async (req, res) => {
  const sessions = await AuthService.getSessions({ userId: req.user._id.toString() });
  success(res, { sessions });
});

export const revokeSession = asyncHandler(async (req, res) => {
  const { sessionId } = req.params;
  const result = await AuthService.revokeSession({ userId: req.user._id.toString(), sessionId });
  success(res, null, result.message);
});

// ── Password Management ───────────────────────────────────────────────────────

export const forgotPassword = asyncHandler(async (req, res) => {
  validate(req);
  const { email } = req.body;
  const result = await AuthService.forgotPassword({ email });
  success(res, null, result.message);
});

export const resetPassword = asyncHandler(async (req, res) => {
  validate(req);
  const { email, otp, newPassword } = req.body;
  const result = await AuthService.resetPassword({ email, otp, newPassword });
  success(res, null, result.message);
});

export const changePassword = asyncHandler(async (req, res) => {
  validate(req);
  const { currentPassword, newPassword } = req.body;
  const result = await AuthService.changePassword({
    userId: req.user._id.toString(),
    currentPassword,
    newPassword,
  });
  success(res, null, result.message);
});

// ── TOTP 2FA ──────────────────────────────────────────────────────────────────

export const setupTotp = asyncHandler(async (req, res) => {
  const result = await AuthService.setupTotp({ userId: req.user._id.toString() });
  success(res, result, "Scan the QR code with your authenticator app, then confirm.");
});

export const confirmTotp = asyncHandler(async (req, res) => {
  validate(req);
  const { token } = req.body;
  const result = await AuthService.confirmTotp({ userId: req.user._id.toString(), token });
  success(res, result, result.message);
});

export const verifyTotp = asyncHandler(async (req, res) => {
  validate(req);
  const { challengeToken, token } = req.body;
  const result = await AuthService.verifyTotp({ challengeToken, token, deviceInfo: deviceInfo(req) });
  success(res, result, "2FA verified. Login successful.");
});

export const disableTotp = asyncHandler(async (req, res) => {
  validate(req);
  const { token } = req.body;
  const result = await AuthService.disableTotp({ userId: req.user._id.toString(), token });
  success(res, null, result.message);
});

// ── Email & SMS 2FA OTP ───────────────────────────────────────────────────────

export const sendEmail2FA = asyncHandler(async (req, res) => {
  const result = await AuthService.sendEmail2FA({ userId: req.user._id.toString() });
  success(res, null, result.message);
});

export const verifyEmail2FA = asyncHandler(async (req, res) => {
  validate(req);
  const { otp } = req.body;
  const result = await AuthService.verifyEmail2FA({ userId: req.user._id.toString(), otp });
  success(res, result, result.message);
});

export const sendSms2FA = asyncHandler(async (req, res) => {
  validate(req);
  const { phoneNumber } = req.body;
  const result = await AuthService.sendSms2FA({ userId: req.user._id.toString(), phoneNumber });
  success(res, null, result.message);
});

export const verifySms2FA = asyncHandler(async (req, res) => {
  validate(req);
  const { otp } = req.body;
  const result = await AuthService.verifySms2FA({ userId: req.user._id.toString(), otp });
  success(res, result, result.message);
});

export const get2FAStatus = asyncHandler(async (req, res) => {
  const result = await AuthService.get2FAStatus({ userId: req.user._id.toString() });
  success(res, result);
});
