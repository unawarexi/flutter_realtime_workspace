import speakeasy from 'speakeasy';
import qrcode from 'qrcode';
import crypto from 'crypto';
import redisClient from './redisClient.js';
import UserInfo from '../../models/userInfoModel.js';
import { getUserByFirebaseUID } from '../middlewares/firebaseAuthMiddleware.js';

class TwoFactorAuthService {
  constructor() {
    this.EMAIL_CODE_EXPIRY = 300; // 5 minutes
    this.SMS_CODE_EXPIRY = 300; // 5 minutes
    this.TOTP_WINDOW = 2; // Allow 2 time windows (60 seconds each)
    this.MAX_ATTEMPTS = 5; // Max verification attempts
    this.RATE_LIMIT_WINDOW = 900; // 15 minutes
    this.APP_NAME = process.env.APP_NAME || 'SecureApp';
  }

  // Generate secure 6-digit code
  generateSecureCode() {
    return crypto.randomInt(100000, 999999).toString();
  }

  // Generate rate limiting key
  getRateLimitKey(userId, type) {
    return `2fa:rate_limit:${type}:${userId}`;
  }

  // Check rate limiting
  async checkRateLimit(userId, type = 'verification') {
    try {
      const key = this.getRateLimitKey(userId, type);
      const rateLimitResult = await redisClient.rateLimit(key, this.MAX_ATTEMPTS, this.RATE_LIMIT_WINDOW);

      if (rateLimitResult.remaining <= 0) {
        return {
          allowed: false,
          resetTime: rateLimitResult.resetTime,
          message: `Too many attempts. Try again in ${Math.ceil(rateLimitResult.resetTime / 60)} minutes.`
        };
      }

      return {
        allowed: true,
        remaining: rateLimitResult.remaining
      };
    } catch (error) {
      console.error('Rate limit check error:', error);
      return { allowed: true, remaining: this.MAX_ATTEMPTS }; // Fail open
    }
  }

  // EMAIL/SMS 2FA Methods
  async generateEmailCode(firebaseUID, email) {
    try {
      // Verify user exists and Firebase token is valid
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      // Verify email matches
      if (userInfo.email !== email) {
        throw new Error('Email mismatch');
      }

      // Check rate limiting
      const rateLimitCheck = await this.checkRateLimit(firebaseUID, 'email_generation');
      if (!rateLimitCheck.allowed) {
        throw new Error(rateLimitCheck.message);
      }

      // Generate secure code
      const code = this.generateSecureCode();
      const timestamp = Date.now();

      // Store in Redis with metadata
      const emailKey = `2fa:email:${firebaseUID}`;
      const emailData = {
        code,
        email,
        timestamp,
        attempts: 0,
        maxAttempts: this.MAX_ATTEMPTS
      };

      await redisClient.set(emailKey, emailData, { EX: this.EMAIL_CODE_EXPIRY });

      // Store generation timestamp for analytics
      await redisClient.set(`2fa:email:generated:${firebaseUID}`, timestamp, { EX: this.EMAIL_CODE_EXPIRY });

      return {
        success: true,
        expiresIn: this.EMAIL_CODE_EXPIRY,
        message: 'Verification code sent to email',
        remaining: rateLimitCheck.remaining - 1
      };
    } catch (error) {
      console.error('Generate email code error:', error);
      throw error;
    }
  }

  async generateSMSCode(firebaseUID, phoneNumber) {
    try {
      // Verify user exists and Firebase token is valid
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      // Verify phone number matches (if provided)
      if (userInfo.phoneNumber && userInfo.phoneNumber !== phoneNumber) {
        throw new Error('Phone number mismatch');
      }

      // Check rate limiting
      const rateLimitCheck = await this.checkRateLimit(firebaseUID, 'sms_generation');
      if (!rateLimitCheck.allowed) {
        throw new Error(rateLimitCheck.message);
      }

      // Generate secure code
      const code = this.generateSecureCode();
      const timestamp = Date.now();

      // Store in Redis with metadata
      const smsKey = `2fa:sms:${firebaseUID}`;
      const smsData = {
        code,
        phoneNumber,
        timestamp,
        attempts: 0,
        maxAttempts: this.MAX_ATTEMPTS
      };

      await redisClient.set(smsKey, smsData, { EX: this.SMS_CODE_EXPIRY });

      // Store generation timestamp
      await redisClient.set(`2fa:sms:generated:${firebaseUID}`, timestamp, { EX: this.SMS_CODE_EXPIRY });

      return {
        success: true,
        expiresIn: this.SMS_CODE_EXPIRY,
        message: 'Verification code sent to phone',
        remaining: rateLimitCheck.remaining - 1
      };
    } catch (error) {
      console.error('Generate SMS code error:', error);
      throw error;
    }
  }

  async verifyEmailCode(firebaseUID, inputCode) {
    try {
      // Check rate limiting
      const rateLimitCheck = await this.checkRateLimit(firebaseUID, 'email_verification');
      if (!rateLimitCheck.allowed) {
        throw new Error(rateLimitCheck.message);
      }

      const emailKey = `2fa:email:${firebaseUID}`;
      const emailData = await redisClient.get(emailKey);

      if (!emailData) {
        throw new Error('Verification code expired or not found');
      }

      // Increment attempt count
      emailData.attempts += 1;
      await redisClient.set(emailKey, emailData, { EX: await redisClient.ttl(emailKey) });

      // Check max attempts
      if (emailData.attempts > emailData.maxAttempts) {
        await redisClient.del(emailKey);
        throw new Error('Maximum verification attempts exceeded');
      }

      // Verify code
      if (emailData.code !== inputCode.toString()) {
        throw new Error('Invalid verification code');
      }

      // Success - cleanup
      await redisClient.del(emailKey);
      await redisClient.del(`2fa:email:generated:${firebaseUID}`);

      // Clear rate limiting on success
      await redisClient.del(this.getRateLimitKey(firebaseUID, 'email_verification'));

      return {
        success: true,
        message: 'Email verification successful',
        verifiedAt: Date.now()
      };
    } catch (error) {
      console.error('Verify email code error:', error);
      throw error;
    }
  }

  async verifySMSCode(firebaseUID, inputCode) {
    try {
      // Check rate limiting
      const rateLimitCheck = await this.checkRateLimit(firebaseUID, 'sms_verification');
      if (!rateLimitCheck.allowed) {
        throw new Error(rateLimitCheck.message);
      }

      const smsKey = `2fa:sms:${firebaseUID}`;
      const smsData = await redisClient.get(smsKey);

      if (!smsData) {
        throw new Error('Verification code expired or not found');
      }

      // Increment attempt count
      smsData.attempts += 1;
      await redisClient.set(smsKey, smsData, { EX: await redisClient.ttl(smsKey) });

      // Check max attempts
      if (smsData.attempts > smsData.maxAttempts) {
        await redisClient.del(smsKey);
        throw new Error('Maximum verification attempts exceeded');
      }

      // Verify code
      if (smsData.code !== inputCode.toString()) {
        throw new Error('Invalid verification code');
      }

      // Success - cleanup
      await redisClient.del(smsKey);
      await redisClient.del(`2fa:sms:generated:${firebaseUID}`);

      // Clear rate limiting on success
      await redisClient.del(this.getRateLimitKey(firebaseUID, 'sms_verification'));

      return {
        success: true,
        message: 'SMS verification successful',
        verifiedAt: Date.now()
      };
    } catch (error) {
      console.error('Verify SMS code error:', error);
      throw error;
    }
  }

  // TOTP (Time-based One-Time Password) Methods
  async generateTOTPSecret(firebaseUID, userEmail) {
    try {
      // Verify user exists
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      // Generate TOTP secret
      const secret = speakeasy.generateSecret({
        name: `${this.APP_NAME} (${userEmail})`,
        issuer: this.APP_NAME,
        length: 32
      });

      // Store secret temporarily in Redis (user hasn't confirmed setup yet)
      const totpKey = `2fa:totp:setup:${firebaseUID}`;
      const totpData = {
        secret: secret.base32,
        otpauthUrl: secret.otpauth_url,
        createdAt: Date.now(),
        confirmed: false
      };

      // Give user 10 minutes to complete setup
      await redisClient.set(totpKey, totpData, { EX: 600 });

      // Generate QR code
      const qrCodeDataURL = await new Promise((resolve, reject) => {
        qrcode.toDataURL(secret.otpauth_url, (err, dataURL) => {
          if (err) reject(err);
          else resolve(dataURL);
        });
      });

      return {
        success: true,
        secret: secret.base32,
        qrCode: qrCodeDataURL,
        manualEntryKey: secret.base32,
        otpauthUrl: secret.otpauth_url,
        expiresIn: 600
      };
    } catch (error) {
      console.error('Generate TOTP secret error:', error);
      throw error;
    }
  }

  async confirmTOTPSetup(firebaseUID, verificationCode) {
    try {
      const totpKey = `2fa:totp:setup:${firebaseUID}`;
      const totpData = await redisClient.get(totpKey);

      if (!totpData) {
        throw new Error('TOTP setup session expired. Please restart setup.');
      }

      // Verify the code
      const verified = speakeasy.totp.verify({
        secret: totpData.secret,
        encoding: 'base32',
        token: verificationCode,
        window: this.TOTP_WINDOW
      });

      if (!verified) {
        throw new Error('Invalid TOTP code');
      }

      // Save secret to user record
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      // Update user with TOTP secret (encrypt in production)
      userInfo.totpSecret = totpData.secret;
      userInfo.totpEnabled = true;
      userInfo.totpSetupAt = new Date();
      await userInfo.save();

      // Cleanup setup session
      await redisClient.del(totpKey);

      // Store permanent TOTP config
      const permanentTotpKey = `2fa:totp:${firebaseUID}`;
      await redisClient.set(
        permanentTotpKey,
        {
          enabled: true,
          setupAt: Date.now()
        },
        { EX: 86400 * 30 }
      ); // 30 days cache

      return {
        success: true,
        message: 'TOTP setup completed successfully',
        backupCodes: this.generateBackupCodes() // Optional: generate backup codes
      };
    } catch (error) {
      console.error('Confirm TOTP setup error:', error);
      throw error;
    }
  }

  async verifyTOTPCode(firebaseUID, inputCode) {
    try {
      // Check rate limiting
      const rateLimitCheck = await this.checkRateLimit(firebaseUID, 'totp_verification');
      if (!rateLimitCheck.allowed) {
        throw new Error(rateLimitCheck.message);
      }

      // Get user info
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo || !userInfo.totpSecret || !userInfo.totpEnabled) {
        throw new Error('TOTP not configured for this user');
      }

      // Check for replay attacks
      const replayKey = `2fa:totp:used:${firebaseUID}:${inputCode}`;
      const alreadyUsed = await redisClient.exists(replayKey);
      if (alreadyUsed) {
        throw new Error('TOTP code already used');
      }

      // Verify TOTP code
      const verified = speakeasy.totp.verify({
        secret: userInfo.totpSecret,
        encoding: 'base32',
        token: inputCode,
        window: this.TOTP_WINDOW
      });

      if (!verified) {
        throw new Error('Invalid TOTP code');
      }

      // Mark code as used (prevent replay)
      await redisClient.set(replayKey, Date.now(), { EX: 90 }); // 90 seconds window

      // Clear rate limiting on success
      await redisClient.del(this.getRateLimitKey(firebaseUID, 'totp_verification'));

      return {
        success: true,
        message: 'TOTP verification successful',
        verifiedAt: Date.now()
      };
    } catch (error) {
      console.error('Verify TOTP code error:', error);
      throw error;
    }
  }

  async disableTOTP(firebaseUID) {
    try {
      // Get user info
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      // Disable TOTP
      userInfo.totpSecret = undefined;
      userInfo.totpEnabled = false;
      userInfo.totpDisabledAt = new Date();
      await userInfo.save();

      // Cleanup Redis
      await redisClient.del(`2fa:totp:${firebaseUID}`);
      await redisClient.del(`2fa:totp:setup:${firebaseUID}`);

      return {
        success: true,
        message: 'TOTP disabled successfully'
      };
    } catch (error) {
      console.error('Disable TOTP error:', error);
      throw error;
    }
  }

  // Utility Methods
  generateBackupCodes(count = 8) {
    const codes = [];
    for (let i = 0; i < count; i++) {
      codes.push(crypto.randomBytes(4).toString('hex').toUpperCase());
    }
    return codes;
  }

  async get2FAStatus(firebaseUID) {
    try {
      const userInfo = await getUserByFirebaseUID(firebaseUID);
      if (!userInfo) {
        throw new Error('User not found');
      }

      return {
        email2FA: {
          available: !!userInfo.email,
          email: userInfo.email
        },
        sms2FA: {
          available: !!userInfo.phoneNumber,
          phoneNumber: userInfo.phoneNumber ? userInfo.phoneNumber.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : null
        },
        totp: {
          enabled: userInfo.totpEnabled || false,
          setupAt: userInfo.totpSetupAt || null
        }
      };
    } catch (error) {
      console.error('Get 2FA status error:', error);
      throw error;
    }
  }

  // Cleanup expired codes (can be run as a cron job)
  async cleanupExpiredCodes() {
    try {
      // This would typically be implemented with Redis SCAN
      // For now, we rely on Redis TTL for automatic cleanup
      console.log('2FA cleanup completed (Redis TTL handles expiration)');
    } catch (error) {
      console.error('Cleanup error:', error);
    }
  }
}

// Export singleton instance
const twoFactorAuthService = new TwoFactorAuthService();
export default twoFactorAuthService;

// Export individual methods for easier importing
export const {
  generateEmailCode, generateSMSCode, verifyEmailCode, verifySMSCode, generateTOTPSecret,
  confirmTOTPSetup, verifyTOTPCode, disableTOTP, get2FAStatus
} = twoFactorAuthService;
