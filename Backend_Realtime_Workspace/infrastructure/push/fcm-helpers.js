// ============================================================================
// TeamSpot — FCM Notification Helpers
// High-level push notification API for all workspace events
// ============================================================================

import { sendPushNotification, sendMulticast, sendToTopic } from "./fcm.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("FCMHelpers");

// ============================================================================
// NOTIFICATION TYPE CONSTANTS
// ============================================================================

export const NOTIFICATION_TYPES = {
  TWO_FA: "TWO_FA",
  TASK_ASSIGNED: "TASK_ASSIGNED",
  TASK_COMPLETED: "TASK_COMPLETED",
  TASK_OVERDUE: "TASK_OVERDUE",
  PROJECT_INVITE: "PROJECT_INVITE",
  TEAM_MENTION: "TEAM_MENTION",
  MESSAGE_RECEIVED: "MESSAGE_RECEIVED",
  MEETING_REMINDER: "MEETING_REMINDER",
  DEADLINE_APPROACHING: "DEADLINE_APPROACHING",
  WORKSPACE_UPDATE: "WORKSPACE_UPDATE",
};

// ============================================================================
// TASK NOTIFICATIONS
// ============================================================================

export async function notifyTaskAssigned(token, taskData) {
  return sendPushNotification({
    token,
    title: `📋 New Task: ${taskData.taskTitle}`,
    body: `${taskData.assignedBy} assigned you a task in ${taskData.projectName}`,
    data: { type: NOTIFICATION_TYPES.TASK_ASSIGNED, taskId: taskData.id, projectName: taskData.projectName },
  });
}

export async function notifyTaskCompleted(tokens, taskData) {
  return sendMulticast({
    tokens,
    title: `✅ Task Completed: ${taskData.taskTitle}`,
    body: `${taskData.completedBy} completed the task in ${taskData.projectName}`,
    data: { type: NOTIFICATION_TYPES.TASK_COMPLETED, taskId: taskData.id },
  });
}

export async function notifyTaskOverdue(token, taskData) {
  return sendPushNotification({
    token,
    title: `🚨 Task Overdue: ${taskData.taskTitle}`,
    body: `This task is ${taskData.overdueDays} day(s) overdue`,
    data: { type: NOTIFICATION_TYPES.TASK_OVERDUE, taskId: taskData.taskId },
  });
}

export async function notifyDeadlineApproaching(token, deadlineData) {
  return sendPushNotification({
    token,
    title: `⏰ Deadline: ${deadlineData.taskTitle}`,
    body: `Due in ${deadlineData.timeRemaining}`,
    data: { type: NOTIFICATION_TYPES.DEADLINE_APPROACHING, taskId: deadlineData.taskId },
  });
}

// ============================================================================
// MEETING NOTIFICATIONS
// ============================================================================

export async function sendMeetingReminder(tokens, meetingData) {
  return sendMulticast({
    tokens,
    title: `📅 Meeting in ${meetingData.timeRemaining}`,
    body: meetingData.meetingTitle,
    data: { type: NOTIFICATION_TYPES.MEETING_REMINDER, meetingId: meetingData.meetingId, meetingLink: meetingData.meetingLink },
  });
}

// ============================================================================
// COMMUNICATION NOTIFICATIONS
// ============================================================================

export async function notifyTeamMention(token, mentionData) {
  return sendPushNotification({
    token,
    title: `💬 @mentioned in #${mentionData.channelName}`,
    body: `${mentionData.userName}: ${mentionData.message?.slice(0, 80)}`,
    data: { type: NOTIFICATION_TYPES.TEAM_MENTION, channelId: mentionData.channelId, messageId: mentionData.messageId },
  });
}

export async function notifyNewMessage(token, messageData) {
  const title = messageData.isDirectMessage
    ? `💬 ${messageData.senderName}`
    : `💬 #${messageData.channelName}`;
  return sendPushNotification({
    token,
    title,
    body: messageData.preview?.slice(0, 100),
    data: { type: NOTIFICATION_TYPES.MESSAGE_RECEIVED, channelId: messageData.channelId },
  });
}

// ============================================================================
// WORKSPACE / PROJECT NOTIFICATIONS
// ============================================================================

export async function sendProjectInvite(token, inviteData) {
  return sendPushNotification({
    token,
    title: `🎯 Project Invite: ${inviteData.projectName}`,
    body: `${inviteData.invitedBy} invited you as ${inviteData.role}`,
    data: { type: NOTIFICATION_TYPES.PROJECT_INVITE, projectId: inviteData.projectId },
  });
}

export async function broadcastWorkspaceUpdate(workspaceId, updateData) {
  return sendToTopic(`workspace_${workspaceId}`, {
    title: `🏢 Workspace Update`,
    body: updateData.message,
    data: { type: NOTIFICATION_TYPES.WORKSPACE_UPDATE, workspaceId, updateType: updateData.updateType },
  });
}

// ============================================================================
// TOPIC HELPERS
// ============================================================================

export const getWorkspaceTopic = (id) => `workspace_${id}`;
export const getProjectTopic = (id) => `project_${id}`;
export const getTeamTopic = (id) => `team_${id}`;
export const getUserTopic = (id) => `user_${id}`;

// ============================================================================
// SMART NOTIFICATION — Auto-routes to single, multi, or topic
// ============================================================================

export async function sendSmartNotification(recipients, notification) {
  if (typeof recipients === "string") {
    return sendPushNotification({ token: recipients, ...notification });
  }
  if (recipients.topic) {
    return sendToTopic(recipients.topic, notification);
  }
  if (Array.isArray(recipients.tokens)) {
    return sendMulticast({ tokens: recipients.tokens, ...notification });
  }
  if (Array.isArray(recipients.users)) {
    const tokens = recipients.users.filter((u) => u.fcmToken).map((u) => u.fcmToken);
    if (tokens.length === 0) return { success: false, error: "No valid FCM tokens" };
    return sendMulticast({ tokens, ...notification });
  }
  throw new Error("Invalid recipients configuration");
}

// ============================================================================
// BATCH NOTIFICATIONS (with rate limiting)
// ============================================================================

export async function sendBatchNotifications(notifications, batchSize = 100, delayMs = 1000) {
  const results = [];
  for (let i = 0; i < notifications.length; i += batchSize) {
    const batch = notifications.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(async (n) => {
        try {
          return await sendSmartNotification(n.recipients, n);
        } catch (err) {
          return { success: false, error: err.message };
        }
      })
    );
    results.push(...batchResults);
    if (i + batchSize < notifications.length) {
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  return {
    totalSent: notifications.length,
    successCount: results.filter((r) => r?.success).length,
    failureCount: results.filter((r) => !r?.success).length,
  };
}

export default {
  NOTIFICATION_TYPES,
  notifyTaskAssigned,
  notifyTaskCompleted,
  notifyTaskOverdue,
  notifyDeadlineApproaching,
  sendMeetingReminder,
  notifyTeamMention,
  notifyNewMessage,
  sendProjectInvite,
  broadcastWorkspaceUpdate,
  sendSmartNotification,
  sendBatchNotifications,
  getWorkspaceTopic,
  getProjectTopic,
  getTeamTopic,
  getUserTopic,
};
