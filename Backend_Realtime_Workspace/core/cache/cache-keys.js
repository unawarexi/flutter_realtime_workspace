// ============================================================================
// TeamSpot — Cache Key Patterns
// Centralized cache key generation for consistent key naming
// ============================================================================

export const CacheKeys = {
  // User
  userProfile: (userId) => `user:profile:${userId}`,
  userPermissions: (userId) => `user:permissions:${userId}`,
  userSession: (userId, deviceId) => `user:session:${userId}:${deviceId}`,

  // Organization
  org: (orgId) => `org:${orgId}`,
  orgMembers: (orgId) => `org:members:${orgId}`,
  orgSettings: (orgId) => `org:settings:${orgId}`,

  // Workspace
  workspace: (wsId) => `workspace:${wsId}`,
  workspaceMembers: (wsId) => `workspace:members:${wsId}`,

  // Team
  team: (teamId) => `team:${teamId}`,
  teamMembers: (teamId) => `team:members:${teamId}`,

  // Project
  project: (projectId) => `project:${projectId}`,
  projectList: (userId, page) => `projects:list:${userId}:p${page}`,
  projectStats: (projectId) => `project:stats:${projectId}`,

  // Task
  task: (taskId) => `task:${taskId}`,
  taskList: (projectId, page) => `tasks:list:${projectId}:p${page}`,

  // Channel
  channel: (channelId) => `channel:${channelId}`,
  channelList: (workspaceId) => `channels:list:${workspaceId}`,
  channelMembers: (channelId) => `channel:members:${channelId}`,

  // Meeting
  meeting: (meetingId) => `meeting:${meetingId}`,
  meetingParticipants: (meetingId) => `meeting:participants:${meetingId}`,

  // Presence
  presence: (userId) => `presence:${userId}`,
  presenceRoom: (roomId) => `presence:room:${roomId}`,
  typing: (channelId) => `typing:${channelId}`,

  // Rate limiting
  rateLimit: (identifier) => `ratelimit:${identifier}`,

  // Search
  searchResults: (query, page) => `search:${query}:p${page}`,

  // AI
  aiConversation: (conversationId) => `ai:conversation:${conversationId}`,
  aiEmbedding: (docId) => `ai:embedding:${docId}`,
};

export default CacheKeys;
