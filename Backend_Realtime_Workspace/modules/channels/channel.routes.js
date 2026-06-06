// ============================================================================
// TeamSpot — Channel Routes
// ============================================================================

import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { channelController } from "./channel.controller.js";
import { 
  createChannelSchema, 
  updateChannelSchema, 
  addMemberSchema,
  sendMessageSchema
} from "./channel.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Channels
router.post(
  '/', 
  validate(createChannelSchema),
  asyncHandler(channelController.createChannel)
);

router.get('/', asyncHandler(channelController.getChannels));
router.get('/:id', asyncHandler(channelController.getChannelById));

router.put(
  '/:id', 
  validate(updateChannelSchema),
  asyncHandler(channelController.updateChannel)
);

router.delete('/:id', asyncHandler(channelController.deleteChannel));

// Members
router.post(
  '/:id/members', 
  validate(addMemberSchema),
  asyncHandler(channelController.addMember)
);

router.delete('/:id/members/:memberId', asyncHandler(channelController.removeMember));

// Messages
router.get('/:id/messages', asyncHandler(channelController.getMessages));

router.post(
  '/:id/messages', 
  upload.array('attachments', 5),
  multerErrorHandler,
  validate(sendMessageSchema),
  asyncHandler(channelController.sendMessage)
);

export default router;
