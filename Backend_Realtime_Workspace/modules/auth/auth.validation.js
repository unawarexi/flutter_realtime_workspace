// ============================================================================
// TeamSpot — Auth Validation Schemas
// ============================================================================
import { body, param } from "express-validator";

export const validateRegister = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
  body("password")
    .isLength({ min: 8, max: 128 })
    .withMessage("Password must be 8-128 characters")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage("Password must contain uppercase, lowercase, and a number"),
  body("fullName").optional().trim().isLength({ min: 2, max: 100 }).withMessage("Full name must be 2-100 characters"),
  body("inviteCode").optional().isString().trim(),
];

export const validateVerifyEmail = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
  body("otp").isLength({ min: 6, max: 6 }).isNumeric().withMessage("6-digit OTP required"),
];

export const validateResendVerification = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
];

export const validateLoginPassword = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
  body("password").notEmpty().withMessage("Password required"),
];

export const validateLoginSocial = [
  body("idToken").notEmpty().withMessage("Firebase ID token required"),
  body("inviteCode").optional().isString().trim(),
];

export const validateRefreshToken = [
  body("refreshToken").notEmpty().isUUID().withMessage("Valid refresh token required"),
];

export const validateLogout = [
  body("refreshToken").notEmpty().isUUID().withMessage("Valid refresh token required"),
];

export const validateForgotPassword = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
];

export const validateResetPassword = [
  body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
  body("otp").isLength({ min: 6, max: 6 }).isNumeric().withMessage("6-digit OTP required"),
  body("newPassword")
    .isLength({ min: 8, max: 128 })
    .withMessage("Password must be 8-128 characters")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage("Password must contain uppercase, lowercase, and a number"),
];

export const validateChangePassword = [
  body("currentPassword").notEmpty().withMessage("Current password required"),
  body("newPassword")
    .isLength({ min: 8, max: 128 })
    .withMessage("Password must be 8-128 characters")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage("Password must contain uppercase, lowercase, and a number")
    .custom((val, { req }) => {
      if (val === req.body.currentPassword) throw new Error("New password must differ from current password");
      return true;
    }),
];

export const validateConfirmTotp = [
  body("token").notEmpty().isLength({ min: 6, max: 8 }).withMessage("TOTP token required"),
];

export const validateVerifyTotp = [
  body("challengeToken").notEmpty().withMessage("Challenge token required"),
  body("token").notEmpty().isLength({ min: 6, max: 8 }).withMessage("TOTP token required"),
];

export const validateDisableTotp = [
  body("token").notEmpty().isLength({ min: 6, max: 8 }).withMessage("TOTP token required"),
];

export const validateOtp = [
  body("otp").isLength({ min: 6, max: 6 }).isNumeric().withMessage("6-digit OTP required"),
];

export const validateSendSms2FA = [
  body("phoneNumber")
    .notEmpty()
    .matches(/^\+[1-9]\d{7,14}$/)
    .withMessage("Valid E.164 phone number required (e.g. +14155552671)"),
];

export const validateRevokeSession = [
  param("sessionId").isUUID().withMessage("Valid session ID required"),
];
