// ============================================================================
// TeamSpot — Auth Routes
// Public: register, verify-email, login, social, forgot/reset password
// Protected (JWT): logout, refresh, sessions, change-password, 2FA management
// ============================================================================

import express from "express";
import { checkValidation } from "../../middlewares/validate.middleware.js";
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

router.post("/register",              validateRegister,           checkValidation, register);
router.post("/verify-email",          validateVerifyEmail,        checkValidation, verifyEmail);
router.post("/resend-verification",   validateResendVerification, checkValidation, resendVerification);
router.post("/login",                 validateLoginPassword,      checkValidation, loginPassword);
router.post("/social",                validateLoginSocial,        checkValidation, loginSocial);
router.post("/2fa/totp/verify",       validateVerifyTotp,         checkValidation, verifyTotp);
router.post("/refresh",               validateRefreshToken,       checkValidation, refreshToken);
router.post("/forgot-password",       validateForgotPassword,     checkValidation, forgotPassword);
router.post("/reset-password",        validateResetPassword,      checkValidation, resetPassword);

// ── Protected Routes ──────────────────────────────────────────────────────────

router.use(authenticate);

router.post("/logout",                validateLogout,             checkValidation, logout);
router.post("/logout-all",            logoutAll);
router.get("/sessions",               getSessions);
router.delete("/sessions/:sessionId", validateRevokeSession,      checkValidation, revokeSession);
router.put("/change-password",        validateChangePassword,     checkValidation, changePassword);
router.get("/2fa/status",             get2FAStatus);
router.post("/2fa/totp/setup",        setupTotp);
router.post("/2fa/totp/confirm",      validateConfirmTotp,        checkValidation, confirmTotp);
router.delete("/2fa/totp/disable",    validateDisableTotp,        checkValidation, disableTotp);
router.post("/2fa/email/send",        sendEmail2FA);
router.post("/2fa/email/verify",      validateOtp,                checkValidation, verifyEmail2FA);
router.post("/2fa/sms/send",          validateSendSms2FA,         checkValidation, sendSms2FA);
router.post("/2fa/sms/verify",        validateOtp,                checkValidation, verifySms2FA);

export default router;