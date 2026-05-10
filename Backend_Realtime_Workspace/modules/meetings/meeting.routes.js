// ============================================================================
// TeamSpot — Meeting Routes
// ============================================================================

import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { meetingController } from "./meeting.controller.js";
import { 
  createMeetingSchema, 
  updateMeetingSchema,
  rsvpMeetingSchema
} from "./meeting.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

// Meeting CRUD
router.post(
  '/', 
  validate(createMeetingSchema),
  asyncHandler(meetingController.createMeeting)
);

router.get('/', asyncHandler(meetingController.getMeetings));
router.get('/:id', asyncHandler(meetingController.getMeetingById));

router.put(
  '/:id', 
  validate(updateMeetingSchema),
  asyncHandler(meetingController.updateMeeting)
);

router.delete('/:id', asyncHandler(meetingController.deleteMeeting));

// Actions
router.post(
  '/:id/rsvp', 
  validate(rsvpMeetingSchema),
  asyncHandler(meetingController.rsvp)
);

router.post(
  '/:id/join', 
  asyncHandler(meetingController.joinMeeting)
);

export default router;
