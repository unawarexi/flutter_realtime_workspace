/// Centralized API endpoint paths matching backend routes.
/// All paths are relative — base URL is set on the Dio client.
class ApiEndpoints {
  ApiEndpoints._();

  // ──────────── Auth ────────────
  static const signIn = '/auth/social';
  static const signOut = '/auth/logout';
  static const authRegister = '/auth/register';
  static const authVerifyEmail = '/auth/verify-email';
  static const authResendVerification = '/auth/resend-verification';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';
  static const authLogoutAll = '/auth/logout-all';
  static const authSessions = '/auth/sessions';
  static String authSession(String sessionId) => '/auth/sessions/$sessionId';
  static const authChangePassword = '/auth/change-password';
  static const auth2faStatus = '/auth/2fa/status';
  static const auth2faTotpSetup = '/auth/2fa/totp/setup';
  static const auth2faTotpConfirm = '/auth/2fa/totp/confirm';
  static const auth2faTotpVerify = '/auth/2fa/totp/verify';
  static const auth2faTotpDisable = '/auth/2fa/totp/disable';
  static const auth2faEmailSend = '/auth/2fa/email/send';
  static const auth2faEmailVerify = '/auth/2fa/email/verify';
  static const auth2faSmsSend = '/auth/2fa/sms/send';
  static const auth2faSmsVerify = '/auth/2fa/sms/verify';

  // ──────────── Users ────────────
  static const me = '/users/me';
  static const deleteAccount = '/users/me';
  static const userProfile = '/users/me';
  static const userUploadPicture = '/users/me/upload-picture';
  static const users = '/users';
  static String userById(String id) => '/users/$id';

  // ──────────── Meetings ────────────
  static const meetings = '/meetings';
  static String meeting(String id) => '/meetings/$id';
  static String meetingRsvp(String id) => '/meetings/$id/rsvp';
  static String joinMeeting(String id) => '/meetings/$id/join';

  // ──────────── Schedules ────────────
  static const schedules = '/schedules';
  static const scheduleCalendar = '/schedules/calendar';
  static const scheduleAvailability = '/schedules/availability';
  static String schedule(String id) => '/schedules/$id';
  static String scheduleCancel(String id) => '/schedules/$id/cancel';
  static String scheduleAttendees(String id) => '/schedules/$id/attendees';
  static String scheduleRsvp(String id) => '/schedules/$id/rsvp';

  // ──────────── Notifications (FCM Push) ────────────
  static const notificationSend = '/notifications/send';
  static const notificationSendMultiple = '/notifications/send-multiple';
  static const notificationSendTopic = '/notifications/send-to-topic';
  static const notificationSubscribe = '/notifications/subscribe';
  static const notificationUnsubscribe = '/notifications/unsubscribe';
  static const notificationValidateToken = '/notifications/validate-token';
  static const notificationTypes = '/notifications/types';

  // ──────────── Notifications (In-App) ────────────
  static const notifications = '/notifications/in-app';
  static const notificationUnreadCount = '/notifications/in-app/unread-count';
  static const notificationReadAll = '/notifications/in-app/read-all';
  static String notificationRead(String id) => '/notifications/in-app/$id/read';
  static String notificationDelete(String id) => '/notifications/in-app/$id';

  // ──────────── Analytics ────────────
  static const analyticsDashboard = '/analytics/dashboard';
  static const analyticsReportsGenerate = '/analytics/reports/generate';

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
  static String workspaceInvite(String id) => '/workspaces/$id/invite';

  // ──────────── Projects ────────────
  static const projects = '/projects';
  static String project(String id) => '/projects/$id';
  static String projectStar(String id) => '/projects/$id/star';
  static String projectArchive(String id) => '/projects/$id/archive';
  static String projectCollaborators(String id) => '/projects/$id/collaborators';
  static String projectTimeline(String id) => '/projects/$id/timeline';
  static String projectMembers(String id) => '/projects/$id/members';
  static String projectMember(String id, String userId) =>
      '/projects/$id/members/$userId';
  static String projectAttachments(String id) => '/projects/$id/attachments';
  static String projectAttachment(String id, String attachmentId) =>
      '/projects/$id/attachments/$attachmentId';

  // ──────────── Tasks ────────────
  static const tasks = '/tasks';
  static String task(String id) => '/tasks/$id';
  static String taskComments(String id) => '/tasks/$id/comments';
  static String taskChecklist(String id) => '/tasks/$id/checklist';
  static String taskAttachments(String id) => '/tasks/$id/attachments';

  // ──────────── Issues ────────────
  static const issues = '/issues';
  static String issue(String id) => '/issues/$id';
  static String issueComments(String issueId) => '/issues/$issueId/comments';
  static String issueLink(String issueId) => '/issues/$issueId/link';
  static String issueAttachments(String issueId) => '/issues/$issueId/attachments';

  // ──────────── Tickets ────────────
  static const tickets = '/tickets';
  static String ticket(String id) => '/tickets/$id';
  static String ticketComments(String id) => '/tickets/$id/comments';
  static String ticketAttachments(String id) => '/tickets/$id/attachments';

  // ──────────── Channels ────────────
  static const channels = '/channels';
  static String channel(String id) => '/channels/$id';
  static String channelMembers(String id) => '/channels/$id/members';
  static String channelMember(String channelId, String memberId) =>
      '/channels/$channelId/members/$memberId';
  static String channelMessages(String id) => '/channels/$id/messages';

  // ──────────── Communication (LiveKit video + VoIP + DMs) ────────────
  static const communicationRoomToken = '/communication/rooms/token';
  static const communicationRooms = '/communication/rooms';
  static String communicationRoom(String name) => '/communication/rooms/$name';
  static String communicationRoomParticipants(String name) =>
      '/communication/rooms/$name/participants';
  static String communicationRoomRemoveParticipant(String name) =>
      '/communication/rooms/$name/remove-participant';
  static const communicationCallInitiate = '/communication/calls/initiate';
  static String communicationCallAccept(String id) => '/communication/calls/$id/accept';
  static String communicationCallEnd(String id) => '/communication/calls/$id/end';
  static String communicationCallReject(String id) => '/communication/calls/$id/reject';
  static const communicationCallHistory = '/communication/calls/history';
  static const communicationMessages = '/communication/messages';
  static const communicationMessagesSearch = '/communication/messages/search';
  static String communicationMessage(String id) => '/communication/messages/$id';

  // ──────────── Teams ────────────
  static const teams = '/teams';
  static String team(String id) => '/teams/$id';
  static String teamMembers(String teamId) => '/teams/$teamId/members';
  static String teamInvite(String teamId) => '/teams/$teamId/invite';

  // ──────────── Documents ────────────
  static const documents = '/documents';
  static String document(String id) => '/documents/$id';
  static String documentShare(String id) => '/documents/$id/share';

  // ──────────── Workflows ────────────
  static const workflows = '/workflows';
  static String workflow(String id) => '/workflows/$id';
  static String workflowToggle(String id) => '/workflows/$id/toggle';
  static String workflowTest(String id) => '/workflows/$id/test';

  // ──────────── Storage ────────────
  static const storageUpload = '/storage/upload';
  static const storageUploadMultiple = '/storage/upload/multiple';
  static const storageAssets = '/storage';
  static String storageAsset(String id) => '/storage/$id';
  static String storageAssetAttach(String id) => '/storage/$id/attach';

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
  static String integrationWebhook(String id) => '/integrations/webhooks/$id';

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

  // ──────────── Whiteboards ────────────
  static const whiteboards = '/whiteboards';
  static String whiteboard(String id) => '/whiteboards/$id';
  static String whiteboardState(String id) => '/whiteboards/$id/state';
  static String whiteboardCursor(String id) => '/whiteboards/$id/cursor';
  static String whiteboardCollaborator(String id, String userId) =>
      '/whiteboards/$id/collaborators/$userId';
  static String whiteboardThumbnail(String id) => '/whiteboards/$id/thumbnail';

  // ──────────── Admin ────────────
  static const adminTenants = '/admin/tenants';
  static String adminTenantStatus(String id) => '/admin/tenants/$id/status';
  static const adminStats = '/admin/stats';
  static const adminImpersonate = '/admin/impersonate';
}
