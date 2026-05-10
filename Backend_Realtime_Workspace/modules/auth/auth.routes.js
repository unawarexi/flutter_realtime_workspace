import express from 'express';
import { generateEmailCode, verifyEmailCode, generateSMSCode, verifySMSCode, generateTOTPSecret,
  confirmTOTPSetup, verifyTOTPCode, disableTOTP, get2FAStatus, healthCheck
} from './2FA.controller.js';

import { firebaseAuthMiddleware } from '../middlewares/firebaseAuthMiddleware.js';

const router = express.Router();

// All 2FA routes require Firebase authentication
router.use(firebaseAuthMiddleware);

// EMAIL 2FA ROUTES
router.post('/2fa/email/generate', generateEmailCode);
router.post('/2fa/email/verify', verifyEmailCode);

// SMS 2FA ROUTES
router.post('/2fa/sms/generate', generateSMSCode);
router.post('/2fa/sms/verify', verifySMSCode);

// TOTP 2FA ROUTES
router.post('/2fa/totp/generate', generateTOTPSecret);
router.post('/2fa/totp/confirm', confirmTOTPSetup);
router.post('/2fa/totp/verify', verifyTOTPCode);
router.delete('/2fa/totp/disable', disableTOTP);

// STATUS ROUTES
router.get('/2fa/status', get2FAStatus);
router.get('/2fa/health', healthCheck);

export default router;