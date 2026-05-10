import express from 'express';
import {
  addAttachment, addFollowUpAction, addMeetingNotes, addParticipant, addRecording, bulkDeleteMeetings, bulkUpdateMeetings,
  cancelRecurringSeries, checkConflicts, checkParticipantAvailability, convertMeetingTimezone, createFromTemplate, createMeeting,
  createMeetingTemplate, deleteMeeting, exportMeetingData, getAllMeetings, getCalendarView, getMeetingAnalytics, getMeetingById,
  getMeetingTemplates, getTodaysMeetings, getUpcomingMeetings, getUserConflicts, getUserInvitations, getUserMeetings, getUserMeetingStats,
  permanentlyDeleteMeeting, postponeMeeting, recordParticipantJoin, recordParticipantLeave, removeAttachment, removeParticipant,
  restoreMeeting, searchMeetings, sendInvitations, updateFollowUpStatus, updateMeeting, updateMeetingNotes, updateMeetingStatus,
  updateParticipantStatus, updateRecurringSeries, updateReminderSettings
} from '../../controllers/scheduleMeet.js';
import { firebaseAuthMiddleware } from '../middlewares/firebaseAuthMiddleware.js';
import { upload, multerErrorHandler } from '../services/cloudinary.js'; // <-- Add these imports

const router = express.Router();
router.use(firebaseAuthMiddleware);

// CREATE
router.post('/', upload.array('attachments', 10), multerErrorHandler, createMeeting);
router.post('/template',  createMeetingTemplate);
router.post('/from-template/:templateId',  createFromTemplate);

// READ
router.get('/',  getAllMeetings);
router.get('/:id',  getMeetingById);
router.get('/user/:userID',  getUserMeetings);
router.get('/user/:userID/today',  getTodaysMeetings);
router.get('/user/:userID/upcoming',  getUpcomingMeetings);
router.get('/user/:userID/invitations',  getUserInvitations);
router.get('/user/:userID/conflicts',  getUserConflicts);
router.get('/user/:userID/calendar',  getCalendarView);
router.get('/user/:userID/stats',  getUserMeetingStats);
router.get('/analytics/:companyName',  getMeetingAnalytics);
router.get('/templates',  getMeetingTemplates);
router.get('/search',  searchMeetings);
router.get('/export',  exportMeetingData);

// UPDATE
router.put('/:id',  updateMeeting);
router.patch('/:id/status',  updateMeetingStatus);
router.patch('/:id/postpone',  postponeMeeting);
router.patch('/:id/reminder',  updateReminderSettings);
router.patch('/:id/notes/:noteId',  updateMeetingNotes);
router.patch('/:id/convert-timezone',  convertMeetingTimezone);
router.patch('/:id/recurring',  updateRecurringSeries);
router.patch('/:id/cancel-recurring',  cancelRecurringSeries);
router.patch('/:id/followup/:actionId',  updateFollowUpStatus);

// PARTICIPANT MANAGEMENT
router.post('/:id/participants',  addParticipant);
router.delete('/:id/participants/:userID',  removeParticipant);
router.patch('/:id/participants/:userID/status', updateParticipantStatus);
router.patch('/:id/participants/:userID/join',  recordParticipantJoin);
router.patch('/:id/participants/:userID/leave',  recordParticipantLeave);

// ATTACHMENTS
router.post('/:id/attachments',  addAttachment);
router.delete('/:id/attachments/:attachmentId',  removeAttachment);

// NOTES
router.post('/:id/notes',  addMeetingNotes);

// RECORDINGS
router.post('/:id/recordings',  addRecording);

// FOLLOW-UPS
router.post('/:id/followup',  addFollowUpAction);

// BULK
router.patch('/bulk-update',  bulkUpdateMeetings);
router.patch('/bulk-delete',  bulkDeleteMeetings);

// CONFLICTS
router.get('/:id/conflicts',  checkConflicts);

// AVAILABILITY
router.get('/availability',  checkParticipantAvailability);

// INVITATIONS
router.post('/:id/invitations',  sendInvitations);

// DELETE/RESTORE
router.delete('/:id',  deleteMeeting);
router.delete('/:id/permanent',  permanentlyDeleteMeeting);
router.patch('/:id/restore',  restoreMeeting);

export default router;
