import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
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

  // ─── Refresh ───────────────────────────────────────────────────────────────

  static Future<void> refreshUser(WidgetRef ref) async {
    await ref.read(currentUserProvider.notifier).fetchProfile();
  }

  // ─── Quick action definitions ──────────────────────────────────────────────

  static List<HomeQuickAction> quickActions(BuildContext context) => const [
        HomeQuickAction(
          icon: Icons.create_new_folder_outlined,
          title: 'New Project',
          subtitle: 'Start fresh',
          color: Color(0xFF3B82F6),
          route: '/projects/new',
        ),
        HomeQuickAction(
          icon: Icons.people_outline_rounded,
          title: 'Invite Team',
          subtitle: 'Collaborate',
          color: Color(0xFF10B981),
          route: '/team/invite',
        ),
        HomeQuickAction(
          icon: Icons.schedule_outlined,
          title: 'Schedule Meet',
          subtitle: 'Plan ahead',
          color: Color(0xFF8B5CF6),
          route: '/meetings/new',
        ),
        HomeQuickAction(
          icon: Icons.analytics_outlined,
          title: 'View Reports',
          subtitle: 'Track progress',
          color: Color(0xFFF59E0B),
          route: '/analytics',
        ),
      ];

  // ─── Workspace tool definitions ────────────────────────────────────────────

  static List<HomeWorkspaceTool> workspaceTools() => const [
        HomeWorkspaceTool(
          icon: Icons.translate_rounded,
          title: 'Translator',
          subtitle: 'Break language barriers',
          route: '/translator',
        ),
        HomeWorkspaceTool(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Team Chat',
          subtitle: 'Stay connected with your team',
          route: '/chats',
        ),
        HomeWorkspaceTool(
          icon: Icons.video_call_outlined,
          title: 'Video Calls',
          subtitle: 'Face-to-face meetings',
          route: '/calls',
        ),
      ];
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
