/// Centralized API endpoint paths matching backend routes.
/// All paths are relative — base URL is set on the Dio client.
class ApiEndpoints {
  ApiEndpoints._();

  // ──────────── Auth (2FA) ────────────
  // Sign-in / sign-out handled by Firebase SDK directly.
  static const auth2faEmailGenerate = '/auth/2fa/email/generate';
  static const auth2faEmailVerify = '/auth/2fa/email/verify';
  static const auth2faSmsGenerate = '/auth/2fa/sms/generate';
  static const auth2faSmsVerify = '/auth/2fa/sms/verify';
  static const auth2faTotpGenerate = '/auth/2fa/totp/generate';
  static const auth2faTotpConfirm = '/auth/2fa/totp/confirm';
  static const auth2faTotpVerify = '/auth/2fa/totp/verify';
  static const auth2faTotpDisable = '/auth/2fa/totp/disable';
  static const auth2faStatus = '/auth/2fa/status';

  // ──────────── Users ────────────
  static const me = '/users/me';
  static const userUploadPicture = '/users/me/upload-picture';
  static const userRegenerateInvite = '/users/me/regenerate-invite';
  static const userReferralStats = '/users/me/my-referral-stats';
  static const userReferralChain = '/users/me/referral-chain';
  static const userFind = '/users/find';
  static const users = '/users';
  static String userById(String id) => '/users/$id';
  static String userRevokeReferral(String id) => '/users/$id/revoke-referral';
  static String userInvitePermissions(String id) => '/users/$id/invite-permissions';

  // ──────────── Meetings ────────────
  // /meetings handles live-meeting CRUD; /schedules handles scheduling.
  static const meetings = '/meetings';
  static String meeting(String id) => '/meetings/$id';
  static String joinMeeting(String id) => '/meetings/$id/join';
  static String leaveMeeting(String id) => '/meetings/$id/leave';

  // ──────────── Schedules (Meeting Scheduling) ────────────
  static const schedules = '/schedules';
  static String schedule(String id) => '/schedules/$id';
  static const scheduleTemplate = '/schedules/template';
  static String scheduleFromTemplate(String templateId) =>
      '/schedules/from-template/$templateId';
  static String userSchedules(String userId) => '/schedules/user/$userId';
  static String userTodaySchedules(String userId) =>
      '/schedules/user/$userId/today';
  static String userUpcomingSchedules(String userId) =>
      '/schedules/user/$userId/upcoming';
  static String userScheduleInvitations(String userId) =>
      '/schedules/user/$userId/invitations';
  static String userScheduleConflicts(String userId) =>
      '/schedules/user/$userId/conflicts';
  static String userCalendar(String userId) =>
      '/schedules/user/$userId/calendar';
  static String userMeetingStats(String userId) =>
      '/schedules/user/$userId/stats';
  static const scheduleSearch = '/schedules/search';
  static const scheduleExport = '/schedules/export';
  static const scheduleTemplates = '/schedules/templates';
  static String scheduleStatus(String id) => '/schedules/$id/status';
  static String schedulePostpone(String id) => '/schedules/$id/postpone';
  static String scheduleParticipants(String id) =>
      '/schedules/$id/participants';
  static String scheduleParticipant(String id, String userId) =>
      '/schedules/$id/participants/$userId';
  static String scheduleAttachments(String id) => '/schedules/$id/attachments';
  static String scheduleRecordings(String id) => '/schedules/$id/recordings';
  static String scheduleInvitations(String id) => '/schedules/$id/invitations';

  // ──────────── Notifications (FCM) ────────────
  static const notificationSend = '/notifications/send';
  static const notificationSendMultiple = '/notifications/send-multiple';
  static const notificationSendTopic = '/notifications/send-to-topic';
  static const notificationSubscribe = '/notifications/subscribe';
  static const notificationUnsubscribe = '/notifications/unsubscribe';
  static const notificationValidateToken = '/notifications/validate-token';
  static const notificationTypes = '/notifications/types';

  // ──────────── Analytics ────────────
  static const analyticsDashboard = '/analytics/dashboard';
  static const analyticsUsage = '/analytics/usage';

  // ──────────── Billing ────────────
  static const subscription = '/billing/subscription';
  static const billingInvoices = '/billing/invoices';
  static String billingInvoice(String id) => '/billing/invoices/$id';
  static const billingUsage = '/billing/usage';

  // ──────────── Search ────────────
  static const search = '/search';
  static String searchResource(String resource) => '/search/$resource';

  // ──────────── Legal ────────────
  static const legalTerms = '/legal/terms';
  static const legalPrivacy = '/legal/privacy';
  static const legalAll = '/legal/all';

  // ──────────── AI ────────────
  static const aiChat = '/ai/chat';
  static const aiConversations = '/ai/conversations';
  static String aiConversation(String id) => '/ai/conversations/$id';
  static const aiRagQuery = '/ai/rag/query';
  static const aiRagIngest = '/ai/rag/ingest';
  static const aiRagStatus = '/ai/rag/status';
  static const aiTools = '/ai/tools';
  static String aiToolExecute(String name) => '/ai/tools/$name/execute';
  static const aiSummarize = '/ai/summarize';

  // ──────────── Organizations ────────────
  static const organizations = '/organizations';
  static String organization(String id) => '/organizations/$id';
  static String orgInvite(String id) => '/organizations/$id/invite';
  static String orgMembers(String id) => '/organizations/$id/members';
  static String orgMember(String orgId, String userId) =>
      '/organizations/$orgId/members/$userId';
  static String orgSettings(String id) => '/organizations/$id/settings';

  // ──────────── Workspaces ────────────
  static const workspaces = '/workspaces';
  static String workspace(String id) => '/workspaces/$id';
  static String workspaceMembers(String id) => '/workspaces/$id/members';
  static String workspaceMember(String workspaceId, String userId) =>
      '/workspaces/$workspaceId/members/$userId';

  // ──────────── Projects ────────────
  static const projects = '/projects';
  static const projectStats = '/projects/stats';
  static const projectKeyGenerate = '/projects/generate/project-key';
  static const projectTeamIdGenerate = '/projects/generate/team-id';
  static String project(String id) => '/projects/$id';
  static String projectStar(String id) => '/projects/$id/star';
  static String projectArchive(String id) => '/projects/$id/archive';
  static String projectProgress(String id) => '/projects/$id/progress';
  static String projectDuplicate(String id) => '/projects/$id/duplicate';
  static String projectCollaborators(String id) =>
      '/projects/$id/collaborators';
  static String projectAttachments(String id) => '/projects/$id/attachments';
  static String projectAttachment(String id, String attachmentId) =>
      '/projects/$id/attachments/$attachmentId';
  static String projectTimeline(String id) => '/projects/$id/timeline';

  // ──────────── Tasks ────────────
  static const tasks = '/tasks';
  static String task(String id) => '/tasks/$id';

  // ──────────── Issues ────────────
  static const issues = '/issues';
  static String issue(String id) => '/issues/$id';
  static String issueComments(String issueId) => '/issues/$issueId/comments';

  // ──────────── Tickets ────────────
  static const tickets = '/tickets';
  static String ticket(String id) => '/tickets/$id';
  static String ticketAssign(String id) => '/tickets/$id/assign';
  static String ticketStatus(String id) => '/tickets/$id/status';
  static String ticketComments(String id) => '/tickets/$id/comments';

  // ──────────── Channels ────────────
  static const channels = '/channels';
  static String channel(String id) => '/channels/$id';
  static String channelMembers(String id) => '/channels/$id/members';
  static String channelMember(String channelId, String memberId) =>
      '/channels/$channelId/members/$memberId';
  static String channelMessages(String id) => '/channels/$id/messages';
  static String messageThreads(String channelId, String messageId) =>
      '/channels/$channelId/messages/$messageId/threads';
  static String channelPin(String channelId, String messageId) =>
      '/channels/$channelId/pins/$messageId';

  // ──────────── Teams ────────────
  static const teams = '/teams';
  static const teamsSearch = '/teams/search';
  static String team(String identifier) => '/teams/$identifier';
  static String teamInvite(String teamId) => '/teams/$teamId/invite';
  static String teamInvitationAccept(String token) =>
      '/teams/invitations/$token/accept';
  static String teamMemberRole(String teamId, String memberId) =>
      '/teams/$teamId/members/$memberId/role';
  static String teamMember(String teamId, String memberId) =>
      '/teams/$teamId/members/$memberId';
  static String teamLeave(String teamId) => '/teams/$teamId/leave';
  static String teamTransferOwnership(String teamId) =>
      '/teams/$teamId/transfer-ownership';
  static String teamBulkPermissions(String teamId) =>
      '/teams/$teamId/members/bulk-permissions';
  static String teamProjects(String teamId) => '/teams/$teamId/projects';
  static String teamProjectAssign(String teamId, String projectId) =>
      '/teams/$teamId/projects/$projectId/assign';
  static String teamAnalytics(String teamId) => '/teams/$teamId/analytics';
  static String teamActivity(String teamId) => '/teams/$teamId/activity';
  static String teamIntegrations(String teamId) =>
      '/teams/$teamId/integrations';
  static String teamPermissions(String teamId) => '/teams/$teamId/permissions';

  // ──────────── Documents ────────────
  static const documentUpload = '/documents/upload';
  static const documents = '/documents';
  static String document(String id) => '/documents/$id';
  static String documentShare(String id) => '/documents/$id/share';
  static String documentReindex(String id) => '/documents/$id/reindex';

  // ──────────── Workflows ────────────
  static const workflows = '/workflows';
  static String workflow(String id) => '/workflows/$id';
  static String workflowToggle(String id) => '/workflows/$id/toggle';
  static String workflowExecute(String id) => '/workflows/$id/execute';

  // ──────────── Storage / Assets ────────────
  static const storageUpload = '/storage/upload';
  static const storageUploadMultiple = '/storage/upload/multiple';
  static const storageAssets = '/storage';
  static String storageAsset(String id) => '/storage/$id';

  // ──────────── Audit ────────────
  static const auditLogs = '/audit';
  static String auditLog(String id) => '/audit/$id';
  static const auditExport = '/audit/export';

  // ──────────── Feedback ────────────
  static const feedbacks = '/feedback';
  static String feedback(String id) => '/feedback/$id';
  static String feedbackRespond(String id) => '/feedback/$id/respond';

  // ──────────── Integrations ────────────
  static const integrations = '/integrations';
  static String integration(String id) => '/integrations/$id';
  static String integrationTest(String id) => '/integrations/$id/test';
  static String integrationWebhook(String id) =>
      '/integrations/webhooks/$id';

  // ──────────── Identity (Roles, Policies & Permissions) ────────────
  static const identityRoles = '/identity/roles';
  static String identityRole(String id) => '/identity/roles/$id';
  static const identityPolicies = '/identity/policies';
  static String identityPolicy(String id) => '/identity/policies/$id';
  static String userPermissions(String userId) =>
      '/identity/users/$userId/permissions';
  static String userRole(String userId) => '/identity/users/$userId/role';

  // ──────────── Templates ────────────
  static const templates = '/templates';
  static String template(String id) => '/templates/$id';
  static String templatePreview(String id) => '/templates/$id/preview';

  // ──────────── Admin ────────────
  // Admin routes are defined but backend file is currently empty (placeholder).
  static const adminUsers = '/admin/users';
  static String adminUser(String userId) => '/admin/users/$userId';
  static String adminSuspendUser(String userId) =>
      '/admin/users/$userId/suspend';
  static String adminUnsuspendUser(String userId) =>
      '/admin/users/$userId/unsuspend';
  static String adminImpersonate(String userId) =>
      '/admin/users/$userId/impersonate';
}
