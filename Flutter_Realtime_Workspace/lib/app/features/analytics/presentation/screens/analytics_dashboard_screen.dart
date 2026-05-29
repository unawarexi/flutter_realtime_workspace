import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/analytics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final role = ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';
    final dashAsync = ref.watch(analyticsDashboardProvider);

    if (!PermissionHelper.canAccessAnalytics(role)) {
      return Scaffold(
        backgroundColor: isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
        appBar: _appBar(context, isDark),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline_rounded, size: 48,
              color: isDark ? TColors.darkMuted : TColors.lightMuted),
            const SizedBox(height: TSizes.paddingMD),
            Text('Access Restricted', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight)),
            const SizedBox(height: TSizes.sm),
            Text('You need manager level or above\nto view analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12,
                color: isDark ? TColors.darkMuted : TColors.lightMuted)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: _appBar(context, isDark),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: TColors.error),
          const SizedBox(height: 12),
          Text('Failed to load analytics', style: TextStyle(
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(analyticsDashboardProvider),
            child: const Text('Retry'),
          ),
        ])),
        data: (data) => _buildDashboard(context, isDark, data),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
          color: isDark ? Colors.white : TColors.textPrimaryLight),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TColors.quickActionYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(TSizes.radiusSm),
          ),
          child: const Icon(Icons.analytics_rounded, color: TColors.quickActionYellow, size: 14),
        ),
        const SizedBox(width: 10),
        Text('Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : TColors.textPrimaryLight)),
      ]),
    );
  }

  Widget _buildDashboard(BuildContext context, bool isDark, Map<String, dynamic> data) {
    final projectCount = data['projectCount'] ?? data['totalProjects'] ?? 0;
    final taskCount = data['taskCount'] ?? data['totalTasks'] ?? 0;
    final completionRate = (data['completionRate'] ?? data['taskCompletionRate'] ?? 0.0).toDouble();
    final activeUsers = data['activeUsers'] ?? data['userCount'] ?? 0;
    final openIssues = data['openIssues'] ?? data['issueCount'] ?? 0;
    final avgCycleTime = data['avgCycleTime'] ?? data['averageCycleTime'] ?? '—';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview cards
                TWidgetAnimations.slideUp(
                  child: _buildOverviewGrid(isDark, projectCount, taskCount, completionRate, activeUsers),
                ),
                const SizedBox(height: TSizes.paddingLG),

                // Velocity section
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildSection(isDark, 'Project Velocity', Icons.speed_rounded, [
                    _buildMetricRow(isDark, 'Avg Cycle Time', '$avgCycleTime', TColors.quickActionBlue),
                    _buildMetricRow(isDark, 'Open Issues', '$openIssues', TColors.warning),
                    _buildMetricRow(isDark, 'Task Throughput', '${data['throughput'] ?? '—'}/week', TColors.success),
                  ]),
                ),
                const SizedBox(height: TSizes.paddingMD),

                // Activity heatmap placeholder
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _buildActivityHeatmap(isDark, data),
                ),
                const SizedBox(height: TSizes.paddingMD),

                // Team productivity
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: _buildSection(isDark, 'Team Productivity', Icons.groups_rounded, [
                    _buildMetricRow(isDark, 'Active Users', '$activeUsers', TColors.quickActionPurple),
                    _buildMetricRow(isDark, 'Tasks Created Today', '${data['tasksToday'] ?? 0}', TColors.quickActionGreen),
                    _buildMetricRow(isDark, 'Tasks Completed Today', '${data['tasksCompletedToday'] ?? 0}', TColors.quickActionBlue),
                  ]),
                ),
                const SizedBox(height: TSizes.paddingXL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(bool isDark, int projects, int tasks, double completion, int users) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: TSizes.sm,
      crossAxisSpacing: TSizes.sm,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(isDark, 'Projects', '$projects', Icons.folder_outlined, TColors.quickActionBlue),
        _buildStatCard(isDark, 'Tasks', '$tasks', Icons.task_alt_rounded, TColors.quickActionGreen),
        _buildStatCard(isDark, 'Completion', '${(completion * 100).toInt()}%', Icons.pie_chart_rounded, TColors.quickActionPurple),
        _buildStatCard(isDark, 'Active Users', '$users', Icons.people_outlined, TColors.quickActionYellow),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(TSizes.paddingSM + 2),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: isDark ? TColors.darkMuted : TColors.lightMuted)),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(TSizes.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: isDark ? TColors.blue400 : TColors.primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight)),
          ]),
          const SizedBox(height: TSizes.paddingSM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow(bool isDark, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 4, height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12,
          color: isDark ? TColors.textDarkSecondary : TColors.textSecondaryLight))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : TColors.textPrimaryLight)),
      ]),
    );
  }

  Widget _buildActivityHeatmap(bool isDark, Map<String, dynamic> data) {
    // Render a 7-day activity bar chart
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activity = (data['weeklyActivity'] as List?)
        ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
        .toList() ??
        [0.6, 0.8, 0.5, 0.9, 0.7, 0.3, 0.2];

    return Container(
      padding: const EdgeInsets.all(TSizes.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.local_fire_department_rounded, size: 16,
              color: isDark ? TColors.blue400 : TColors.primary),
            const SizedBox(width: 8),
            Text('Weekly Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight)),
          ]),
          const SizedBox(height: TSizes.paddingMD),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = i < activity.length ? activity[i] : 0.0;
                return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    width: 28,
                    height: (val * 60).clamp(4, 60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColors.quickActionBlue, TColors.quickActionPurple.withValues(alpha: 0.7)],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(weekDays[i], style: TextStyle(fontSize: 9,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
