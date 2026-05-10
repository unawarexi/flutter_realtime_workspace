import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'package:flutter_realtime_workspace/app/screens/splash/splash_screen.dart';
import 'package:flutter_realtime_workspace/app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_realtime_workspace/app/screens/home.dart';
import 'package:flutter_realtime_workspace/app/screens/dashboard.dart';
import 'package:flutter_realtime_workspace/app/screens/project.dart';

// Auth
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/login.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/signup_screen.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/2fa_screen.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/user_information.dart';

// Collaboration
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/chat_screen.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/calls_screen.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/meetings_screen.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/document_editor_screen.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/history_screen.dart';

// Project Management
import 'package:flutter_realtime_workspace/app/features/project_management/presentation/screens/create_project_screen.dart';
import 'package:flutter_realtime_workspace/app/features/project_management/presentation/screens/create_task_screen.dart';
import 'package:flutter_realtime_workspace/app/features/project_management/presentation/screens/project_more.dart';
import 'package:flutter_realtime_workspace/app/features/project_management/presentation/screens/project_timeline_screen.dart';

// Team Management
import 'package:flutter_realtime_workspace/app/features/team_management/presentation/all_team.dart';
import 'package:flutter_realtime_workspace/app/features/team_management/presentation/team_screen.dart';
import 'package:flutter_realtime_workspace/app/features/team_management/presentation/widgets/create_team_screen.dart';

// Account Management
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/account.dart';
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/settings.dart';
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/invite.dart';
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/feedback.dart' as acct_fb;
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/support.dart';
import 'package:flutter_realtime_workspace/app/features/account_management/presentation/whats_new.dart';

// Notifications
import 'package:flutter_realtime_workspace/app/features/notification/presentation/notification_screen.dart';

// Workspaces
import 'package:flutter_realtime_workspace/app/features/workspaces/presentation/screens/workspaces_screen.dart';
import 'package:flutter_realtime_workspace/app/features/workspaces/presentation/screens/create_workspace_screen.dart';
import 'package:flutter_realtime_workspace/app/features/workspaces/presentation/screens/workspace_detail_screen.dart';

// Organizations
import 'package:flutter_realtime_workspace/app/features/organizations/presentation/screens/organization_screen.dart';
import 'package:flutter_realtime_workspace/app/features/organizations/presentation/screens/org_members_screen.dart';
import 'package:flutter_realtime_workspace/app/features/organizations/presentation/screens/invite_screen.dart' as org_invite;

// Issues
import 'package:flutter_realtime_workspace/app/features/issues/presentation/screens/issues_screen.dart';
import 'package:flutter_realtime_workspace/app/features/issues/presentation/screens/issue_detail_screen.dart';
import 'package:flutter_realtime_workspace/app/features/issues/presentation/screens/create_issue_screen.dart';

// Tasks
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/screens/create_task_screen.dart' as ts;
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/screens/my_tasks_screen.dart';

// Tickets
import 'package:flutter_realtime_workspace/app/features/tickets/presentation/screens/tickets_screen.dart';
import 'package:flutter_realtime_workspace/app/features/tickets/presentation/screens/ticket_detail_screen.dart';
import 'package:flutter_realtime_workspace/app/features/tickets/presentation/screens/create_ticket_screen.dart';

// Search
import 'package:flutter_realtime_workspace/app/features/search/presentation/screens/search_screen.dart';

// Admin
import 'package:flutter_realtime_workspace/app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:flutter_realtime_workspace/app/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:flutter_realtime_workspace/app/features/admin/presentation/screens/admin_logs_screen.dart';
import 'package:flutter_realtime_workspace/app/features/admin/presentation/screens/admin_approvals_screen.dart';

// Workflows
import 'package:flutter_realtime_workspace/app/features/workflows/presentation/screens/workflows_screen.dart';
import 'package:flutter_realtime_workspace/app/features/workflows/presentation/screens/create_workflow_screen.dart';
import 'package:flutter_realtime_workspace/app/features/workflows/presentation/screens/workflow_detail_screen.dart';

// Schedules
import 'package:flutter_realtime_workspace/app/features/schedules/presentation/screens/schedule_screen.dart';
import 'package:flutter_realtime_workspace/app/features/schedules/presentation/screens/create_schedule_screen.dart';

// Storage
import 'package:flutter_realtime_workspace/app/features/storage/presentation/screens/storage_screen.dart';
import 'package:flutter_realtime_workspace/app/features/storage/presentation/screens/upload_screen.dart';

// Integrations
import 'package:flutter_realtime_workspace/app/features/integrations/presentation/screens/integrations_screen.dart';
import 'package:flutter_realtime_workspace/app/features/integrations/presentation/screens/integration_setup_screen.dart';

// Audit
import 'package:flutter_realtime_workspace/app/features/audit/presentation/screens/audit_log_screen.dart';

// Feedback
import 'package:flutter_realtime_workspace/app/features/feedback/presentation/screens/feedback_screen.dart' as fb;
import 'package:flutter_realtime_workspace/app/features/feedback/presentation/screens/submit_feedback_screen.dart';

// Identity
import 'package:flutter_realtime_workspace/app/features/identity/presentation/screens/roles_screen.dart';

// Legal
import 'package:flutter_realtime_workspace/app/features/legal/presentation/screens/terms_screen.dart';
import 'package:flutter_realtime_workspace/app/features/legal/presentation/screens/privacy_screen.dart';

// AI
import 'package:flutter_realtime_workspace/app/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:flutter_realtime_workspace/app/features/ai/presentation/screens/ai_insights_screen.dart';

// Analytics
import 'package:flutter_realtime_workspace/app/features/analytics/presentation/screens/analytics_screen.dart';

// Billing
import 'package:flutter_realtime_workspace/app/features/billing/presentation/screens/billing_screen.dart';
import 'package:flutter_realtime_workspace/app/features/billing/presentation/screens/subscription_screen.dart';

// Dashboard Management
import 'package:flutter_realtime_workspace/app/features/dashboard_management/default_dashboard.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard_management/starred_dashboards.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard_management/financial_overview_dashboard.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;

    final publicPaths = ['/splash', '/onboarding', '/login', '/signup', '/2fa', '/terms', '/privacy'];
    final isPublic = publicPaths.any((p) => path.startsWith(p));

    if (!isLoggedIn && !isPublic) return '/login';
    if (isLoggedIn && path == '/login') return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const TeamSpotSplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const Authentication(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUp(),
    ),
    GoRoute(
      path: '/2fa',
      builder: (context, state) => const TwoFAScreen(),
    ),
    GoRoute(
      path: '/user-info',
      builder: (context, state) => const UserInformationScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Home(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
          routes: [
            GoRoute(path: 'default', builder: (c, s) => const DefaultDashboard()),
            GoRoute(path: 'starred', builder: (c, s) => const StarredDashboard()),
            GoRoute(path: 'financial', builder: (c, s) => const FinancialOverviewDashboard()),
          ],
        ),
        GoRoute(
          path: '/workspaces',
          builder: (context, state) => const WorkspacesScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateWorkspaceScreen()),
            GoRoute(
              path: ':workspaceId',
              builder: (c, s) => WorkspaceDetailScreen(workspaceId: s.pathParameters['workspaceId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/organization',
          builder: (context, state) => const OrganizationScreen(),
          routes: [
            GoRoute(
              path: 'members',
              builder: (c, s) => OrgMembersScreen(orgId: s.uri.queryParameters['orgId'] ?? ''),
            ),
            GoRoute(
              path: 'invite',
              builder: (c, s) => org_invite.InviteScreen(orgId: s.uri.queryParameters['orgId'] ?? ''),
            ),
          ],
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectHome(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateProjectScreen()),
            GoRoute(
              path: ':projectId',
              builder: (c, s) => ProjectMore(),
              routes: [
                GoRoute(path: 'timeline', builder: (c, s) => const ProjectTimelineScreen()),
                GoRoute(path: 'task/create', builder: (c, s) => const CreateTaskScreen()),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
          routes: [
            GoRoute(path: 'my', builder: (c, s) => const MyTasksScreen()),
            GoRoute(path: 'create', builder: (c, s) => const ts.CreateTaskScreen()),
            GoRoute(path: ':taskId', builder: (c, s) => const TaskDetailScreen()),
          ],
        ),
        GoRoute(
          path: '/issues',
          builder: (context, state) => const IssuesScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateIssueScreen()),
            GoRoute(path: ':issueId', builder: (c, s) => const IssueDetailScreen()),
          ],
        ),
        GoRoute(
          path: '/tickets',
          builder: (context, state) => const TicketsScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateTicketScreen()),
            GoRoute(path: ':ticketId', builder: (c, s) => const TicketDetailScreen()),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatScreen(),
          routes: [
            GoRoute(path: ':channelId', builder: (c, s) => const ChatScreen()),
          ],
        ),
        GoRoute(path: '/meetings', builder: (c, s) => const ScheduleMeet()),
        GoRoute(path: '/calls', builder: (c, s) => const CallsScreen()),
        GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentEditorScreen(),
          routes: [
            GoRoute(path: ':documentId', builder: (c, s) => const DocumentEditorScreen()),
          ],
        ),
        GoRoute(
          path: '/teams',
          builder: (context, state) => const AllTeamScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateTeamScreen()),
            GoRoute(path: ':teamId', builder: (c, s) => const TeamScreen()),
          ],
        ),
        GoRoute(
          path: '/workflows',
          builder: (context, state) => const WorkflowsScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateWorkflowScreen()),
            GoRoute(path: ':workflowId', builder: (c, s) => const WorkflowDetailScreen()),
          ],
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const ScheduleScreen(),
          routes: [
            GoRoute(path: 'create', builder: (c, s) => const CreateScheduleScreen()),
          ],
        ),
        GoRoute(
          path: '/files',
          builder: (context, state) => const StorageScreen(),
          routes: [
            GoRoute(path: 'upload', builder: (c, s) => const UploadScreen()),
          ],
        ),
        GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
        GoRoute(path: '/notifications', builder: (c, s) => const NotificationScreen()),
        GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        GoRoute(
          path: '/ai',
          builder: (context, state) => const AIAssistantScreen(),
          routes: [
            GoRoute(path: 'insights', builder: (c, s) => const AIInsightsScreen()),
          ],
        ),
        GoRoute(
          path: '/integrations',
          builder: (context, state) => const IntegrationsScreen(),
          routes: [
            GoRoute(path: ':integrationId', builder: (c, s) => const IntegrationSetupScreen()),
          ],
        ),
        GoRoute(path: '/audit', builder: (c, s) => const AuditLogScreen()),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => const fb.FeedbackScreen(),
          routes: [
            GoRoute(path: 'submit', builder: (c, s) => const SubmitFeedbackScreen()),
          ],
        ),
        GoRoute(
          path: '/billing',
          builder: (context, state) => const BillingScreen(),
          routes: [
            GoRoute(path: 'subscription', builder: (c, s) => const SubscriptionScreen()),
          ],
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
          routes: [
            GoRoute(path: 'users', builder: (c, s) => const AdminUsersScreen()),
            GoRoute(path: 'logs', builder: (c, s) => const AdminLogsScreen()),
            GoRoute(path: 'approvals', builder: (c, s) => const AdminApprovalsScreen()),
          ],
        ),
        GoRoute(path: '/roles', builder: (c, s) => const RolesScreen()),
        GoRoute(path: '/account', builder: (c, s) => const AccountScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsSection()),
        GoRoute(path: '/account/invite', builder: (c, s) => const InviteScreen()),
        GoRoute(path: '/support', builder: (c, s) => const SupportSection()),
        GoRoute(path: '/whats-new', builder: (c, s) => const WhatsNewScreen()),
        GoRoute(path: '/account/feedback', builder: (c, s) => const acct_fb.FeedbackScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Page not found: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
