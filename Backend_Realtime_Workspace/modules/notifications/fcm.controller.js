import {
    sendFCMToDevice, sendFCMToMultipleDevices, sendFCMToTopic, subscribeToTopic, unsubscribeFromTopic,
    validateFCMToken, NOTIFICATION_TYPES
} from '../services/fcmServices.js';

/**
 * FCM Controller for Teamspot Workspace App
 * Provides HTTP endpoints for notification management
 */

/**
 * Send notification to a single device
 * POST /api/notifications/send
 * Body: { fcmToken, type, data?, options? }
 */
export const sendNotification = async (req, res) => {
  try {
    const { fcmToken, type, data = {}, options = {} } = req.body;

    // Validation
    if (!fcmToken || !type) {
      return res.status(400).json({
        success: false,
        message: 'fcmToken and type are required',
        availableTypes: Object.values(NOTIFICATION_TYPES)
      });
    }

    if (!Object.values(NOTIFICATION_TYPES).includes(type)) {
      return res.status(400).json({
        success: false,
        message: `Invalid notification type: ${type}`,
        availableTypes: Object.values(NOTIFICATION_TYPES)
      });
    }

    const result = await sendFCMToDevice(fcmToken, type, data, options);

    if (result.success) {
      res.json({
        success: true,
        message: 'Notification sent successfully',
        messageId: result.messageId,
        timestamp: result.timestamp
      });
    } else {
      const statusCode = result.shouldRemoveToken ? 410 : 500;
      res.status(statusCode).json({
        success: false,
        message: result.error,
        errorCode: result.errorCode,
        shouldRemoveToken: result.shouldRemoveToken || false
      });
    }
  } catch (error) {
    console.error('Send notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Send notification to multiple devices
 * POST /api/notifications/send-multiple
 * Body: { fcmTokens, type, data?, options? }
 */
export const sendMultipleNotifications = async (req, res) => {
  try {
    const { fcmTokens, type, data = {}, options = {} } = req.body;

    // Validation
    if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'fcmTokens array is required and must not be empty'
      });
    }

    if (!type || !Object.values(NOTIFICATION_TYPES).includes(type)) {
      return res.status(400).json({
        success: false,
        message: `Invalid notification type: ${type}`,
        availableTypes: Object.values(NOTIFICATION_TYPES)
      });
    }

    const result = await sendFCMToMultipleDevices(fcmTokens, type, data, options);

    if (result.success) {
      res.json({
        success: true,
        message: 'Notifications sent',
        successCount: result.successCount,
        failureCount: result.failureCount,
        invalidTokens: result.invalidTokens,
        totalSent: fcmTokens.length
      });
    } else {
      res.status(500).json({
        success: false,
        message: result.error,
        errorCode: result.errorCode
      });
    }
  } catch (error) {
    console.error('Send multiple notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Send notification to topic (broadcast)
 * POST /api/notifications/send-to-topic
 * Body: { topic, type, data?, options? }
 */
export const sendTopicNotification = async (req, res) => {
  try {
    const { topic, type, data = {}, options = {} } = req.body;

    // Validation
    if (!topic || !type) {
      return res.status(400).json({
        success: false,
        message: 'topic and type are required'
      });
    }

    if (!Object.values(NOTIFICATION_TYPES).includes(type)) {
      return res.status(400).json({
        success: false,
        message: `Invalid notification type: ${type}`,
        availableTypes: Object.values(NOTIFICATION_TYPES)
      });
    }

    const result = await sendFCMToTopic(topic, type, data, options);

    if (result.success) {
      res.json({
        success: true,
        message: 'Topic notification sent successfully',
        messageId: result.messageId,
        timestamp: result.timestamp,
        topic: topic
      });
    } else {
      res.status(500).json({
        success: false,
        message: result.error,
        errorCode: result.errorCode
      });
    }
  } catch (error) {
    console.error('Send topic notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Subscribe devices to a topic
 * POST /api/notifications/subscribe
 * Body: { tokens, topic }
 */
export const subscribeDevicesToTopic = async (req, res) => {
  try {
    const { tokens, topic } = req.body;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'tokens array is required and must not be empty'
      });
    }

    if (!topic) {
      return res.status(400).json({
        success: false,
        message: 'topic is required'
      });
    }

    const result = await subscribeToTopic(tokens, topic);

    if (result.success) {
      res.json({
        success: true,
        message: `Successfully subscribed ${tokens.length} devices to topic: ${topic}`,
        topic: topic,
        deviceCount: tokens.length
      });
    } else {
      res.status(500).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Subscribe to topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Unsubscribe devices from a topic
 * POST /api/notifications/unsubscribe
 * Body: { tokens, topic }
 */
export const unsubscribeDevicesFromTopic = async (req, res) => {
  try {
    const { tokens, topic } = req.body;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'tokens array is required and must not be empty'
      });
    }

    if (!topic) {
      return res.status(400).json({
        success: false,
        message: 'topic is required'
      });
    }

    const result = await unsubscribeFromTopic(tokens, topic);

    if (result.success) {
      res.json({
        success: true,
        message: `Successfully unsubscribed ${tokens.length} devices from topic: ${topic}`,
        topic: topic,
        deviceCount: tokens.length
      });
    } else {
      res.status(500).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Unsubscribe from topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Validate FCM token
 * POST /api/notifications/validate-token
 * Body: { token }
 */
export const validateToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'token is required'
      });
    }

    const result = await validateFCMToken(token);

    res.json({
      success: true,
      valid: result.valid,
      shouldRemove: result.shouldRemove || false,
      error: result.error || null
    });
  } catch (error) {
    console.error('Validate token error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Get available notification types
 * GET /api/notifications/types
 */
export const getNotificationTypes = (req, res) => {
  res.json({
    success: true,
    types: NOTIFICATION_TYPES,
    description: {
      [NOTIFICATION_TYPES.TWO_FA]: 'Two-factor authentication codes',
      [NOTIFICATION_TYPES.TASK_ASSIGNED]: 'New task assignments',
      [NOTIFICATION_TYPES.TASK_COMPLETED]: 'Task completion notifications',
      [NOTIFICATION_TYPES.TASK_OVERDUE]: 'Overdue task alerts',
      [NOTIFICATION_TYPES.PROJECT_INVITE]: 'Project invitation notifications',
      [NOTIFICATION_TYPES.TEAM_MENTION]: 'Team mention alerts',
      [NOTIFICATION_TYPES.MESSAGE_RECEIVED]: 'New message notifications',
      [NOTIFICATION_TYPES.MEETING_REMINDER]: 'Meeting reminders',
      [NOTIFICATION_TYPES.DEADLINE_APPROACHING]: 'Deadline alerts',
      [NOTIFICATION_TYPES.WORKSPACE_UPDATE]: 'General workspace updates'
    }
  });
};
