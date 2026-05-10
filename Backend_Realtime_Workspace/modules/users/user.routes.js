// ============================================================================
// TeamSpot — User Routes
// ============================================================================

import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload } from '../../infrastructure/storage/cloudinary.service.js';

import { userController } from "./user.controller.js";
import { updateUserSchema } from "./user.validation.js";

const router = express.Router();

// Require auth for all user routes
router.use(firebaseAuthMiddleware);

router.get('/me', asyncHandler(userController.getMyProfile));

router.put(
  '/me', 
  validate(updateUserSchema),
  asyncHandler(userController.updateMyProfile)
);

router.delete('/me', asyncHandler(userController.deleteMyProfile));

router.post(
  '/me/upload-picture', 
  upload.single('profilePicture'), 
  asyncHandler(userController.uploadProfilePicture)
);

// Admin / Internal use
router.get('/', asyncHandler(userController.getAllUsers));
router.get('/:id', asyncHandler(userController.getUserById));

export default router;
