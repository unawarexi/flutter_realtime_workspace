# TeamSpot Flutter — AI Skills Reference

> **App**: TeamSpot — Real-time collaborative workspace platform
> **Package**: `flutter_realtime_workspace`
> **Flutter SDK**: >=3.5.0
> **Dart SDK**: ^3.5.2
> **State Management**: Riverpod 2.5 (flutter_riverpod)
> **Navigation**: GoRouter 16.1
> **Design System**: Material 3 + Poppins + TColors
> **Backend**: Node.js (Express 5) at configured base URL
> **Auth**: Firebase Auth (Google OAuth, GitHub OAuth) + Biometric (local_auth)
> **Real-time**: Socket.IO client 3.1 + LiveKit Flutter SDK (WebRTC video)
> **Monitoring**: Sentry Flutter 9.20
> **Updated**: 2025

---

## Table of Contents

1. [Directory Structure](#1-directory-structure)
2. [Entry Point & App Setup](#2-entry-point--app-setup)
3. [State Management (Riverpod)](#3-state-management-riverpod)
4. [Routing / Navigation (GoRouter)](#4-routing--navigation-gorouter)
5. [Feature Modules](#5-feature-modules)
6. [Domain Models](#6-domain-models)
7. [Repositories](#7-repositories)
8. [Riverpod Providers (Store)](#8-riverpod-providers-store)
9. [Network Layer (Dio + Interceptors)](#9-network-layer-dio--interceptors)
10. [Local Storage (Hive + TTL)](#10-local-storage-hive--ttl)
11. [Theme / Design System](#11-theme--design-system)
12. [Real-time (Socket.IO)](#12-real-time-socketio)
13. [Authentication](#13-authentication)
14. [Notifications (FCM)](#14-notifications-fcm)
15. [Components / Widgets](#15-components--widgets)
16. [Platform Configuration](#16-platform-configuration)
17. [Assets](#17-assets)
18. [Build & Scripts](#18-build--scripts)
19. [API Endpoints Reference](#19-api-endpoints-reference)

---

## 1. Directory Structure

```
lib/
├── main.dart                          # App entry point — bootstrap, Firebase, Hive, Sentry
├── app.dart                           # TeamSpotApp widget — MaterialApp.router + theme
├── firebase_options.dart              # FlutterFire platform-specific Firebase config
├── injection_container.dart           # Dependency injection setup
│
├── app/
│   ├── components/
│   │   ├── shapes/
│   │   │   ├── shapes.dart            # Barrel export for all shape files
│   │   │   ├── bg_patterns.dart       # Background pattern painters
│   │   │   ├── curved_clippers.dart   # Custom ClipPath shapes
│   │   │   └── decorative_painters.dart # CustomPainter decorations
│   │   ├── ui/
│   │   │   ├── activity_indicator.dart # SActivityIndicator, SLoadingOverlay
│   │   │   ├── bottom_sheet.dart      # SBottomSheet (iOS blur backdrop)
│   │   │   ├── button.dart            # SButton (5 variants), SIconButton
│   │   │   ├── card.dart              # SCard, generic card components
│   │   │   ├── connectivity_toast.dart # ConnectivityToast (auto offline/online banner)
│   │   │   ├── dense_widgets.dart     # SectionHeader, DenseTile, CompactTile
│   │   │   ├── input.dart             # SInput, SSearchBar
│   │   │   ├── modal.dart             # SModal (Cupertino alert dialog)
│   │   │   ├── skeleton.dart          # SSkeleton loading placeholders
│   │   │   └── toast_notifier.dart    # SToast (fluttertoast wrapper)
│   │   └── widgets/
│   │       ├── app_bar.dart           # Custom AppBar widget
│   │       ├── date_time_picker.dart  # Date/time picker widget
│   │       ├── fab.dart               # Floating action button
│   │       ├── input_fields.dart      # Specialized input fields
│   │       └── spinners.dart          # Loading spinner variants
│   │
│   ├── domain/
│   │   ├── models/                    # 28 Dart data models (freezed + json_serializable)
│   │   │   ├── ai_models.dart         # AIConversation, AIMessage, AITool, EmbeddingResult
│   │   │   ├── audit_model.dart       # AuditLog, AuditActor, AuditChange
│   │   │   ├── auth_session_model.dart # AuthSession, SessionDevice, TokenPair
│   │   │   ├── channel_model.dart     # ChannelModel, ChannelType, ChannelMember
│   │   │   ├── chat_model.dart        # ChatMessage, ChatRoom, ChatMember
│   │   │   ├── document_model.dart    # DocumentModel, DocumentVersion, FileMetadata
│   │   │   ├── feedback_model.dart    # FeedbackModel, FeedbackCategory, FeedbackStatus
│   │   │   ├── integration_model.dart # IntegrationModel, IntegrationType, IntegrationConfig
│   │   │   ├── issue_model.dart       # IssueModel, IssueSeverity, IssueStatus
│   │   │   ├── legal_model.dart       # LegalDocument, LegalSection
│   │   │   ├── material_model.dart    # MeetingMaterialModel
│   │   │   ├── meeting_model.dart     # MeetingModel, MeetingStatus, MeetingType
│   │   │   ├── message_model.dart     # MessageModel, MessageType, MessageReaction
│   │   │   ├── notification_model.dart # NotificationModel, NotificationType, NotificationPriority
│   │   │   ├── organization_model.dart # OrganizationModel, OrgPlan, OrgQuota
│   │   │   ├── participant_model.dart # ParticipantModel, ParticipantRole
│   │   │   ├── project_model.dart     # ProjectModel, ProjectStatus, ProjectPriority
│   │   │   ├── recording_model.dart   # RecordingModel, RecordingStatus
│   │   │   ├── referral_model.dart    # ReferralModel, ReferralStatus
│   │   │   ├── role_model.dart        # RoleModel, Permission, PolicyRule
│   │   │   ├── schedule_model.dart    # ScheduleModel, RecurrenceRule, TimeSlot
│   │   │   ├── storage_model.dart     # AssetModel, AssetType, CloudinaryVariant
│   │   │   ├── subscription_model.dart # SubscriptionModel, SubscriptionPlan, BillingCycle
│   │   │   ├── task_model.dart        # TaskModel, TaskStatus, TaskPriority, Checklist
│   │   │   ├── team_model.dart        # TeamModel, TeamType, TeamMember
│   │   │   ├── template_model.dart    # TemplateModel, TemplateType, TemplateVariable
│   │   │   ├── ticket_model.dart      # TicketModel, TicketCategory, SLAConfig
│   │   │   ├── user_model.dart        # UserModel, UserRole, WorkingHours, DeviceModel
│   │   │   ├── workflow_model.dart    # WorkflowModel, WorkflowTrigger, WorkflowAction
│   │   │   └── workspace_model.dart   # WorkspaceModel, WorkspaceMember, WorkspaceSettings
│   │   └── repositories/              # 30 repository interfaces (abstract classes)
│   │       ├── admin_repository.dart
│   │       ├── ai_repository.dart
│   │       ├── analytics_repository.dart
│   │       ├── audit_repository.dart
│   │       ├── auth_repository.dart
│   │       ├── billing_repository.dart
│   │       ├── channel_repository.dart
│   │       ├── chat_repository.dart
│   │       ├── document_repository.dart
│   │       ├── feedback_repository.dart
│   │       ├── integration_repository.dart
│   │       ├── issue_repository.dart
│   │       ├── legal_repository.dart
│   │       ├── meeting_repository.dart
│   │       ├── notification_repository.dart
│   │       ├── organization_repository.dart
│   │       ├── project_repository.dart
│   │       ├── recording_repository.dart
│   │       ├── role_repository.dart
│   │       ├── schedule_repository.dart
│   │       ├── search_repository.dart
│   │       ├── storage_repository.dart
│   │       ├── task_repository.dart
│   │       ├── team_repository.dart
│   │       ├── template_repository.dart
│   │       ├── ticket_repository.dart
│   │       ├── user_repository.dart
│   │       ├── whiteboard_repository.dart
│   │       ├── workflow_repository.dart
│   │       └── workspace_repository.dart
│   │
│   ├── features/                      # 25 feature modules (Feature-First Clean Architecture)
│   │   ├── admin/                     # Tenant admin: impersonation, org stats, SLA management
│   │   ├── ai/                        # AI assistant chat, RAG query, tool execution
│   │   ├── analytics/                 # Usage reports, project analytics, team stats
│   │   ├── audit/                     # Audit log viewer
│   │   ├── authentication/            # Login, signup, onboarding, 2FA, social sign-in
│   │   ├── billing/                   # Subscription management, invoices, Stripe checkout
│   │   ├── collaboration/             # Channels, direct messages, whiteboards
│   │   ├── dashboard/                 # Home dashboard with recent activity
│   │   ├── feedback/                  # User feedback submission, bug reports
│   │   ├── home/                      # Home screen with workspace context
│   │   ├── identity/                  # IAM roles, permissions, user policy management
│   │   ├── integrations/              # GitHub, Slack, Google Drive, Jira, Zoom connect
│   │   ├── issues/                    # Issue tracking (bug reports, feature requests)
│   │   ├── legal/                     # Terms of service, privacy policy viewer
│   │   ├── notification/              # Notification center + preferences
│   │   ├── organizations/             # Organization management, member invites
│   │   ├── project/                   # Project CRUD, timeline, kanban, progress
│   │   ├── schedules/                 # Advanced scheduling, recurring events
│   │   ├── search/                    # Global search across all workspace entities
│   │   ├── settings/                  # User preferences, notifications, security
│   │   ├── storage/                   # File/media asset management (Cloudinary)
│   │   ├── tasks/                     # Task tracking, assignment, checklist
│   │   ├── team/                      # Team management, members, permissions
│   │   ├── tickets/                   # Support ticket system with SLA tracking
│   │   ├── workflows/                 # Automation rule builder (trigger -> condition -> action)
│   │   └── workspaces/                # Workspace creation, settings, invite management
│   │
│   └── screens/                       # Cross-feature screens
│       ├── home_screen.dart
│       ├── onboarding/
│       ├── settings/
│       └── splash/
│
├── core/
│   ├── apis/
│   │   └── endpoints.dart             # ALL API paths (centralized, matches backend routes)
│   ├── auth/
│   │   ├── google_sign_in.dart        # GoogleSignInService.signIn() / signOut()
│   │   ├── github_sign_in.dart        # GitHub OAuth flow
│   │   └── biometric_auth.dart        # local_auth: Face ID / fingerprint / PIN
│   ├── config/
│   │   ├── base_url.dart              # AppBaseUrl.api (from dart_defines env)
│   │   └── app_config.dart            # Environment-specific configuration
│   ├── constants/
│   │   ├── colors.dart                # TColors design system
│   │   ├── icons.dart                 # Custom icon constants
│   │   ├── sizes.dart                 # Spacing + size constants (TSize)
│   │   ├── text_strings.dart          # UI copy strings
│   │   └── responsive.dart            # SResponsive breakpoints
│   ├── db/
│   │   └── hive.dart                  # HiveService: init, TTL cache, prune expired
│   ├── errors/
│   │   ├── exceptions.dart            # ServerException, CacheException, NetworkException
│   │   └── failures.dart              # ServerFailure, CacheFailure (Either pattern)
│   ├── network/
│   │   ├── api_client.dart            # Dio singleton + interceptor chain
│   │   ├── connectivity_interceptor.dart
│   │   ├── auth_interceptor.dart      # Inject Bearer + auto token refresh
│   │   └── retry_interceptor.dart     # Retry on 500/network errors
│   ├── services/
│   │   ├── local_storage_service.dart # Non-sensitive prefs (shared_preferences)
│   │   ├── secure_storage_service.dart # JWT tokens (FlutterSecureStorage)
│   │   ├── notification_service.dart  # Local notification scheduling
│   │   └── websocket_service.dart     # Socket.IO client lifecycle
│   └── utils/
│       ├── date_formatter.dart
│       ├── file_picker_helper.dart
│       ├── permission_handler.dart
│       └── validators.dart
│
├── router/
│   └── app_router.dart                # GoRouter: 50+ routes + auth guard + deep links
│
├── store/                             # Riverpod providers (one per domain)
│   ├── admin_provider.dart
│   ├── ai_provider.dart
│   ├── analytics_provider.dart
│   ├── audit_provider.dart
│   ├── auth_provider.dart
│   ├── billing_provider.dart
│   ├── channel_provider.dart
│   ├── chat_provider.dart
│   ├── connectivity_provider.dart
│   ├── document_provider.dart
│   ├── feedback_provider.dart
│   ├── integration_provider.dart
│   ├── issue_provider.dart
│   ├── legal_provider.dart
│   ├── meeting_provider.dart
│   ├── notification_provider.dart
│   ├── organization_provider.dart
│   ├── project_provider.dart
│   ├── recording_provider.dart
│   ├── role_provider.dart
│   ├── schedule_provider.dart
│   ├── search_provider.dart
│   ├── settings_provider.dart
│   ├── storage_provider.dart
│   ├── task_provider.dart
│   ├── team_provider.dart
│   ├── template_provider.dart
│   ├── theme_provider.dart
│   ├── ticket_provider.dart
│   ├── user_provider.dart
│   ├── workflow_provider.dart
│   └── workspace_provider.dart
│
└── theme/
    ├── app_theme.dart                 # TAppTheme.light() + TAppTheme.dark()
    ├── custom_themes/
    │   ├── appbar_theme.dart
    │   ├── bottom_sheet_theme.dart
    │   ├── button_theme.dart
    │   ├── chip_theme.dart
    │   ├── input_decoration_theme.dart
    │   └── text_theme.dart            # Poppins text theme mapping
    └── theme_utils.dart
```

---

## 2. Entry Point & App Setup

### `lib/main.dart` — Bootstrap Sequence
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveService.init();
  await LocalStorageService.init();
  await GoogleSignInService.init();

  // FCM background handler (Android only)
  if (!kIsWeb && Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await NotificationService.init();

  if (kReleaseMode) {
    await SentryFlutter.init((options) {
      options.dsn = dotenv.env["SENTRY_DSN"] ?? "";
      options.tracesSampleRate = 0.1;
    }, appRunner: () => runApp(ProviderScope(child: TeamSpotApp())));
  } else {
    runApp(ProviderScope(child: TeamSpotApp()));
  }
}
```

### `lib/app.dart` — Root Widget
```dart
class TeamSpotApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: "TeamSpot",
      theme: TAppTheme.light(),
      darkTheme: TAppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) => ConnectivityToast(child: child!),
    );
  }
}
```

---

## 3. State Management (Riverpod)

All providers follow the `StateNotifier` pattern with sealed `XxxState` classes:

```dart
// store/task_provider.dart
@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  TaskState build() => const TaskState.initial();

  Future<void> loadTasks(String projectId) async {
    state = const TaskState.loading();
    final result = await ref.read(taskRepositoryProvider).getTasks(projectId);
    result.fold(
      (failure) => state = TaskState.error(failure.message),
      (tasks)   => state = TaskState.loaded(tasks),
    );
  }

  Future<void> createTask(CreateTaskParams params) async {
    final result = await ref.read(taskRepositoryProvider).createTask(params);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (task)    => state = state.copyWith(tasks: [...state.tasks!, task]),
    );
  }
}
```

Repositories injected via Riverpod (overridable for testing):
```dart
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    apiClient: ref.read(apiClientProvider),
    hive: ref.read(hiveServiceProvider),
  );
});
```

---

## 4. Routing / Navigation (GoRouter)

### Auth Guard
```dart
Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final firebaseLoggedIn = FirebaseAuth.instance.currentUser != null;
  final backendToken = await SecureStorageService.getAccessToken();
  final isLoggedIn = firebaseLoggedIn || (backendToken?.isNotEmpty ?? false);
  final hasSeenOnboarding = LocalStorageService.hasSeenOnboarding;

  if (!isLoggedIn) {
    if (!hasSeenOnboarding) return "/onboarding";
    if (!publicPaths.contains(state.uri.path)) return "/login";
  }
  if (isLoggedIn && publicPaths.contains(state.uri.path)) return "/home";
  return null;
}
```

### Route Table
| Path | Screen | Auth |
|------|--------|------|
| `/splash` | SplashScreen | No |
| `/onboarding` | OnboardingScreen | No |
| `/login` | LoginScreen | No |
| `/signup` | SignupScreen | No |
| `/terms` | TermsScreen | No |
| `/privacy` | PrivacyScreen | No |
| `/home` | HomeScreen | Yes (Shell) |
| `/projects` | ProjectHomeScreen | Yes (Shell) |
| `/tasks` | TasksScreen | Yes (Shell) |
| `/channels` | ChannelsScreen | Yes (Shell) |
| `/ai` | AIAssistantScreen | Yes (Shell) |
| `/projects/:id` | ProjectDetailScreen | Yes |
| `/projects/:id/tasks/:taskId` | TaskDetailScreen | Yes |
| `/meetings/:id` | MeetingRoomScreen | Yes |
| `/channels/:id` | ChannelDetailScreen | Yes |
| `/workspaces` | WorkspacesScreen | Yes |
| `/organizations` | OrganizationsScreen | Yes |
| `/settings` | SettingsScreen | Yes |
| `/billing` | BillingScreen | Yes |
| `/admin` | AdminDashboardScreen | Yes (admin) |

---

## 5. Feature Modules

Each feature under `lib/app/features/{name}/`:
```
features/{feature}/
├── presentation/
│   ├── screens/   # Full page screens (routed via GoRouter)
│   └── widgets/   # Feature-specific widgets
└── usecases/      # Business orchestration (repository + transform)
```

| Feature | Key Screens |
|---------|------------|
| `authentication` | LoginScreen, SignupScreen, TwoFAScreen, SocialSignInScreen |
| `workspaces` | WorkspaceListScreen, WorkspaceDetailScreen, CreateWorkspaceScreen |
| `organizations` | OrgDashboardScreen, OrgSettingsScreen, MemberManagementScreen |
| `project` | ProjectListScreen, KanbanBoardScreen, TimelineScreen, ProjectDetailScreen |
| `tasks` | TaskListScreen, TaskDetailScreen, MyTasksScreen |
| `issues` | IssueListScreen, IssueDetailScreen, ReportIssueScreen |
| `tickets` | TicketListScreen, TicketDetailScreen, CreateTicketScreen |
| `team` | TeamListScreen, TeamDetailScreen, CreateTeamScreen |
| `collaboration` | ChannelListScreen, ChannelDetailScreen, DirectMessageScreen |
| `ai` | AIAssistantScreen, ConversationHistoryScreen |
| `meetings` | MeetingRoomScreen, ScheduleMeetingScreen, MeetingHistoryScreen |
| `notification` | NotificationCenterScreen, NotificationPreferencesScreen |
| `billing` | PlansScreen, CheckoutScreen, InvoiceHistoryScreen |
| `storage` | FileManagerScreen, UploadScreen |
| `search` | GlobalSearchScreen, SearchResultsScreen |
| `settings` | ProfileSettingsScreen, SecuritySettingsScreen, AppearanceScreen |
| `admin` | AdminDashboardScreen, TenantManagementScreen, ImpersonationScreen |
| `analytics` | AnalyticsDashboardScreen, ProjectReportScreen |
| `workflows` | WorkflowListScreen, WorkflowBuilderScreen |
| `integrations` | IntegrationsListScreen, IntegrationSetupScreen |
| `schedules` | ScheduleCalendarScreen, CreateScheduleScreen |
| `identity` | RolesListScreen, PermissionEditorScreen |
| `legal` | TermsScreen, PrivacyPolicyScreen |
| `feedback` | FeedbackFormScreen |
| `audit` | AuditLogScreen, AuditDetailScreen |

---

## 6. Domain Models

All in `lib/app/domain/models/`, using `freezed` + `json_serializable`:

| Model | Key Fields |
|-------|-----------|
| `UserModel` | id, email, displayName, avatar, tenantId, orgId, workspaceIds, roleTitle, permissionsLevel (super_admin/admin/manager/member/guest), totpEnabled, workingHours |
| `WorkspaceModel` | id, name, slug, tenantId, orgId, owner, members, settings, isDefault |
| `OrganizationModel` | id, name, slug, tenantId, owner, plan (free/starter/professional/enterprise), quotas |
| `ProjectModel` | id, name, key (PROJ-001), tenantId, workspaceId, status, priority, collaborators, progress (0-100), budget |
| `TaskModel` | id, title, tenantId, projectId, assignedTo, status (todo/in_progress/done/blocked), priority, checklist, labels, dueDate |
| `IssueModel` | id, title, tenantId, projectId, assignedTo, reporter, severity, environment, linkedIssues |
| `TicketModel` | id, ticketNumber, tenantId, reporter, assignedTo, category, status, priority, sla |
| `ChannelModel` | id, name, slug, tenantId, workspaceId, type (public/private/dm), topic, members |
| `MessageModel` | id, channelId, tenantId, sender, content, type, reactions, editedAt |
| `MeetingModel` | id, title, tenantId, workspaceId, organizer, participants, liveKitRoomName, status, scheduledAt |
| `TeamModel` | id, name, slug, tenantId, orgId, type, members, stats |
| `NotificationModel` | id, tenantId, recipientId, type, title, body, channel, resource, read, priority |
| `DocumentModel` | id, tenantId, workspaceId, file (url/size/mimeType), parsedContent, sharedWith, versions |
| `SubscriptionModel` | id, tenantId, orgId, plan, status, billingCycle, seats (purchased/used), stripeId |
| `WorkflowModel` | id, tenantId, name, trigger (type/config), conditions, actions, enabled, lastRun |
| `ScheduleModel` | id, tenantId, workspaceId, title, recurrenceRule, startTime, endTime, participants |
| `AIConversation` | id, tenantId, userId, title, messages, context, tokenUsage, model, status |
| `AuditLog` | id, tenantId, action, category, actor (userId/email/ip), target, changes (before/after) |
| `IntegrationModel` | id, tenantId, orgId, name, type (github/slack/google_drive/jira/zoom), config, enabled |
| `RoleModel` | id, tenantId, orgId, name, slug, permissions ({resource, actions[]}), isSystem |

---

## 7. Repositories

Interface + implementation pattern using `Either<Failure, T>` from `dartz`:

```dart
abstract class TaskRepository {
  Future<Either<Failure, List<TaskModel>>> getTasks(String projectId);
  Future<Either<Failure, TaskModel>> getTaskById(String taskId);
  Future<Either<Failure, TaskModel>> createTask(CreateTaskParams params);
  Future<Either<Failure, TaskModel>> updateTask(String id, UpdateTaskParams params);
  Future<Either<Failure, void>> deleteTask(String taskId);
  Future<Either<Failure, List<TaskModel>>> getMyTasks();
}
```

Implementations in `lib/app/data/repositories/` use `ApiClient` (network) + `HiveService` (cache).

---

## 8. Riverpod Providers (Store)

| Provider | State | Key Methods |
|----------|-------|-------------|
| `auth_provider` | AuthState (authenticated/unauthenticated/loading) | signIn, signOut, refreshToken |
| `workspace_provider` | WorkspaceState | loadWorkspaces, selectWorkspace, createWorkspace |
| `project_provider` | ProjectState | loadProjects, createProject, archiveProject |
| `task_provider` | TaskState | loadTasks, createTask, updateTaskStatus, assignTask |
| `channel_provider` | ChannelState | loadChannels, joinChannel, sendMessage |
| `meeting_provider` | MeetingState | createMeeting, joinMeeting, endMeeting, getLiveKitToken |
| `notification_provider` | NotificationState | loadNotifications, markAsRead, markAllAsRead |
| `ai_provider` | AIState | sendMessage, loadConversations, deleteConversation |
| `search_provider` | SearchState | search, clearResults |
| `connectivity_provider` | ConnectivityStatus | reactive stream — auto-updates on network change |
| `theme_provider` | ThemeMode | toggleTheme, setTheme |

---

## 9. Network Layer (Dio + Interceptors)

`core/network/api_client.dart` — Dio singleton, interceptor chain:



### Base URL
```dart
class AppBaseUrl {
  static String get api => const String.fromEnvironment(
    "API_BASE_URL", defaultValue: "http://10.0.2.2:5000/api/v1");
  static String get ws  => const String.fromEnvironment(
    "WS_BASE_URL", defaultValue: "http://10.0.2.2:5000");
}
```

---

## 10. Local Storage (Hive + TTL)

| Hive Box | Contents | TTL |
|----------|----------|-----|
| `user` | Current user profile | 5 min |
| `workspaces` | User's workspace list | 2 min |
| `meetings` | Upcoming meetings | 1 min |
| `notifications` | Recent notifications | 30 sec |
| `settings` | App preferences | No TTL |

**Tokens stored in FlutterSecureStorage ONLY — never Hive or SharedPreferences.**

---

## 11. Theme / Design System

### TColors
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#2563EB` | Primary actions, links |
| `secondary` | `#7C3AED` | Secondary actions, badges |
| `accent` | `#0EA5E9` | Highlights, indicators |
| `lightBg` | `#F7FAFC` | Light mode background |
| `darkBg` | `#0F172A` | Dark mode background |
| `darkSurface` | `#1E293B` | Dark mode card surface |
| `success` | `#10B981` | Success states |
| `warning` | `#F59E0B` | Warning states |
| `error` | `#EF4444` | Error states |

### Typography
- **Font**: Poppins (300 Light, 400 Regular, 500 Medium) — bundled in `assets/fonts/`
- Material 3 TextTheme mapped in `theme/custom_themes/text_theme.dart`

### Responsive Breakpoints (`SResponsive`)
- Mobile: < 768px — bottom navigation
- Tablet: 768–1024px — side rail, 2 columns
- Desktop: >= 1024px — full sidebar, multi-column

---

## 12. Real-time (Socket.IO)

`core/services/websocket_service.dart`:

```dart
void connect(String token) {
  _socket = IO.io(AppBaseUrl.ws, {
    "transports": ["websocket"],
    "auth": {"token": token},
    "reconnection": true,
    "reconnectionAttempts": 5,
    "reconnectionDelay": 1000,
  });
}
```

### Socket Events
| Event | Direction | Purpose |
|-------|-----------|---------|
| `auth:register` | C→S | Join `user:{id}` room |
| `chat:message` | C→S / S→C | Send / receive channel message |
| `chat:typing` | C→S | Typing indicator |
| `channel:join` | C→S | Subscribe to channel |
| `meeting:join` | C→S | Join meeting room |
| `presence:update` | C→S | Online/idle/offline/dnd |
| `notifications:new` | S→C | Push notification to user |
| `task:updated` | S→C | Real-time task state change |
| `ai:stream-token` | S→C | AI streaming response token |
| `presence:change` | S→C | Teammate presence update |

---

## 13. Authentication

### Flow
```
Google Sign-In → Firebase credential → POST /auth/social {idToken}
→ Backend JWT {accessToken, refreshToken, user}
→ SecureStorageService.saveAccessToken()
→ GoRouter redirects to /home
```

### Biometric (`core/auth/biometric_auth.dart`)
- iOS: Face ID / Touch ID
- Android: Fingerprint / Face unlock
- Fallback: device PIN via `local_auth`

### Token Storage Rule
```dart
// CORRECT — always use FlutterSecureStorage
await SecureStorageService.saveAccessToken(token);
// On sign-out
await SecureStorageService.clearAll();
// NEVER store tokens in SharedPreferences or plain Hive
```

---

## 14. Notifications (FCM)

```dart
// Background handler registered in main.dart (Android only)
@pragma("vm:entry-point")
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
```

| Notification Type | Trigger | Deep Link |
|------------------|---------|-----------|
| `task_assigned` | Task assigned to user | `/projects/:id/tasks/:taskId` |
| `meeting_starting` | 5 min before meeting | `/meetings/:id` |
| `message_received` | New channel message | `/channels/:id` |
| `mention` | User @ mentioned | Context-dependent |
| `workflow_triggered` | Automation fired | `/workflows/:id` |
| `billing_alert` | Subscription event | `/billing` |

---

## 15. Components / Widgets

| Component | Description |
|-----------|-------------|
| `SButton` | Primary / secondary / outlined / text / destructive variants |
| `SInput` | Text input with label, error, helper text |
| `SSearchBar` | Global search with debounce |
| `SCard` | Material 3 container card |
| `SBottomSheet` | iOS-style bottom sheet with drag handle |
| `SModal` | Cupertino confirmation dialog |
| `SSkeleton` | Loading skeleton placeholder |
| `ConnectivityToast` | App-wide offline/online toast overlay |
| `SActivityIndicator` | Platform-aware loading indicator |
| `SToast` | Success / error / info toast |

---

## 16. Platform Configuration

### Android
- Permissions: `INTERNET`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`
- Firebase Messaging service declaration in `AndroidManifest.xml`

### iOS
- `NSCameraUsageDescription` — meeting video
- `NSMicrophoneUsageDescription` — meeting audio
- `NSFaceIDUsageDescription` — biometric auth
- `NSPhotoLibraryUsageDescription` — file picker
- APN entitlements for push notifications

### Web
- Firebase JS SDK in `web/index.html`
- Service Worker (future: offline PWA)

---

## 17. Assets

```
assets/
├── fonts/
│   ├── Poppins-Light.ttf       # 300 weight
│   ├── Poppins-Regular.ttf     # 400 weight
│   └── Poppins-Medium.ttf      # 500 weight
├── icons/                      # Custom SVG/PNG icons
├── images/
│   ├── logo.png                # TeamSpot logo
│   ├── onboarding_*.png        # Onboarding illustrations
│   └── empty_states/           # Empty state illustrations
└── lottie/
    └── *.json                  # Lottie animations
```

---

## 18. Build & Scripts

```bash
# Development (Android emulator)
flutter run --dart-define-from-file=dart_defines/dev.json

# Staging
flutter run --dart-define-from-file=dart_defines/staging.json

# Release builds
flutter build apk --release --dart-define-from-file=dart_defines/prod.json
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json
flutter build ios --release --dart-define-from-file=dart_defines/prod.json
flutter build web --release --dart-define-from-file=dart_defines/prod.json

# Tests
flutter test
flutter test --coverage

# Fastlane CI/CD
bundle exec fastlane android deploy    # Play Store
bundle exec fastlane ios deploy        # App Store
```

### dart_defines/ Environment Files
```json
// dev.json
{
  "API_BASE_URL": "http://10.0.2.2:5000/api/v1",
  "WS_BASE_URL":  "http://10.0.2.2:5000",
  "SENTRY_DSN":   ""
}
// prod.json
{
  "API_BASE_URL": "https://api.teamspot.app/api/v1",
  "WS_BASE_URL":  "https://api.teamspot.app",
  "SENTRY_DSN":   "https://xxx@sentry.io/yyy"
}
```

---

## 19. API Endpoints Reference

All paths defined in `core/apis/endpoints.dart` — mirrors backend `modules/` routes:

| Category | Endpoints |
|----------|-----------|
| **Auth** | `POST /auth/social`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/2fa/enable`, `POST /auth/2fa/verify` |
| **Users** | `GET /users/me`, `PATCH /users/:id`, `DELETE /users/:id` |
| **Organizations** | `POST /organizations`, `GET /organizations/:id`, `PATCH /organizations/:id`, `POST /organizations/:id/invite` |
| **Workspaces** | `POST /workspaces`, `GET /workspaces`, `GET /workspaces/:id`, `POST /workspaces/:id/join` |
| **Teams** | `POST /teams`, `GET /teams`, `GET /teams/:id`, `POST /teams/:id/invite` |
| **Projects** | `POST /projects`, `GET /projects`, `GET /projects/:id`, `PATCH /projects/:id` |
| **Tasks** | `POST /tasks`, `GET /tasks`, `GET /tasks/:id`, `PATCH /tasks/:id`, `PATCH /tasks/:id/status` |
| **Issues** | `POST /issues`, `GET /issues`, `GET /issues/:id`, `POST /issues/:id/resolve` |
| **Tickets** | `POST /tickets`, `GET /tickets`, `GET /tickets/:id`, `PATCH /tickets/:id/status` |
| **Channels** | `POST /channels`, `GET /channels`, `POST /channels/:id/messages`, `GET /channels/:id/messages` |
| **Communication** | `POST /rooms/token`, `POST /rooms/create`, `POST /calls/initiate`, `POST /messages`, `GET /messages` |
| **Meetings** | `POST /meetings`, `GET /meetings`, `GET /meetings/:id`, `POST /meetings/:id/join`, `POST /meetings/:id/end` |
| **Schedules** | `POST /schedules`, `GET /schedules`, `GET /schedules/:id`, `PATCH /schedules/:id` |
| **Notifications** | `GET /notifications`, `PATCH /notifications/:id/read`, `POST /notifications/read-all` |
| **Documents** | `POST /documents`, `GET /documents`, `GET /documents/:id`, `DELETE /documents/:id` |
| **Storage** | `POST /storage/upload`, `GET /storage/assets`, `DELETE /storage/assets/:id` |
| **Search** | `GET /search?q=&type=&workspaceId=` |
| **AI** | `POST /ai/chat`, `GET /ai/conversations`, `DELETE /ai/conversations/:id`, `POST /ai/rag/query` |
| **Analytics** | `GET /analytics/dashboard`, `GET /analytics/projects/:id` |
| **Audit** | `GET /audit`, `GET /audit/:id` |
| **Admin** | `GET /admin/stats`, `POST /admin/impersonate`, `GET /admin/tenants` |
| **Billing** | `GET /billing/subscription`, `POST /billing/checkout`, `POST /billing/portal` |
| **Integrations** | `GET /integrations`, `POST /integrations/:type/connect`, `DELETE /integrations/:id` |
| **Workflows** | `POST /workflows`, `GET /workflows`, `PATCH /workflows/:id` |
| **Templates** | `GET /templates`, `POST /templates`, `PATCH /templates/:id` |
| **Feedback** | `POST /feedback` |
| **Identity** | `GET /identity/roles`, `POST /identity/roles`, `POST /identity/assign` |
| **Legal** | `GET /legal/terms`, `GET /legal/privacy` |

---

## Key Architecture Patterns

- **Feature-First Clean Architecture**: `presentation` → `usecase` → `repository` → `data`
- **Repository Pattern**: All API calls abstracted behind repository interfaces (testable, swappable)
- **StateNotifier**: Complex domain state with typed methods and sealed state classes
- **FutureProvider / FutureProvider.family**: Simple async data fetching, parameterized by ID
- **Offline-first Caching**: Hive TTL cache — stale-while-revalidate for user/workspace/meeting data
- **Auth Dual-Layer**: Firebase (social credential) + TeamSpot JWT (API authorization)
- **Secure Token Storage**: FlutterSecureStorage with iOS Keychain + Android Keystore encryption
- **Reactive Connectivity**: `connectivity_provider` streams network state → `ConnectivityToast` overlay
- **Deep Linking**: GoRouter handles `teamspot://` scheme + web URL paths
