
// ============================================================================
// TeamSpot — Auth Controller
// ============================================================================

import { asyncHandler } from "../../core/base/base.controller.js";
import { success, created } from "../../core/utils/api-response.js";
import authService from "./auth.service.js";

const ctx = (req) => ({
  ip: req.ip,
  userAgent: req.get("user-agent"),
  userId: req.user?._id?.toString() || req.user?.id || null,
  sessionId: req.user?.sessionId || null,
});

export const register = asyncHandler(async (req, res) => {
  const result = await authService.register({ ...req.body, ip: req.ip });
  created(res, result, "Registration successful. Verify your email.");
});

export const verifyEmail = asyncHandler(async (req, res) => {
  const result = await authService.verifyEmail(req.body);
  success(res, result, "Email verified");
});

export const resendVerification = asyncHandler(async (req, res) => {
  const result = await authService.resendVerification({ ...req.body, ip: req.ip });
  success(res, result);
});

export const loginPassword = asyncHandler(async (req, res) => {
  const result = await authService.loginPassword({ ...req.body, ip: req.ip });
  success(res, result, result.requires2FA ? "2FA required" : "Login successful");
});

export const loginSocial = asyncHandler(async (req, res) => {
  const result = await authService.loginSocial(req.body);
  success(res, result, "Login successful");
});

export const refreshToken = asyncHandler(async (req, res) => {
  const result = await authService.refreshToken(req.body);
  success(res, result, "Token refreshed");
});

export const logout = asyncHandler(async (req, res) => {
  const result = await authService.logout({
    userId: ctx(req).userId,
    refreshToken: req.body.refreshToken,
    sessionId: ctx(req).sessionId,
  });
  success(res, result, "Logged out");
});

export const logoutAll = asyncHandler(async (req, res) => {
  const result = await authService.logoutAll({ userId: ctx(req).userId });
  success(res, result, "Logged out from all devices");
});

export const getSessions = asyncHandler(async (req, res) => {
  const result = await authService.getSessions({ userId: ctx(req).userId });
  success(res, result, "Active sessions");
});

export const revokeSession = asyncHandler(async (req, res) => {
  const result = await authService.revokeSession({ userId: ctx(req).userId, sessionId: req.params.sessionId });
  success(res, result);
});

export const forgotPassword = asyncHandler(async (req, res) => {
  const result = await authService.forgotPassword({ email: req.body.email, ip: req.ip });
  success(res, result);
});

export const resetPassword = asyncHandler(async (req, res) => {
  const result = await authService.resetPassword(req.body);
  success(res, result, "Password reset successful");
});

export const changePassword = asyncHandler(async (req, res) => {
  const result = await authService.changePassword({ userId: ctx(req).userId, ...req.body });
  success(res, result, "Password changed");
});

export const setupTotp = asyncHandler(async (req, res) => {
  const result = await authService.setupTotp({ userId: ctx(req).userId });
  success(res, result, "TOTP setup initiated");
});

export const confirmTotp = asyncHandler(async (req, res) => {
  const result = await authService.confirmTotp({ userId: ctx(req).userId, token: req.body.token });
  success(res, result, "TOTP enabled");
});

export const verifyTotp = asyncHandler(async (req, res) => {
  const result = await authService.verifyTotp({ tempToken: req.body.tempToken, token: req.body.token });
  success(res, result, "2FA verified");
});

export const disableTotp = asyncHandler(async (req, res) => {
  const result = await authService.disableTotp({ userId: ctx(req).userId, token: req.body.token });
  success(res, result, "TOTP disabled");
});

export const sendEmail2FA = asyncHandler(async (req, res) => {
  const result = await authService.sendEmail2FA({ userId: ctx(req).userId });
  success(res, result);
});

export const verifyEmail2FA = asyncHandler(async (req, res) => {
  const result = await authService.verifyEmail2FA({ userId: ctx(req).userId, otp: req.body.otp, tempToken: req.body.tempToken });
  success(res, result, "2FA verified");
});

export const sendSms2FA = asyncHandler(async (req, res) => {
  const result = await authService.sendSms2FA({ userId: ctx(req).userId, phoneNumber: req.body.phoneNumber });
  success(res, result);
});

export const verifySms2FA = asyncHandler(async (req, res) => {
  const result = await authService.verifySms2FA({ userId: ctx(req).userId, otp: req.body.otp, tempToken: req.body.tempToken });
  success(res, result, "2FA verified");
});

export const get2FAStatus = asyncHandler(async (req, res) => {
  const result = await authService.get2FAStatus({ userId: ctx(req).userId });
  success(res, result, "2FA status");
});
