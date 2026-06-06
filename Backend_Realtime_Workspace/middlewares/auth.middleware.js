// ============================================================================
// TeamSpot — Auth Middleware
// Verify custom JWT access tokens for protected routes.
// Firebase tokens are only used at social login time (auth.service loginSocial).
// After any login — email/password or social — the client receives a custom
// JWT signed with JWT_SECRET; that is what protected routes validate.
// ============================================================================

import jwt from "jsonwebtoken";
import admin from "../config/firebase-admin.config.js";
import User from "../modules/users/models/user.model.js";
import { env } from "../config/env.config.js";
import { HttpStatus, ErrorCodes } from "../config/constants.js";
import { createLogger } from "../observability/logger.js";

const log = createLogger("Auth");

// ============================================================================
// AUTHENTICATE — Verify custom JWT, require existing active user in DB
// ============================================================================

export async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.UNAUTHORIZED, message: "Missing or invalid authorization header" },
      });
    }

    const token = authHeader.split("Bearer ")[1];

    let decoded;
    try {
      decoded = jwt.verify(token, env.JWT_SECRET, { algorithms: ["HS256"] });
    } catch (jwtErr) {
      if (jwtErr.name === "TokenExpiredError") {
        return res.status(HttpStatus.UNAUTHORIZED).json({
          success: false,
          error: { code: ErrorCodes.TOKEN_EXPIRED, message: "Token expired. Please sign in again." },
        });
      }
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.TOKEN_INVALID, message: "Invalid token. Please sign in again." },
      });
    }

    // decoded.sub is the MongoDB user _id (set in signAccess)
    const user = await User.findById(decoded.sub).lean();

    if (!user) {
      return res.status(HttpStatus.NOT_FOUND).json({
        success: false,
        error: {
          code: ErrorCodes.USER_NOT_FOUND,
          message: "Account not found. It may have been suspended or deleted. Please contact support or sign up again.",
        },
      });
    }

    if (user.status === "suspended" || user.status === "deactivated") {
      return res.status(HttpStatus.FORBIDDEN).json({
        success: false,
        error: { code: ErrorCodes.ACCOUNT_SUSPENDED, message: "Account has been disabled. Contact support." },
      });
    }

    // Attach user and add uid shim (controllers use req.user.uid which used to be
    // the Firebase UID from firebaseAuthMiddleware; now it maps to the MongoDB _id
    // string so existing controller code works without modification).
    req.user = { ...user, uid: user._id.toString() };
    // Expose decoded JWT claims (sessionId, role, tenantId) for downstream use
    req.tokenClaims = decoded;

    next();
  } catch (error) {
    log.error("Auth middleware error", { error });
    next(error);
  }
}

// ============================================================================
// VERIFY FIREBASE TOKEN — Used only by the social login endpoint.
// Verifies the one-time Firebase ID token the client sends to initiate social
// sign-in. After this, a custom JWT is issued and used for all subsequent calls.
// ============================================================================

export async function verifyFirebaseToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.UNAUTHORIZED, message: "Missing or invalid authorization header" },
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken, true);

    req.firebaseUser = decodedToken;
    next();
  } catch (error) {
    if (error.code === "auth/id-token-expired") {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.TOKEN_EXPIRED, message: "Token expired. Please sign in again." },
      });
    }

    if (error.code === "auth/id-token-revoked") {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.TOKEN_INVALID, message: "Token revoked. Please sign in again." },
      });
    }

    if (error.code === "auth/user-disabled") {
      return res.status(HttpStatus.FORBIDDEN).json({
        success: false,
        error: { code: ErrorCodes.ACCOUNT_SUSPENDED, message: "Account has been disabled. Contact support." },
      });
    }

    if (error.code?.startsWith("auth/")) {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.FIREBASE_AUTH_FAILED, message: "Authentication failed" },
      });
    }

    log.error("verifyFirebaseToken error", { error });
    next(error);
  }
}

// ============================================================================
// OPTIONAL AUTH — Attach user if a valid JWT is present, continue if not
// ============================================================================

export async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next();
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    const decoded = jwt.verify(token, env.JWT_SECRET, { algorithms: ["HS256"] });

    const user = await User.findById(decoded.sub).lean();
    if (user && user.status === "active") {
      req.user = { ...user, uid: user._id.toString() };
      req.tokenClaims = decoded;
    }
  } catch {
    // Silently continue without auth — token invalid/expired is not an error here
  }

  next();
}

// ============================================================================
// REQUIRE ROLE — Authorize by user role
// ============================================================================

export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(HttpStatus.UNAUTHORIZED).json({
        success: false,
        error: { code: ErrorCodes.UNAUTHORIZED, message: "Authentication required" },
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(HttpStatus.FORBIDDEN).json({
        success: false,
        error: { code: ErrorCodes.FORBIDDEN, message: "Insufficient permissions" },
      });
    }

    next();
  };
}

export default { authenticate, optionalAuth, requireRole };
