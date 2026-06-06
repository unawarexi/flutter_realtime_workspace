import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/project_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/admin_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/analytics_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/collaboration_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/integration_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/project_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/schedule_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/task_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/team_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/workflow_usecase.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';

/// All business logic and derived data for the home screen.
///
/// The UI layer stays pure — it only calls helpers from here.
class HomeUseCase {
  HomeUseCase._();

  // ─── Greeting ──────────────────────────────────────────────────────────────

  /// Returns a time-aware greeting: Good morning / afternoon / evening.
  static String greeting() {
    final hour = TimeOfDay.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ─── Current user helpers ──────────────────────────────────────────────────

  static UserModel? currentUser(WidgetRef ref) {
    return ref.watch(currentUserProvider).valueOrNull;
  }

  static bool isLoadingUser(WidgetRef ref) {
    return ref.watch(currentUserProvider).isLoading;
  }

  static String? userError(WidgetRef ref) {
    return ref.watch(currentUserProvider).hasError
        ? ref.watch(currentUserProvider).error.toString()
        : null;
  }

  static String displayName(WidgetRef ref) {
    final user = currentUser(ref);
    final name = user?.displayName?.trim() ?? user?.fullName.trim() ?? '';
    return name.isNotEmpty ? name : 'there';
  }

  static String photoUrl(WidgetRef ref) {
    return currentUser(ref)?.profilePicture ?? '';
  }

  static String userId(WidgetRef ref) {
    return currentUser(ref)?.id ?? '';
  }

  static String role(WidgetRef ref) {
    return currentUser(ref)?.permissionsLevel ?? 'guest';
  }

  static String roleLabel(WidgetRef ref) {
    return PermissionHelper.roleLabel(role(ref));
  }

  // ─── Refresh ───────────────────────────────────────────────────────────────

  static Future<void> refreshUser(WidgetRef ref) async {
    await ref.read(currentUserProvider.notifier).fetchProfile();
  }

  // ─── Quick action definitions ──────────────────────────────────────────────

  static List<HomeQuickAction> quickActions(WidgetRef ref) {
    final actions = <HomeQuickAction>[];

    if (ProjectUseCase.canCreateProject(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.create_new_folder_outlined,
        title: 'New Project',
        subtitle: 'Start a workspace project',
        color: Color(0xFF3B82F6),
        route: '/projects/create',
      ));
    }

    if (TaskUseCase.canCreateTask(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.task_alt_outlined,
        title: 'Create Task',
        subtitle: 'Assign and track work',
        color: Color(0xFF0EA5E9),
        route: '/tasks/create',
      ));
    }

    if (TeamUseCase.canCreateTeam(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.group_add_outlined,
        title: 'Create Team',
        subtitle: 'Organize collaborators',
        color: Color(0xFF10B981),
        route: '/teams/create',
      ));
    }

    if (ScheduleUseCase.canCreateSchedule(ref) ||
        CollaborationUseCase.canCreateMeeting(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.schedule_outlined,
        title: 'Schedule',
        subtitle: 'Plan meetings and events',
        color: Color(0xFF8B5CF6),
        route: '/schedule/create',
      ));
    }

    if (AnalyticsUseCase.canViewAnalytics(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.analytics_outlined,
        title: 'View Reports',
        subtitle: 'Track team performance',
        color: Color(0xFFF59E0B),
        route: '/analytics',
      ));
    }

    if (WorkflowUseCase.canCreateWorkflow(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.route_outlined,
        title: 'New Workflow',
        subtitle: 'Automate repetitive tasks',
        color: Color(0xFFEC4899),
        route: '/workflows/create',
      ));
    }

    if (IntegrationUseCase.canManageIntegrations(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.extension_outlined,
        title: 'Integrations',
        subtitle: 'Connect external tools',
        color: Color(0xFF14B8A6),
        route: '/integrations',
      ));
    }

    if (AdminUseCase.canAccessAdmin(ref)) {
      actions.add(const HomeQuickAction(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin Panel',
        subtitle: 'Manage tenant and users',
        color: Color(0xFFEF4444),
        route: '/admin',
      ));
    }

    return actions.take(8).toList();
  }

  static List<HomeQuickAction> fallbackQuickActions() {
    return [
      const HomeQuickAction(
        icon: Icons.search_outlined,
        title: 'Search',
        subtitle: 'Find anything quickly',
        color: Color(0xFF6366F1),
        route: '/search',
      ),
      const HomeQuickAction(
        icon: Icons.auto_awesome_outlined,
        title: 'AI Assistant',
        subtitle: 'Ask TeamSpot AI',
        color: Color(0xFF8B5CF6),
        route: '/ai',
      ),
      const HomeQuickAction(
        icon: Icons.notifications_none_outlined,
        title: 'Updates',
        subtitle: 'Check notifications',
        color: Color(0xFFF59E0B),
        route: '/notifications',
      ),
      const HomeQuickAction(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'Manage preferences',
        color: Color(0xFF64748B),
        route: '/settings',
      ),
    ];
  }

  // ─── Workspace tool definitions ────────────────────────────────────────────

  static List<HomeWorkspaceTool> workspaceTools(WidgetRef ref) {
    final tools = <HomeWorkspaceTool>[
      const HomeWorkspaceTool(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Team Chat',
        subtitle: 'Stay connected with your team',
        route: '/chat',
      ),
      const HomeWorkspaceTool(
        icon: Icons.video_call_outlined,
        title: 'Calls',
        subtitle: 'Live meetings and standups',
        route: '/calls',
      ),
      const HomeWorkspaceTool(
        icon: Icons.description_outlined,
        title: 'Documents',
        subtitle: 'Docs, notes and shared files',
        route: '/documents',
      ),
      const HomeWorkspaceTool(
        icon: Icons.confirmation_number_outlined,
        title: 'Tickets',
        subtitle: 'Support and issue queue',
        route: '/tickets',
      ),
    ];

    if (AdminUseCase.canAccessAdmin(ref)) {
      tools.add(const HomeWorkspaceTool(
        icon: Icons.manage_accounts_outlined,
        title: 'Role Control',
        subtitle: 'Roles and permissions',
        route: '/roles',
      ));
    }

    return tools;
  }

  static String summaryLine({
    required int projectCount,
    required int taskCount,
    required int issueCount,
  }) {
    return '$projectCount active projects  •  $taskCount tasks  •  $issueCount issues';
  }

  static List<HomeActivityItem> recentActivity({
    required List<ProjectModel> projects,
    required List<TaskModel> tasks,
    required List<IssueModel> issues,
    int limit = 4,
  }) {
    final items = <HomeActivityItem>[
      ...projects.map((p) => HomeActivityItem(
            icon: Icons.folder_outlined,
            title: p.name,
            subtitle: 'Project  •  ${ProjectUseCase.statusLabel(p.status)}',
            date: p.updatedAt,
            color: const Color(0xFF3B82F6),
          )),
      ...tasks.map((t) => HomeActivityItem(
            icon: Icons.task_alt_outlined,
            title: t.title,
            subtitle: 'Task  •  ${t.status.replaceAll('_', ' ')}',
            date: t.updatedAt,
            color: const Color(0xFF0EA5E9),
          )),
      ...issues.map((i) => HomeActivityItem(
            icon: Icons.bug_report_outlined,
            title: i.title,
            subtitle: 'Issue  •  ${i.status.replaceAll('_', ' ')}',
            date: i.updatedAt,
            color: const Color(0xFFF59E0B),
          )),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(limit).toList();
  }

  static String timeAgo(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ─── Value objects ─────────────────────────────────────────────────────────────

class HomeQuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class HomeWorkspaceTool {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const HomeWorkspaceTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class HomeActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;

  const HomeActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
  });
}
