// ============================================================================
// TeamSpot — Auth Routes
// Public: register, verify-email, login, social, forgot/reset password
// Protected (JWT): logout, refresh, sessions, change-password, 2FA management
// ============================================================================

import express from "express";
import { validate } from "../../middlewares/validate.middleware.js";
import { authenticate } from "../../middlewares/auth.middleware.js";

import {
  register, verifyEmail, resendVerification,
  loginPassword, loginSocial,
  refreshToken, logout, logoutAll,
  getSessions, revokeSession,
  forgotPassword, resetPassword, changePassword,
  setupTotp, confirmTotp, verifyTotp, disableTotp,
  sendEmail2FA, verifyEmail2FA,
  sendSms2FA, verifySms2FA,
  get2FAStatus,
} from "./auth.controller.js";

import {
  validateRegister, validateVerifyEmail, validateResendVerification,
  validateLoginPassword, validateLoginSocial,
  validateRefreshToken, validateLogout,
  validateForgotPassword, validateResetPassword, validateChangePassword,
  validateConfirmTotp, validateVerifyTotp, validateDisableTotp,
  validateOtp, validateSendSms2FA,
  validateRevokeSession,
} from "./auth.validation.js";

const router = express.Router();

// ── Public Routes ─────────────────────────────────────────────────────────────

router.post("/register",              validateRegister,           validate, register);
router.post("/verify-email",          validateVerifyEmail,        validate, verifyEmail);
router.post("/resend-verification",   validateResendVerification, validate, resendVerification);
router.post("/login",                 validateLoginPassword,      validate, loginPassword);
router.post("/social",                validateLoginSocial,        validate, loginSocial);
router.post("/2fa/totp/verify",       validateVerifyTotp,         validate, verifyTotp);
router.post("/refresh",               validateRefreshToken,       validate, refreshToken);
router.post("/forgot-password",       validateForgotPassword,     validate, forgotPassword);
router.post("/reset-password",        validateResetPassword,      validate, resetPassword);

// ── Protected Routes ──────────────────────────────────────────────────────────

router.use(authenticate);

router.post("/logout",                validateLogout,             validate, logout);
router.post("/logout-all",            logoutAll);
router.get("/sessions",               getSessions);
router.delete("/sessions/:sessionId", validateRevokeSession,      validate, revokeSession);
router.put("/change-password",        validateChangePassword,     validate, changePassword);
router.get("/2fa/status",             get2FAStatus);
router.post("/2fa/totp/setup",        setupTotp);
router.post("/2fa/totp/confirm",      validateConfirmTotp,        validate, confirmTotp);
router.delete("/2fa/totp/disable",    validateDisableTotp,        validate, disableTotp);
router.post("/2fa/email/send",        sendEmail2FA);
router.post("/2fa/email/verify",      validateOtp,                validate, verifyEmail2FA);
router.post("/2fa/sms/send",          validateSendSms2FA,         validate, sendSms2FA);
router.post("/2fa/sms/verify",        validateOtp,                validate, verifySms2FA);

export default router;