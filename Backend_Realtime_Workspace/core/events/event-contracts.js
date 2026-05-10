// ============================================================================
// TeamSpot — Domain Event Contracts
// Typed event name constants for all bounded contexts
// ============================================================================

export const DomainEvents = {
  // ── Auth ──
  USER_REGISTERED: "user.registered",
  USER_LOGGED_IN: "user.logged_in",
  USER_LOGGED_OUT: "user.logged_out",
  USER_2FA_ENABLED: "user.2fa_enabled",
  USER_2FA_VERIFIED: "user.2fa_verified",

  // ── Users ──
  USER_PROFILE_UPDATED: "user.profile_updated",
  USER_AVATAR_CHANGED: "user.avatar_changed",
  USER_DEACTIVATED: "user.deactivated",
  USER_INVITED: "user.invited",

  // ── Organizations ──
  ORG_CREATED: "org.created",
  ORG_UPDATED: "org.updated",
  ORG_MEMBER_ADDED: "org.member_added",
  ORG_MEMBER_REMOVED: "org.member_removed",
  ORG_SUSPENDED: "org.suspended",

  // ── Workspaces ──
  WORKSPACE_CREATED: "workspace.created",
  WORKSPACE_UPDATED: "workspace.updated",
  WORKSPACE_ARCHIVED: "workspace.archived",

  // ── Teams ──
  TEAM_CREATED: "team.created",
  TEAM_UPDATED: "team.updated",
  TEAM_MEMBER_ADDED: "team.member_added",
  TEAM_MEMBER_REMOVED: "team.member_removed",
  TEAM_DELETED: "team.deleted",

  // ── Projects ──
  PROJECT_CREATED: "project.created",
  PROJECT_UPDATED: "project.updated",
  PROJECT_ARCHIVED: "project.archived",
  PROJECT_DELETED: "project.deleted",
  PROJECT_COLLABORATOR_ADDED: "project.collaborator_added",

  // ── Tasks ──
  TASK_CREATED: "task.created",
  TASK_UPDATED: "task.updated",
  TASK_ASSIGNED: "task.assigned",
  TASK_STATUS_CHANGED: "task.status_changed",
  TASK_COMPLETED: "task.completed",
  TASK_DELETED: "task.deleted",
  TASK_COMMENT_ADDED: "task.comment_added",

  // ── Issues ──
  ISSUE_CREATED: "issue.created",
  ISSUE_UPDATED: "issue.updated",
  ISSUE_ASSIGNED: "issue.assigned",
  ISSUE_RESOLVED: "issue.resolved",
  ISSUE_CLOSED: "issue.closed",

  // ── Tickets ──
  TICKET_CREATED: "ticket.created",
  TICKET_UPDATED: "ticket.updated",
  TICKET_ASSIGNED: "ticket.assigned",
  TICKET_RESOLVED: "ticket.resolved",
  TICKET_ESCALATED: "ticket.escalated",

  // ── Channels & Chat ──
  CHANNEL_CREATED: "channel.created",
  CHANNEL_UPDATED: "channel.updated",
  CHANNEL_DELETED: "channel.deleted",
  MESSAGE_SENT: "message.sent",
  MESSAGE_EDITED: "message.edited",
  MESSAGE_DELETED: "message.deleted",
  THREAD_CREATED: "thread.created",

  // ── Meetings ──
  MEETING_SCHEDULED: "meeting.scheduled",
  MEETING_UPDATED: "meeting.updated",
  MEETING_STARTED: "meeting.started",
  MEETING_ENDED: "meeting.ended",
  MEETING_CANCELLED: "meeting.cancelled",
  MEETING_PARTICIPANT_JOINED: "meeting.participant_joined",
  MEETING_PARTICIPANT_LEFT: "meeting.participant_left",
  MEETING_RECORDING_STARTED: "meeting.recording_started",
  MEETING_RECORDING_STOPPED: "meeting.recording_stopped",

  // ── Documents ──
  DOCUMENT_UPLOADED: "document.uploaded",
  DOCUMENT_PARSED: "document.parsed",
  DOCUMENT_UPDATED: "document.updated",
  DOCUMENT_DELETED: "document.deleted",
  DOCUMENT_SHARED: "document.shared",
  DOCUMENT_INDEXED: "document.indexed",

  // ── Notifications ──
  NOTIFICATION_CREATED: "notification.created",
  NOTIFICATION_SENT: "notification.sent",
  NOTIFICATION_READ: "notification.read",
  NOTIFICATION_FAILED: "notification.failed",

  // ── Billing ──
  SUBSCRIPTION_CREATED: "billing.subscription_created",
  SUBSCRIPTION_UPDATED: "billing.subscription_updated",
  SUBSCRIPTION_CANCELLED: "billing.subscription_cancelled",
  PAYMENT_RECEIVED: "billing.payment_received",
  PAYMENT_FAILED: "billing.payment_failed",

  // ── Workflows ──
  WORKFLOW_TRIGGERED: "workflow.triggered",
  WORKFLOW_COMPLETED: "workflow.completed",
  WORKFLOW_FAILED: "workflow.failed",

  // ── AI ──
  AI_QUERY_STARTED: "ai.query_started",
  AI_QUERY_COMPLETED: "ai.query_completed",
  AI_EMBEDDING_CREATED: "ai.embedding_created",
  AI_RAG_INDEXED: "ai.rag_indexed",
  AI_AGENT_ACTION: "ai.agent_action",

  // ── Audit ──
  AUDIT_LOG_CREATED: "audit.log_created",

  // ── Integrations ──
  WEBHOOK_RECEIVED: "integration.webhook_received",
  WEBHOOK_SENT: "integration.webhook_sent",
  INTEGRATION_CONNECTED: "integration.connected",
  INTEGRATION_DISCONNECTED: "integration.disconnected",
};

export default DomainEvents;
