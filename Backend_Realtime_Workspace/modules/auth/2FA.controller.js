import twoFactorAuthService from '../services/2FA-Services.js';


// EMAIL 2FA ENDPOINTS
export const generateEmailCode = async (req, res) => {
  try {
    const { uid: firebaseUID, email } = req.user;

    const result = await twoFactorAuthService.generateEmailCode(firebaseUID, email);

    // PLACEHOLDER: Replace with your email service
    // await sendEmailVerificationCode(email, result.code);

    res.status(200).json({
      success: true,
      message: result.message,
      expiresIn: result.expiresIn,
      remaining: result.remaining
    });
  } catch (error) {
    console.error('Generate email code controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to generate email verification code'
    });
  }
};

export const verifyEmailCode = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Verification code is required'
      });
    }

    const result = await twoFactorAuthService.verifyEmailCode(firebaseUID, code);

    res.status(200).json(result);
  } catch (error) {
    console.error('Verify email code controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Email verification failed'
    });
  }
};

// SMS 2FA ENDPOINTS
export const generateSMSCode = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    const result = await twoFactorAuthService.generateSMSCode(firebaseUID, phoneNumber);

    // PLACEHOLDER: Replace with your SMS service
    // await sendSMSVerificationCode(phoneNumber, result.code);

    res.status(200).json({
      success: true,
      message: result.message,
      expiresIn: result.expiresIn,
      remaining: result.remaining
    });
  } catch (error) {
    console.error('Generate SMS code controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to generate SMS verification code'
    });
  }
};

export const verifySMSCode = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Verification code is required'
      });
    }

    const result = await twoFactorAuthService.verifySMSCode(firebaseUID, code);

    res.status(200).json(result);
  } catch (error) {
    console.error('Verify SMS code controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'SMS verification failed'
    });
  }
};

// TOTP ENDPOINTS
export const generateTOTPSecret = async (req, res) => {
  try {
    const { uid: firebaseUID, email } = req.user;

    const result = await twoFactorAuthService.generateTOTPSecret(firebaseUID, email);

    res.status(200).json(result);
  } catch (error) {
    console.error('Generate TOTP secret controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to generate TOTP secret'
    });
  }
};

export const confirmTOTPSetup = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'TOTP verification code is required'
      });
    }

    const result = await twoFactorAuthService.confirmTOTPSetup(firebaseUID, code);

    res.status(200).json(result);
  } catch (error) {
    console.error('Confirm TOTP setup controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'TOTP setup confirmation failed'
    });
  }
};

export const verifyTOTPCode = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'TOTP code is required'
      });
    }

    const result = await twoFactorAuthService.verifyTOTPCode(firebaseUID, code);

    res.status(200).json(result);
  } catch (error) {
    console.error('Verify TOTP code controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'TOTP verification failed'
    });
  }
};

export const disableTOTP = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;

    const result = await twoFactorAuthService.disableTOTP(firebaseUID);

    res.status(200).json(result);
  } catch (error) {
    console.error('Disable TOTP controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to disable TOTP'
    });
  }
};

// STATUS AND UTILITY ENDPOINTS
export const get2FAStatus = async (req, res) => {
  try {
    const { uid: firebaseUID } = req.user;

    const result = await twoFactorAuthService.get2FAStatus(firebaseUID);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Get 2FA status controller error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to get 2FA status'
    });
  }
};

export const healthCheck = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      message: '2FA service is healthy',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '2FA service health check failed'
    });
  }
};