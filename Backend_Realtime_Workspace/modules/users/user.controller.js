// userInfoControllers.js - Improved version with better referral handling

import UserInfo from '../../models/userInfoModel.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.js';
import { calculateProfileCompletion } from './profile-completion.js';
import { assignReferralCode, useReferralCode, revokeReferralCode, autoRegenerateExpiredCodes, getReferralStats } from '../../core/helpers/referal-code.js';
import admin from 'firebase-admin';

// Utility functions (keep existing ones)
function ensureStringArray(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val.map(String);
  return [String(val)];
}

function ensureReferredToArray(val) {
  if (!val) return [];
  if (Array.isArray(val)) {
    return val.map((v) => (typeof v === 'string' ? { email: v } : v));
  }
  return [typeof val === 'string' ? { email: val } : val];
}

function ensureInvitedByArray(val) {
  if (!val) return [];
  if (Array.isArray(val)) {
    return val.map((v) => (typeof v === 'string' ? { inviterCode: v } : v));
  }
  return [typeof val === 'string' ? { inviterCode: val } : val];
}

// Create or update (upsert) user info for authenticated user with improved referral logic
export const createOrUpdateMyUserInfo = async (req, res) => {
  try {
    console.log('[createOrUpdateMyUserInfo] Called by:', req.user);
    const { email, uid } = req.user;
    const data = req.body;
    console.log('[createOrUpdateMyUserInfo] Incoming data:', data);

    // Ensure arrays are properly formatted
    data.interestsSkills = ensureStringArray(data.interestsSkills);
    data.referredTo = ensureReferredToArray(data.referredTo);
    data.invitedBy = ensureInvitedByArray(data.invitedBy);

    // Handle image upload (FIXED)
    if (req.file) {
      try {
        console.log('[createOrUpdateMyUserInfo] Image file detected:', {
          filename: req.file.originalname,
          mimetype: req.file.mimetype,
          size: req.file.size
        });

        const existingUser = await UserInfo.findOne({ email });

        // FIXED: Use correct parameters - buffer, originalname, folder
        const uploadResult = await uploadToCloudinary(
          req.file.buffer, // Use buffer, not path
          req.file.originalname, // Use original filename
          '/projects/workspace' // Folder parameter
        );

        console.log('[createOrUpdateMyUserInfo] Uploaded to Cloudinary:', uploadResult);

        data.profilePicture = uploadResult.url;
        data.profilePicturePublicId = uploadResult.public_id;

        if (existingUser && existingUser.profilePicturePublicId) {
          console.log('[createOrUpdateMyUserInfo] Deleting old Cloudinary image:', existingUser.profilePicturePublicId);
          await deleteFromCloudinary(existingUser.profilePicturePublicId);
        }
      } catch (uploadError) {
        console.error('[createOrUpdateMyUserInfo] Failed to upload image:', uploadError.message);
        return res.status(500).json({
          message: 'Failed to upload image',
          error: uploadError.message
        });
      }
    }

    // Always set userID and email from token
    data.userID = uid;
    data.email = email;

    // Check if this is a new user or existing user
    const existingUser = await UserInfo.findOne({ email });
    const isNewUser = !existingUser;

    // Store referral code for processing AFTER user creation/update
    const referralCodeToUse = data.inviteCode;

    // Remove inviteCode from data to prevent it from being saved as user's own code
    delete data.inviteCode;

    // Upsert user
    let userInfo = await UserInfo.findOneAndUpdate({ email }, { ...data, email, userID: uid }, { new: true, upsert: true, setDefaultsOnInsert: true });
    console.log('[createOrUpdateMyUserInfo] Upserted userInfo:', userInfo);

    // Always assign a referral code if user doesn't have one (ignore invitePermissions here)
    if (!userInfo.inviteCode) {
      try {
        // Directly assign code, bypassing invitePermissions check
        const code = await assignReferralCode(userInfo, {
          ignorePermissions: true
        });
        console.log('[createOrUpdateMyUserInfo] Assigned code (auto):', userInfo.inviteCode);
      } catch (err) {
        console.error('[createOrUpdateMyUserInfo] Referral code assignment failed:', err.message);
        return res.status(400).json({
          message: 'Referral code assignment failed',
          error: err.message
        });
      }
    }

    // Step 2: Process referral code if provided (user joining with someone's code)
    if (referralCodeToUse && data.permissionsLevel === 'member') {
      console.log('[createOrUpdateMyUserInfo] Processing referral code:', referralCodeToUse);

      const result = await useReferralCode({
        memberUser: userInfo,
        code: referralCodeToUse
      });

      if (!result.success) {
        console.warn('[createOrUpdateMyUserInfo] Referral code processing failed:', result.reason);
        return res.status(400).json({
          message: 'Invalid or expired referral code',
          reason: result.reason,
          regenerated: result.regenerated
        });
      }

      console.log('[createOrUpdateMyUserInfo] Successfully processed referral code');
    }

    // Recalculate profile completion and save
    userInfo.profileCompletion = calculateProfileCompletion(userInfo);
    await userInfo.save();

    console.log('[createOrUpdateMyUserInfo] Final userInfo:', {
      email: userInfo.email,
      inviteCode: userInfo.inviteCode,
      referredTo: userInfo.referredTo?.length || 0,
      invitedBy: userInfo.invitedBy?.length || 0
    });

    res.status(200).json(userInfo);
  } catch (err) {
    console.error('[createOrUpdateMyUserInfo] Failed to save user info:', err.message);
    res.status(500).json({
      message: 'Failed to save user info',
      error: err.message
    });
  }
};
// Update user info with improved referral handling
export const updateMyUserInfo = async (req, res) => {
  try {
    console.log('[updateMyUserInfo] Called by:', req.user);
    const { email, uid } = req.user;
    const data = req.body;
    console.log('[updateMyUserInfo] Incoming data:', data);

    // Ensure arrays are properly formatted
    data.interestsSkills = ensureStringArray(data.interestsSkills);
    data.referredTo = ensureReferredToArray(data.referredTo);
    data.invitedBy = ensureInvitedByArray(data.invitedBy);

    // Handle image upload (keep existing logic)
    if (req.file) {
      try {
        console.log('[updateMyUserInfo] Image file detected:', req.file.path);
        const existingUser = await UserInfo.findOne({ email });
        const uploadResult = await uploadToCloudinary(req.file.path, '/projects/banking/profile-pictures');
        console.log('[updateMyUserInfo] Uploaded to Cloudinary:', uploadResult);

        data.profilePicture = uploadResult.url;
        data.profilePicturePublicId = uploadResult.public_id;

        if (existingUser && existingUser.profilePicturePublicId) {
          console.log('[updateMyUserInfo] Deleting old Cloudinary image:', existingUser.profilePicturePublicId);
          await deleteFromCloudinary(existingUser.profilePicturePublicId);
        }
      } catch (uploadError) {
        console.error('[updateMyUserInfo] Failed to upload image:', uploadError.message);
        return res.status(500).json({
          message: 'Failed to upload image',
          error: uploadError.message
        });
      }
    }

    // Always set userID and email from token
    data.userID = uid;
    data.email = email;

    // Store referral code for processing
    const referralCodeToUse = data.inviteCode;
    delete data.inviteCode; // Remove from update data

    let user = await UserInfo.findOneAndUpdate({ email }, { $set: { ...data, userID: uid, email } }, { new: true });

    if (!user) {
      console.warn('[updateMyUserInfo] User info not found for email:', email);
      return res.status(404).json({ message: 'User info not found' });
    }

    // Generate referral code if user doesn't have one and has appropriate permissions
    if (['admin', 'manager', 'employee', 'member'].includes(data.permissionsLevel) && !user.inviteCode) {
      try {
        console.log('[updateMyUserInfo] Assigning referral code...');
        await assignReferralCode(user);
      } catch (err) {
        console.error('[updateMyUserInfo] Referral code assignment failed:', err.message);
        return res.status(400).json({
          message: 'Referral code assignment failed',
          error: err.message
        });
      }
    }

    // Process referral code if provided
    if (referralCodeToUse && data.permissionsLevel === 'member') {
      console.log('[updateMyUserInfo] Using referral code:', referralCodeToUse);
      const result = await useReferralCode({
        memberUser: user,
        code: referralCodeToUse
      });

      if (!result.success) {
        console.warn('[updateMyUserInfo] Invalid or expired referral code:', referralCodeToUse);
        return res.status(400).json({
          message: 'Invalid or expired referral code',
          reason: result.reason,
          regenerated: result.regenerated
        });
      }
    }

    // Recalculate profile completion
    user.profileCompletion = calculateProfileCompletion(user);
    await user.save();

    console.log('[updateMyUserInfo] Final user:', {
      email: user.email,
      inviteCode: user.inviteCode,
      referredTo: user.referredTo?.length || 0,
      invitedBy: user.invitedBy?.length || 0
    });

    res.json(user);
  } catch (err) {
    console.error('[updateMyUserInfo] Failed to update user info:', err.message);
    res.status(500).json({
      message: 'Failed to update user info',
      error: err.message
    });
  }
};

// New endpoint: Get referral statistics for authenticated user
export const getMyReferralStats = async (req, res) => {
  try {
    console.log('[getMyReferralStats] Called by:', req.user);
    const { email } = req.user;

    const user = await UserInfo.findOne({ email });
    if (!user) {
      console.warn('[getMyReferralStats] User not found for email:', email);
      return res.status(404).json({ message: 'User not found' });
    }

    const stats = await getReferralStats(user._id);
    res.json(stats);
  } catch (err) {
    console.error('[getMyReferralStats] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// New endpoint: Get referral chain (who invited whom)
export const getReferralChain = async (req, res) => {
  try {
    console.log('[getReferralChain] Called by:', req.user);
    const { email } = req.user;

    const user = await UserInfo.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Build referral chain upwards (who invited this user)
    const buildUpwardChain = async (userEmail, chain = []) => {
      const currentUser = await UserInfo.findOne({ email: userEmail });
      if (!currentUser) return chain;

      chain.push({
        email: currentUser.email,
        name: currentUser.fullName || currentUser.displayName || currentUser.email,
        inviteCode: currentUser.inviteCode,
        level: chain.length
      });

      if (currentUser.invitedBy && currentUser.invitedBy.length > 0) {
        const inviter = currentUser.invitedBy[0]; // Get first inviter
        return await buildUpwardChain(inviter.email, chain);
      }

      return chain;
    };

    // Build downward chain (who this user invited)
    const buildDownwardChain = async (userEmail, visited = new Set()) => {
      if (visited.has(userEmail)) return [];
      visited.add(userEmail);

      const currentUser = await UserInfo.findOne({ email: userEmail });
      if (!currentUser || !currentUser.referredTo) return [];

      const chain = [];
      for (const referred of currentUser.referredTo) {
        const referredUser = await UserInfo.findOne({ email: referred.email });
        if (referredUser) {
          const subChain = await buildDownwardChain(referred.email, visited);
          chain.push({
            email: referredUser.email,
            name: referredUser.fullName || referredUser.displayName || referredUser.email,
            inviteCode: referredUser.inviteCode,
            children: subChain
          });
        }
      }
      return chain;
    };

    const upwardChain = await buildUpwardChain(email);
    const downwardChain = await buildDownwardChain(email);

    res.json({
      currentUser: {
        email: user.email,
        name: user.fullName || user.displayName || user.email,
        inviteCode: user.inviteCode
      },
      upwardChain: upwardChain.reverse(), // Root first
      downwardChain
    });
  } catch (err) {
    console.error('[getReferralChain] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Fetch user by invite code or email
export const getUserByInviteCodeOrEmail = async (req, res) => {
  try {
    const { inviteCode, email } = req.query;
    let user = null;

    if (inviteCode) {
      user = await UserInfo.findOne({ inviteCode });
    } else if (email) {
      user = await UserInfo.findOne({ email });
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (err) {
    console.error('[getUserByInviteCodeOrEmail] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Keep all existing endpoints unchanged
export const revokeUserReferralCode = async (req, res) => {
  try {
    console.log('[revokeUserReferralCode] Called by:', req.user, 'for userId:', req.params.id);
    const { id } = req.params;
    const user = await UserInfo.findById(id);
    if (!user) {
      console.warn('[revokeUserReferralCode] User not found:', id);
      return res.status(404).json({ message: 'User not found' });
    }
    await revokeReferralCode(user);
    console.log('[revokeUserReferralCode] Referral code revoked for user:', id);
    res.json({ message: 'Referral code revoked' });
  } catch (err) {
    console.error('[revokeUserReferralCode] Failed to revoke referral code:', err.message);
    res.status(500).json({ message: 'Failed to revoke referral code', error: err.message });
  }
};

export const deleteMyUserInfo = async (req, res) => {
  try {
    console.log('[deleteMyUserInfo] Called by:', req.user);
    const { email, uid } = req.user;
    const user = await UserInfo.findOne({ email, userID: uid });

    if (!user) {
      console.warn('[deleteMyUserInfo] User info not found for email:', email);
      return res.status(404).json({ message: 'User info not found' });
    }

    if (user.profilePicturePublicId) {
      try {
        console.log('[deleteMyUserInfo] Deleting Cloudinary image:', user.profilePicturePublicId);
        await deleteFromCloudinary(user.profilePicturePublicId);
      } catch (cloudinaryError) {
        console.error('[deleteMyUserInfo] Failed to delete image from Cloudinary:', cloudinaryError);
      }
    }

    await UserInfo.findOneAndDelete({ email, userID: uid });
    console.log('[deleteMyUserInfo] User info deleted for email:', email);

    try {
      await admin.auth().deleteUser(uid);
      console.log('[deleteMyUserInfo] Firebase user deleted:', uid);
    } catch (firebaseError) {
      if (firebaseError.code === 'auth/user-not-found') {
        console.warn('[deleteMyUserInfo] Firebase user not found:', uid);
      } else {
        console.error('[deleteMyUserInfo] Failed to delete Firebase user:', firebaseError.message);
      }
    }

    res.json({ message: 'User info and Firebase user deleted' });
  } catch (err) {
    console.error('[deleteMyUserInfo] Failed to delete user info:', err.message);
    res.status(500).json({ message: 'Failed to delete user info', error: err.message });
  }
};

export const uploadProfilePicture = async (req, res) => {
  try {
    console.log('[uploadProfilePicture] Called by:', req.user);
    const { email, uid } = req.user;

    if (!req.file) {
      console.warn('[uploadProfilePicture] No file provided');
      return res.status(400).json({ message: 'No file provided' });
    }

    const existingUser = await UserInfo.findOne({ email, userID: uid });
    if (!existingUser) {
      console.warn('[uploadProfilePicture] User info not found for email:', email);
      return res.status(404).json({ message: 'User info not found' });
    }

    try {
      const uploadResult = await uploadToCloudinary(req.file.path, '/projects/banking/profile-pictures');
      console.log('[uploadProfilePicture] Uploaded to Cloudinary:', uploadResult);

      if (existingUser.profilePicturePublicId) {
        console.log('[uploadProfilePicture] Deleting old Cloudinary image:', existingUser.profilePicturePublicId);
        await deleteFromCloudinary(existingUser.profilePicturePublicId);
      }

      const updatedUser = await UserInfo.findOneAndUpdate(
        { email, userID: uid },
        {
          $set: {
            profilePicture: uploadResult.url,
            profilePicturePublicId: uploadResult.public_id
          }
        },
        { new: true }
      );

      updatedUser.profileCompletion = calculateProfileCompletion(updatedUser);
      await updatedUser.save();
      console.log('[uploadProfilePicture] Updated user:', updatedUser);

      res.json({
        message: 'Profile picture uploaded successfully',
        profilePicture: uploadResult.url,
        user: updatedUser
      });
    } catch (uploadError) {
      console.error('[uploadProfilePicture] Failed to upload image:', uploadError.message);
      return res.status(500).json({
        message: 'Failed to upload image',
        error: uploadError.message
      });
    }
  } catch (err) {
    console.error('[uploadProfilePicture] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

export const getAllUserInfos = async (req, res) => {
  try {
    console.log('[getAllUserInfos] Called by:', req.user);
    const users = await UserInfo.find();
    res.json(users);
  } catch (err) {
    console.error('[getAllUserInfos] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

export const getMyUserInfo = async (req, res) => {
  try {
    console.log('[getMyUserInfo] Called by:', req.user);
    const { email, uid } = req.user;
    const user = await UserInfo.findOne({ email, userID: uid });
    if (!user) {
      console.warn('[getMyUserInfo] User info not found for email:', email);
      return res.status(404).json({ message: 'User info not found' });
    }
    res.json(user);
  } catch (err) {
    console.error('[getMyUserInfo] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

export const getUserInfoById = async (req, res) => {
  try {
    console.log('[getUserInfoById] Called by:', req.user, 'for userId:', req.params.id);
    const { id } = req.params;
    const user = await UserInfo.findById(id);
    if (!user) {
      console.warn('[getUserInfoById] User info not found for id:', id);
      return res.status(404).json({ message: 'User info not found' });
    }
    res.json(user);
  } catch (err) {
    console.error('[getUserInfoById] Server error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

export const regenerateMyInviteCode = async (req, res) => {
  try {
    console.log('[regenerateMyInviteCode] Called by:', req.user);
    const { email } = req.user;
    const user = await UserInfo.findOne({ email });
    if (!user) {
      console.warn('[regenerateMyInviteCode] User not found for email:', email);
      return res.status(404).json({ message: 'User not found' });
    }
    try {
      // Only allow admin to regenerate
      if (user.permissionsLevel !== 'admin') {
        return res.status(403).json({ message: 'Only admin can regenerate invite code' });
      }
      await assignReferralCode(user); // normal permission check
      console.log('[regenerateMyInviteCode] Invite code regenerated:', user.inviteCode);
    } catch (err) {
      console.error('[regenerateMyInviteCode] Failed to assign referral code:', err.message);
      return res.status(400).json({ message: err.message });
    }
    res.json({
      message: 'Invite code regenerated',
      inviteCode: user.inviteCode,
      inviteCodeExpiry: user.inviteCodeExpiry
    });
  } catch (err) {
    console.error('[regenerateMyInviteCode] Failed to regenerate invite code:', err.message);
    res.status(500).json({
      message: 'Failed to regenerate invite code',
      error: err.message
    });
  }
};

export const updateInvitePermissions = async (req, res) => {
  try {
    console.log('[updateInvitePermissions] Called by:', req.user, 'for userId:', req.params.id, 'with body:', req.body);
    const { id } = req.params;
    const { invitePermissions } = req.body;

    const user = await UserInfo.findById(id);
    if (!user) {
      console.warn('[updateInvitePermissions] User not found for id:', id);
      return res.status(404).json({ message: 'User not found' });
    }

    user.invitePermissions = {
      ...user.invitePermissions,
      ...invitePermissions
    };
    await user.save();

    console.log('[updateInvitePermissions] Updated invitePermissions:', user.invitePermissions);
    res.json({
      message: 'Invite permissions updated',
      invitePermissions: user.invitePermissions
    });
  } catch (err) {
    console.error('[updateInvitePermissions] Failed to update invite permissions:', err.message);
    res.status(500).json({
      message: 'Failed to update invite permissions',
      error: err.message
    });
  }
};
