import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/network/pull_refresh.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/options_screen.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/issue_provider.dart';
import 'package:flutter_realtime_workspace/store/notification_provider.dart';
import 'package:flutter_realtime_workspace/store/project_provider.dart';
import 'package:flutter_realtime_workspace/store/task_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

// ── Extracted home widgets ───────────────────────────────────────
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_welcome.dart';
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_recent_activity.dart';
import 'package:flutter_realtime_workspace/app/features/home/presentation/widgets/home_workspace_tools.dart';

// ── Decorative shapes / painters ────────────────────────────────
import 'package:flutter_realtime_workspace/app/components/shapes/shapes.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    await ref.read(currentUserProvider.notifier).fetchProfile();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final userState = ref.watch(currentUserProvider);
    final isLoading = userState.isLoading;
    final hasError = userState.hasError;
    final user = userState.valueOrNull;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspaceId = activeWorkspace?.id ??
        ((user != null && user.workspaceIds.isNotEmpty)
            ? user.workspaceIds.first
            : null);

    final projectsState = ref.watch(projectsProvider(workspaceId));
    final tasksState = ref.watch(tasksProvider({
      'workspaceId': workspaceId,
      'projectId': null,
      'assigneeId': null,
      'status': null,
    }));
    final issuesState = ref.watch(issuesProvider({
      'workspaceId': workspaceId,
      'projectId': null,
      'assigneeId': null,
      'status': null,
      'priority': null,
    }));
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final projects = projectsState.valueOrNull ?? const [];
    final tasks = tasksState.valueOrNull ?? const [];
    final issues = issuesState.valueOrNull ?? const [];

    final summaryText = HomeUseCase.summaryLine(
      projectCount: projects.length,
      taskCount: tasks.length,
      issueCount: issues.length,
    );

    final activityItems = HomeUseCase.recentActivity(
      projects: projects,
      tasks: tasks,
      issues: issues,
      limit: 4,
    );
    final roleLabel = HomeUseCase.roleLabel(ref);

    return Scaffold(
      backgroundColor:
          isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: Stack(
        children: [
          // ── Subtle dot-grid texture ──────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDarkMode ? Colors.white : Colors.blueGrey)
                    .withValues(alpha: isDarkMode ? 0.04 : 0.055),
                spacing: 26,
                dotRadius: 1.0,
              ),
            ),
          ),
          // ── Soft accent orb (top-right corner) ───────────────
          Positioned(
            top: -70,
            right: -70,
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: TOrbFieldPainter(
                  colors: [
                    isDarkMode
                        ? TColors.buttonPrimary
                        : TColors.buttonPrimaryLight,
                    TColors.lightBlue,
                  ],
                  orbCount: 2,
                  isDark: isDarkMode,
                  seed: 7,
                ),
              ),
            ),
          ),
          // ── Scrollable content ────────────────────────────────
          SafeArea(
            child: AdvancedPullRefresh(
              onRefresh: () => _onRefresh(context, ref),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 10.0),
                      child: Builder(
                        builder: (context) {
                          if (isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (hasError) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrganisationOptionsScreen(),
                                ),
                              );
                            });
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              HomeHeader(
                                isDark: isDarkMode,
                                unreadCount: unreadCount,
                                roleLabel: roleLabel,
                              ),
                              const SizedBox(height: 18),
                              HomeWelcome(
                                isDark: isDarkMode,
                                summaryText: summaryText,
                                roleLabel: roleLabel,
                              ),
                              const SizedBox(height: 14),
                              HomeSearchBar(isDark: isDarkMode),
                              const SizedBox(height: 18),
                              HomeQuickActions(isDark: isDarkMode),
                              const SizedBox(height: 18),
                              HomeRecentActivity(
                                isDark: isDarkMode,
                                items: activityItems,
                                isLoading: projectsState.isLoading ||
                                    tasksState.isLoading ||
                                    issuesState.isLoading,
                              ),
                              const SizedBox(height: 18),
                              HomeWorkspaceTools(isDark: isDarkMode),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
