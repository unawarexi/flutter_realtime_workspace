// ============================================================================
// TeamSpot — Application Constants
// ============================================================================

// ============================================================================
// HTTP STATUS CODES
// ============================================================================

export const HttpStatus = {
  OK: 200,
  CREATED: 201,
  ACCEPTED: 202,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  PAYMENT_REQUIRED: 402,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
};

// ============================================================================
// ERROR CODES
// ============================================================================

export const ErrorCodes = {
  // Auth & Identity (E1xxx)
  UNAUTHORIZED: "E1001",
  TOKEN_INVALID: "E1002",
  FORBIDDEN: "E1003",
  TOKEN_EXPIRED: "E1004",
  ACCOUNT_SUSPENDED: "E1005",
  ACCOUNT_DEACTIVATED: "E1006",
  FIREBASE_AUTH_FAILED: "E1007",
  TENANT_NOT_FOUND: "E1008",
  WORKSPACE_ACCESS_DENIED: "E1009",
  SESSION_EXPIRED: "E1010",

  // Validation (E2xxx)
  VALIDATION_ERROR: "E2001",
  INVALID_INPUT: "E2002",
  MISSING_FIELD: "E2003",
  FILE_TOO_LARGE: "E2004",
  UNSUPPORTED_FILE_TYPE: "E2005",
  INVALID_DATE_RANGE: "E2006",

  // Resource Not Found (E3xxx)
  USER_NOT_FOUND: "E3001",
  USER_ALREADY_EXISTS: "E3002",
  WORKSPACE_NOT_FOUND: "E3003",
  PROJECT_NOT_FOUND: "E3004",
  TASK_NOT_FOUND: "E3005",
  CHANNEL_NOT_FOUND: "E3006",
  MEETING_NOT_FOUND: "E3007",
  NOTIFICATION_NOT_FOUND: "E3008",
  DOCUMENT_NOT_FOUND: "E3009",
  TEMPLATE_NOT_FOUND: "E3010",
  ORGANIZATION_NOT_FOUND: "E3011",
  TEAM_NOT_FOUND: "E3012",
  ISSUE_NOT_FOUND: "E3013",
  TICKET_NOT_FOUND: "E3014",
  SCHEDULE_NOT_FOUND: "E3015",

  // Business Logic (E4xxx)
  WORKSPACE_LIMIT_REACHED: "E4001",
  MEMBER_LIMIT_REACHED: "E4002",
  STORAGE_QUOTA_EXCEEDED: "E4003",
  PLAN_FEATURE_UNAVAILABLE: "E4004",
  DUPLICATE_ENTRY: "E4005",
  MEETING_CAPACITY_EXCEEDED: "E4006",
  CHANNEL_ARCHIVED: "E4007",
  TASK_IMMUTABLE: "E4008",
  WORKFLOW_INVALID_TRANSITION: "E4009",
  INTEGRATION_AUTH_FAILED: "E4010",
  INVITE_EXPIRED: "E4011",
  INVITE_ALREADY_USED: "E4012",
  ROLE_NOT_ASSIGNABLE: "E4013",

  // Billing (E6xxx)
  PAYMENT_FAILED: "E6001",
  SUBSCRIPTION_EXPIRED: "E6002",
  INVOICE_NOT_FOUND: "E6003",
  REFUND_FAILED: "E6004",
  PLAN_CHANGE_INVALID: "E6005",

  // AI (E7xxx)
  AI_SERVICE_UNAVAILABLE: "E7001",
  AI_CONTEXT_TOO_LONG: "E7002",
  AI_QUOTA_EXCEEDED: "E7003",
  RAG_INGEST_FAILED: "E7004",
  AI_TOOL_EXECUTION_FAILED: "E7005",

  // Rate Limiting (E8xxx)
  RATE_LIMIT_EXCEEDED: "E8001",

  // Server (E9xxx)
  INTERNAL_ERROR: "E9001",
  SERVICE_UNAVAILABLE: "E9002",
  AI_SERVICE_DOWN: "E9003",
  EXTERNAL_SERVICE_DOWN: "E9004",
};

// ============================================================================
// WORKSPACE CONFIGURATION
// ============================================================================

export const WorkspaceConfig = {
  MAX_MEMBERS: 1000,
  MAX_CHANNELS: 500,
  MAX_PROJECTS: 200,
  MAX_DESCRIPTION_LENGTH: 5000,
  DEFAULT_PLAN: "free",
  INVITE_EXPIRY_DAYS: 7,
};

// ============================================================================
// MEETING CONFIGURATION
// ============================================================================

export const MeetingConfig = {
  MAX_PARTICIPANTS: 250,
  MAX_DURATION_HOURS: 8,
  RECORDING_RETENTION_DAYS: 90,
  DEFAULT_JOIN_BEFORE_HOST_MINUTES: 5,
  LOBBY_WAIT_TIMEOUT_MS: 300000, // 5 minutes
};

// ============================================================================
// STORAGE CONFIGURATION
// ============================================================================

export const StorageConfig = {
  MAX_FILE_SIZE_MB: 100,
  MAX_UPLOAD_SIZE_MB: 50,
  ALLOWED_MIME_TYPES: [
    "image/jpeg", "image/png", "image/gif", "image/webp",
    "video/mp4", "video/webm",
    "audio/mpeg", "audio/wav", "audio/webm",
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "text/plain", "text/markdown", "text/csv",
    "application/zip",
  ],
  RETENTION_DAYS: { free: 30, pro: 365, enterprise: -1 },
};

// ============================================================================
// RATE LIMITING
// ============================================================================

export const RateLimits = {
  API:           { windowMs: 15 * 60 * 1000, max: 300 },
  AUTH:          { windowMs: 15 * 60 * 1000, max: 20 },
  AI_CHAT:       { windowMs: 60 * 1000, max: 30 },
  UPLOAD:        { windowMs: 60 * 1000, max: 20 },
  MESSAGE:       { windowMs: 60 * 1000, max: 120 },
  NOTIFICATION:  { windowMs: 60 * 1000, max: 60 },
  MEETING:       { windowMs: 60 * 1000, max: 10 },
  SEARCH:        { windowMs: 60 * 1000, max: 60 },
  STORAGE:       { windowMs: 60 * 1000, max: 20 },
};

// ============================================================================
// CACHE TTL (in seconds)
// ============================================================================

export const CacheTTL = {
  USER_PROFILE:     300,  // 5 min
  WORKSPACE:        120,  // 2 min
  PROJECT:           60,  // 1 min
  TASK_LIST:         30,  // 30 sec
  CHANNEL_LIST:      60,  // 1 min
  MEETING_LIST:      60,  // 1 min
  TEAM_MEMBERS:     300,  // 5 min
  ORGANIZATION:     600,  // 10 min
  NOTIFICATIONS:     30,  // 30 sec
  SEARCH_RESULTS:    60,  // 1 min
  BILLING:          300,  // 5 min
  AI_RESPONSE:        0,  // never cache
  TEMPLATES:        600,  // 10 min
};

// ============================================================================
// SOCKET / REAL-TIME EVENTS
// ============================================================================

export const SocketEvents = {
  // Connection lifecycle
  CONNECTION: "connection",
  DISCONNECT: "disconnect",
  ERROR: "error",

  // Workspace
  WORKSPACE_UPDATED: "workspace:updated",
  MEMBER_JOINED: "workspace:member_joined",
  MEMBER_LEFT: "workspace:member_left",
  MEMBER_ROLE_CHANGED: "workspace:member_role_changed",

  // Projects
  PROJECT_CREATED: "project:created",
  PROJECT_UPDATED: "project:updated",
  PROJECT_DELETED: "project:deleted",

  // Tasks
  TASK_CREATED: "task:created",
  TASK_UPDATED: "task:updated",
  TASK_ASSIGNED: "task:assigned",
  TASK_COMPLETED: "task:completed",
  TASK_COMMENT: "task:comment",

  // Issues & Tickets
  ISSUE_CREATED: "issue:created",
  ISSUE_UPDATED: "issue:updated",
  TICKET_CREATED: "ticket:created",
  TICKET_UPDATED: "ticket:updated",

  // Channels & Messaging
  CHANNEL_MESSAGE: "channel:message",
  CHANNEL_TYPING: "channel:typing",
  CHANNEL_READ: "channel:read",
  DIRECT_MESSAGE: "dm:message",
  DM_TYPING: "dm:typing",
  DM_READ: "dm:read",

  // Meetings & Calls
  MEETING_STARTED: "meeting:started",
  MEETING_ENDED: "meeting:ended",
  MEETING_PARTICIPANT_JOINED: "meeting:participant_joined",
  MEETING_PARTICIPANT_LEFT: "meeting:participant_left",
  MEETING_RECORDING_STARTED: "meeting:recording_started",
  MEETING_RECORDING_STOPPED: "meeting:recording_stopped",
  CALL_INCOMING: "call:incoming",
  CALL_ACCEPTED: "call:accepted",
  CALL_REJECTED: "call:rejected",
  CALL_ENDED: "call:ended",

  // Notifications
  NOTIFICATION: "notification:received",
  NOTIFICATION_READ: "notification:read",

  // User Presence
  USER_ONLINE: "user:online",
  USER_OFFLINE: "user:offline",
  USER_STATUS_CHANGED: "user:status_changed",

  // AI Agent
  AI_TYPING: "ai:typing",
  AI_TOOL_EXECUTE: "ai:tool_execute",
  AI_TOOL_RESULT: "ai:tool_result",
  AI_WORKFLOW_STATUS: "ai:workflow_status",
  AI_TASK_PROGRESS: "ai:task_progress",

  // Scheduling
  SCHEDULE_REMINDER: "schedule:reminder",

  // Admin
  ADMIN_BROADCAST: "admin:broadcast",

  // WebSocket — client-to-server lifecycle events
  AUTH_REGISTER: "auth:register",
  JOIN_ROOM:     "room:join",
  LEAVE_ROOM:    "room:leave",

  // Participant media state (meetings)
  PARTICIPANT_MUTED:             "meeting:participant_muted",
  PARTICIPANT_UNMUTED:           "meeting:participant_unmuted",
  PARTICIPANT_VIDEO_ON:          "meeting:participant_video_on",
  PARTICIPANT_VIDEO_OFF:         "meeting:participant_video_off",
  PARTICIPANT_SCREEN_SHARE_ON:   "meeting:participant_screen_share_on",
  PARTICIPANT_SCREEN_SHARE_OFF:  "meeting:participant_screen_share_off",
  PARTICIPANT_HAND_RAISED:       "meeting:participant_hand_raised",
  PARTICIPANT_HAND_LOWERED:      "meeting:participant_hand_lowered",
};

// ============================================================================
// KAFKA TOPICS
// ============================================================================

export const KafkaTopics = {
  USER_EVENTS:        "teamspot.user.events",
  WORKSPACE_EVENTS:   "teamspot.workspace.events",
  PROJECT_EVENTS:     "teamspot.project.events",
  TASK_EVENTS:        "teamspot.task.events",
  CHANNEL_MESSAGES:   "teamspot.channel.messages",
  DIRECT_MESSAGES:    "teamspot.direct.messages",
  MEETING_EVENTS:     "teamspot.meeting.events",
  NOTIFICATION_EVENTS:"teamspot.notification.events",
  ANALYTICS_EVENTS:   "teamspot.analytics.events",
  BILLING_EVENTS:     "teamspot.billing.events",
  AUDIT_EVENTS:       "teamspot.audit.events",
  STORAGE_EVENTS:     "teamspot.storage.events",
  AI_TASKS:           "teamspot.ai.tasks",
  AI_RESULTS:         "teamspot.ai.results",
};

// ============================================================================
// RABBITMQ QUEUES
// ============================================================================

export const RabbitQueues = {
  EMAIL:            "teamspot.email",
  NOTIFICATION:     "teamspot.notification",
  AI_EMBEDDING:     "teamspot.ai.embedding",
  AI_RAG_INGEST:    "teamspot.ai.rag_ingest",
  AI_AGENT_TASK:    "teamspot.ai.agent_task",
  PDF_RENDER:       "teamspot.pdf.render",
  ANALYTICS:        "teamspot.analytics",
  CLEANUP:          "teamspot.cleanup",
  AUDIT:            "teamspot.audit",
};

// ============================================================================
// PAGINATION DEFAULTS
// ============================================================================

export const Pagination = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 20,
  MAX_LIMIT: 100,
};

// ============================================================================
// COMMON HEADERS
// ============================================================================

export const Headers = {
  REQUEST_ID: "x-request-id",
  USER_AGENT:  "user-agent",
  PLATFORM:    "x-platform",
  TENANT_ID:   "x-tenant-id",
  API_VERSION: "x-api-version",
};

// ============================================================================
// APP LINKS
// ============================================================================

export const AppLinks = {
  GOOGLE_PLAY: "https://play.google.com/store/apps/details?id=com.teamspot.app",
  APPLE_STORE: "https://apps.apple.com/app/teamspot/id0000000000",
  WEB_APP:     process.env.FRONTEND_URL || "https://teamspot.app",
};

export default {
  HttpStatus,
  ErrorCodes,
  WorkspaceConfig,
  MeetingConfig,
  StorageConfig,
  RateLimits,
  CacheTTL,
  SocketEvents,
  KafkaTopics,
  RabbitQueues,
  Pagination,
  Headers,
  AppLinks,
};
