import admin from 'firebase-admin';

// Notification types for different workspace events
export const NOTIFICATION_TYPES = {
  TWO_FA: 'two_fa',
  TASK_ASSIGNED: 'task_assigned',
  TASK_COMPLETED: 'task_completed',
  TASK_OVERDUE: 'task_overdue',
  PROJECT_INVITE: 'project_invite',
  TEAM_MENTION: 'team_mention',
  MESSAGE_RECEIVED: 'message_received',
  MEETING_REMINDER: 'meeting_reminder',
  DEADLINE_APPROACHING: 'deadline_approaching',
  WORKSPACE_UPDATE: 'workspace_update'
};

// Notification templates for consistent messaging
const NOTIFICATION_TEMPLATES = {
  [NOTIFICATION_TYPES.TWO_FA]: {
    title: 'Verification Code',
    body: (data) => `Your verification code is: ${data.code}`,
    icon: 'security'
  },
  [NOTIFICATION_TYPES.TASK_ASSIGNED]: {
    title: 'New Task Assigned',
    body: (data) => `You've been assigned: ${data.taskTitle}`,
    icon: 'task'
  },
  [NOTIFICATION_TYPES.TASK_COMPLETED]: {
    title: 'Task Completed',
    body: (data) => `${data.userName} completed: ${data.taskTitle}`,
    icon: 'check'
  },
  [NOTIFICATION_TYPES.TASK_OVERDUE]: {
    title: 'Task Overdue',
    body: (data) => `Overdue: ${data.taskTitle}`,
    icon: 'warning'
  },
  [NOTIFICATION_TYPES.PROJECT_INVITE]: {
    title: 'Project Invitation',
    body: (data) => `You've been invited to join ${data.projectName}`,
    icon: 'team'
  },
  [NOTIFICATION_TYPES.TEAM_MENTION]: {
    title: 'You were mentioned',
    body: (data) => `${data.userName} mentioned you in ${data.context}`,
    icon: 'mention'
  },
  [NOTIFICATION_TYPES.MESSAGE_RECEIVED]: {
    title: 'New Message',
    body: (data) => `${data.senderName}: ${data.preview}`,
    icon: 'message'
  },
  [NOTIFICATION_TYPES.MEETING_REMINDER]: {
    title: 'Meeting Reminder',
    body: (data) => `${data.meetingTitle} starts in ${data.timeRemaining}`,
    icon: 'calendar'
  },
  [NOTIFICATION_TYPES.DEADLINE_APPROACHING]: {
    title: 'Deadline Approaching',
    body: (data) => `${data.taskTitle} is due ${data.timeRemaining}`,
    icon: 'clock'
  },
  [NOTIFICATION_TYPES.WORKSPACE_UPDATE]: {
    title: 'Workspace Update',
    body: (data) => data.message,
    icon: 'info'
  }
};

/**
 * Send FCM notification to a single device
 * @param {string} fcmToken - Device FCM token
 * @param {string} type - Notification type from NOTIFICATION_TYPES
 * @param {Object} data - Data payload for the notification
 * @param {Object} options - Additional options
 */
export const sendFCMToDevice = async (fcmToken, type, data = {}, options = {}) => {
  if (!fcmToken || !type) {
    throw new Error('FCM token and notification type are required');
  }

  const template = NOTIFICATION_TEMPLATES[type];
  if (!template) {
    throw new Error(`Unknown notification type: ${type}`);
  }

  const message = {
    token: fcmToken,
    notification: {
      title: template.title,
      body: typeof template.body === 'function' ? template.body(data) : template.body,
      icon: options.icon || template.icon,
      sound: options.sound || 'default',
      badge: options.badge || '1'
    },
    data: {
      type,
      timestamp: new Date().toISOString(),
      clickAction: options.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
      ...data
    },
    android: {
      priority: options.priority || 'high',
      notification: {
        channelId: options.channelId || 'teamspot_notifications',
        color: options.color || '#4285F4',
        icon: options.androidIcon || 'ic_notification'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: options.sound || 'default',
          badge: options.badge || 1,
          contentAvailable: true
        }
      },
      headers: {
        'apns-priority': '10'
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('FCM notification sent successfully:', response);
    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('FCM notification failed:', error);

    // Handle token registration errors
    if (error.code === 'messaging/registration-token-not-registered' || error.code === 'messaging/invalid-registration-token') {
      return {
        success: false,
        error: error.message,
        shouldRemoveToken: true,
        errorCode: error.code
      };
    }

    return {
      success: false,
      error: error.message,
      errorCode: error.code
    };
  }
};

/**
 * Send FCM notification to multiple devices
 * @param {Array} fcmTokens - Array of FCM tokens
 * @param {string} type - Notification type
 * @param {Object} data - Data payload
 * @param {Object} options - Additional options
 */
export const sendFCMToMultipleDevices = async (fcmTokens, type, data = {}, options = {}) => {
  if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
    throw new Error('FCM tokens array is required and must not be empty');
  }

  const template = NOTIFICATION_TEMPLATES[type];
  if (!template) {
    throw new Error(`Unknown notification type: ${type}`);
  }

  const message = {
    tokens: fcmTokens,
    notification: {
      title: template.title,
      body: typeof template.body === 'function' ? template.body(data) : template.body,
      icon: options.icon || template.icon
    },
    data: {
      type,
      timestamp: new Date().toISOString(),
      clickAction: options.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
      ...data
    },
    android: {
      priority: options.priority || 'high',
      notification: {
        channelId: options.channelId || 'teamspot_notifications',
        color: options.color || '#4285F4'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: options.sound || 'default',
          badge: options.badge || 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    const results = {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses,
      invalidTokens: []
    };

    // Collect invalid tokens for cleanup
    response.responses.forEach((resp, idx) => {
      if (!resp.success && (resp.error?.code === 'messaging/registration-token-not-registered' || resp.error?.code === 'messaging/invalid-registration-token')) {
        results.invalidTokens.push(fcmTokens[idx]);
      }
    });

    console.log(`FCM multicast sent. Success: ${response.successCount}, Failed: ${response.failureCount}`);
    return results;
  } catch (error) {
    console.error('FCM multicast failed:', error);
    return {
      success: false,
      error: error.message,
      errorCode: error.code
    };
  }
};

/**
 * Send notification to topic (for broadcast messages)
 * @param {string} topic - Topic name (e.g., 'workspace_123', 'project_456')
 * @param {string} type - Notification type
 * @param {Object} data - Data payload
 * @param {Object} options - Additional options
 */
export const sendFCMToTopic = async (topic, type, data = {}, options = {}) => {
  if (!topic || !type) {
    throw new Error('Topic and notification type are required');
  }

  const template = NOTIFICATION_TEMPLATES[type];
  if (!template) {
    throw new Error(`Unknown notification type: ${type}`);
  }

  const message = {
    topic: topic,
    notification: {
      title: template.title,
      body: typeof template.body === 'function' ? template.body(data) : template.body,
      icon: options.icon || template.icon
    },
    data: {
      type,
      timestamp: new Date().toISOString(),
      ...data
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('FCM topic notification sent:', response);
    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('FCM topic notification failed:', error);
    return {
      success: false,
      error: error.message,
      errorCode: error.code
    };
  }
};

/**
 * Subscribe tokens to a topic
 * @param {Array} tokens - FCM tokens to subscribe
 * @param {string} topic - Topic name
 */
export const subscribeToTopic = async (tokens, topic) => {
  try {
    const response = await admin.messaging().subscribeToTopic(tokens, topic);
    console.log('Successfully subscribed to topic:', topic);
    return { success: true, response };
  } catch (error) {
    console.error('Failed to subscribe to topic:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Unsubscribe tokens from a topic
 * @param {Array} tokens - FCM tokens to unsubscribe
 * @param {string} topic - Topic name
 */
export const unsubscribeFromTopic = async (tokens, topic) => {
  try {
    const response = await admin.messaging().unsubscribeFromTopic(tokens, topic);
    console.log('Successfully unsubscribed from topic:', topic);
    return { success: true, response };
  } catch (error) {
    console.error('Failed to unsubscribe from topic:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Validate FCM token
 * @param {string} token - FCM token to validate
 */
export const validateFCMToken = async (token) => {
  try {
    // Send a dry run message to validate token
    const message = {
      token: token,
      data: { test: 'validation' },
      dryRun: true
    };

    await admin.messaging().send(message);
    return { valid: true };
  } catch (error) {
    return {
      valid: false,
      error: error.message,
      shouldRemove: error.code === 'messaging/registration-token-not-registered' || error.code === 'messaging/invalid-registration-token'
    };
  }
};
