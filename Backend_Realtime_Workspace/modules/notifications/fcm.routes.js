import express from 'express';
import {
  sendNotification, sendMultipleNotifications, sendTopicNotification, subscribeDevicesToTopic,
  unsubscribeDevicesFromTopic, validateToken, getNotificationTypes
} from './fcm.controller.js';
import { authenticate } from '../../middlewares/auth.middleware.js';

const router = express.Router();


router.use(authenticate);

// Notification endpoints
router.post('/send', sendNotification);
router.post('/send-multiple', sendMultipleNotifications);
router.post('/send-to-topic', sendTopicNotification);
router.post('/subscribe', subscribeDevicesToTopic);
router.post('/unsubscribe', unsubscribeDevicesFromTopic);
router.post('/validate-token', validateToken);
router.get('/types', getNotificationTypes);

export default router;
