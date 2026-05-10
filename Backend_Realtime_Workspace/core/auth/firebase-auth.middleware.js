// ============================================================================
// TeamSpot — Firebase Auth Middleware
// Verifies Firebase ID tokens and attaches decoded user to req.user
// ============================================================================

import admin from "firebase-admin";
import { createLogger } from "../../observability/logger.js";
import { AppError } from "../errors/app-error.js";
import { HttpStatus, ErrorCodes } from "../../config/constants.js";

const log = createLogger("FirebaseAuth");

export async function firebaseAuthMiddleware(req, _res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new AppError(
        "Missing or invalid Authorization header",
        HttpStatus.UNAUTHORIZED,
        ErrorCodes.UNAUTHORIZED
      );
    }

    const token = authHeader.split("Bearer ")[1];

    if (!token) {
      throw new AppError(
        "Token not provided",
        HttpStatus.UNAUTHORIZED,
        ErrorCodes.INVALID_TOKEN
      );
    }

    const decodedToken = await admin.auth().verifyIdToken(token);

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      displayName: decodedToken.name || null,
      picture: decodedToken.picture || null,
      authProvider: decodedToken.firebase?.sign_in_provider || null,
      firebaseToken: decodedToken,
    };

    next();
  } catch (err) {
    if (err instanceof AppError) return next(err);

    if (err.code === "auth/id-token-expired") {
      return next(new AppError("Token expired", HttpStatus.UNAUTHORIZED, ErrorCodes.TOKEN_EXPIRED));
    }

    if (err.code === "auth/id-token-revoked") {
      return next(new AppError("Token revoked", HttpStatus.UNAUTHORIZED, ErrorCodes.INVALID_TOKEN));
    }

    log.warn("Firebase auth failed", { error: err.message });
    return next(new AppError("Invalid token", HttpStatus.UNAUTHORIZED, ErrorCodes.INVALID_TOKEN));
  }
}

/**
 * Optional auth — attaches user if token present, but doesn't block
 */
export async function optionalAuth(req, _res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    req.user = null;
    return next();
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified,
      displayName: decoded.name || null,
      picture: decoded.picture || null,
      authProvider: decoded.firebase?.sign_in_provider || null,
    };
  } catch {
    req.user = null;
  }

  next();
}

export default { firebaseAuthMiddleware, optionalAuth };
