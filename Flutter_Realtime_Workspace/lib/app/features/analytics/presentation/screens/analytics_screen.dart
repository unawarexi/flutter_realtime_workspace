import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _period = '7d';

  static const _periods = [
    ('Today', '1d'), ('7 Days', '7d'), ('30 Days', '30d'), ('Quarter', '90d'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final reportAsync = ref.watch(analyticsReportProvider({'period': _period}));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Analytics', showBack: true),
      body: Column(children: [
        // Period selector
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.md),
          child: Row(children: _periods.map((p) {
            final active = _period == p.$2;
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: p.$2 != '90d' ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _period = p.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? TColors.primary : (isDark ? TColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(TSizes.radiusMd),
                    border: Border.all(color: active ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                  ),
                  child: Text(p.$1, textAlign: TextAlign.center, style: TextStyle(
                    fontSize: TResponsive.sp(context, 12),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? Colors.white : (isDark ? TColors.textDark : TColors.textLight),
                  )),
                ),
              ),
            ));
          }).toList()),
        ),

        Expanded(
          child: reportAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(children: [
                Row(children: const [
                  Expanded(child: TSkeleton(height: 90)),
                  SizedBox(width: TSizes.sm),
                  Expanded(child: TSkeleton(height: 90)),
                  SizedBox(width: TSizes.sm),
                  Expanded(child: TSkeleton(height: 90)),
                ]),
                const SizedBox(height: TSizes.md),
                const TSkeleton(height: 200),
                const SizedBox(height: TSizes.md),
                const TSkeleton(height: 200),
              ]),
            ),
            error: (_, __) => const Center(child: Text('Failed to load analytics')),
            data: (report) {
              final tasks = report['tasks'] as Map<String, dynamic>? ?? {};
              final issues = report['issues'] as Map<String, dynamic>? ?? {};
              final members = report['members'] as Map<String, dynamic>? ?? {};
              final topUsers = (report['topUsers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final recentActivity = (report['recentActivity'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(analyticsReportProvider({'period': _period})),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
                  children: [
                    // Summary stats
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _StatCard(
                        label: 'Tasks',
                        value: '${tasks['total'] ?? 0}',
                        sub: '${tasks['completed'] ?? 0} done',
                        icon: Iconsax.task,
                        color: TColors.primary,
                        isDark: isDark,
                      )),
                      const SizedBox(width: TSizes.sm),
                      Expanded(child: _StatCard(
                        label: 'Issues',
                        value: '${issues['total'] ?? 0}',
                        sub: '${issues['open'] ?? 0} open',
                        icon: Iconsax.warning_2,
                        color: TColors.warning,
                        isDark: isDark,
                      )),
                      const SizedBox(width: TSizes.sm),
                      Expanded(child: _StatCard(
                        label: 'Members',
                        value: '${members['active'] ?? 0}',
                        sub: 'active',
                        icon: Iconsax.people,
                        color: TColors.success,
                        isDark: isDark,
                      )),
                    ]),
                    const SizedBox(height: TSizes.md),

                    // Task Completion breakdown
                    TCard(
                      hasBorder: true,
                      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Task Completion', style: TextStyle(
                            fontSize: TResponsive.sp(context, 15),
                            fontWeight: FontWeight.w700,
                            color: isDark ? TColors.textDark : TColors.textLight,
                          )),
                          Text('${_pct(tasks['completed'], tasks['total'])}%', style: TextStyle(
                            fontSize: TResponsive.sp(context, 14),
                            fontWeight: FontWeight.w700,
                            color: TColors.primary,
                          )),
                        ]),
                        const SizedBox(height: TSizes.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _pct(tasks['completed'], tasks['total']) / 100,
                            backgroundColor: TColors.primary.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(TColors.primary),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: TSizes.md),
                        _TaskBreakdownRow(tasks: tasks, isDark: isDark),
                      ]),
                    ),
                    const SizedBox(height: TSizes.md),

                    // Top Performers
                    if (topUsers.isNotEmpty) ...[
                      Text('Top Performers', style: TextStyle(
                        fontSize: TResponsive.sp(context, 16),
                        fontWeight: FontWeight.w700,
                        color: isDark ? TColors.textDark : TColors.textLight,
                      )),
                      const SizedBox(height: TSizes.sm),
                      TCard(
                        hasBorder: true,
                        padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                        child: Column(
                          children: topUsers.take(5).toList().asMap().entries.map((e) => _PerformerRow(
                            rank: e.key + 1,
                            data: e.value,
                            isDark: isDark,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: TSizes.md),
                    ],

                    // Recent Activity
                    if (recentActivity.isNotEmpty) ...[
                      Text('Recent Activity', style: TextStyle(
                        fontSize: TResponsive.sp(context, 16),
                        fontWeight: FontWeight.w700,
                        color: isDark ? TColors.textDark : TColors.textLight,
                      )),
                      const SizedBox(height: TSizes.sm),
                      ...recentActivity.take(8).map((act) => Padding(
                        padding: const EdgeInsets.only(bottom: TSizes.xs),
                        child: TCard(
                          hasBorder: true,
                          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                          child: Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: TColors.primary.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(width: TSizes.sm),
                            Expanded(child: Text(act['description'] as String? ?? '', style: TextStyle(
                              fontSize: TResponsive.sp(context, 13),
                              color: isDark ? TColors.textDark : TColors.textLight,
                            ))),
                            Text(act['time'] as String? ?? '', style: TextStyle(
                              fontSize: TResponsive.sp(context, 11),
                              color: isDark ? TColors.darkMuted : TColors.lightMuted,
                            )),
                          ]),
                        ),
                      )),
                    ],

                    // Export button
                    const SizedBox(height: TSizes.md),
                    TButton(
                      text: 'Export Report',
                      prefixIcon: Iconsax.export,
                      variant: SButtonVariant.outline,
                      onPressed: () {},
                    ),
                    const SizedBox(height: TSizes.lg),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  double _pct(dynamic done, dynamic total) {
    final d = (done as num?)?.toDouble() ?? 0;
    final t = (total as num?)?.toDouble() ?? 0;
    if (t == 0) return 0;
    return ((d / t) * 100).clamp(0, 100);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.sub, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TCard(
      hasBorder: true,
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
          fontSize: TResponsive.sp(context, 20),
          fontWeight: FontWeight.w800,
          color: isDark ? TColors.textDark : TColors.textLight,
        )),
        Text(sub, style: TextStyle(
          fontSize: TResponsive.sp(context, 11),
          color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: TResponsive.sp(context, 11),
          color: isDark ? TColors.darkMuted : TColors.lightMuted,
        )),
      ]),
    );
  }
}

class _TaskBreakdownRow extends StatelessWidget {
  final Map<String, dynamic> tasks;
  final bool isDark;
  const _TaskBreakdownRow({required this.tasks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('To Do', tasks['todo'], TColors.neutralGray),
      ('In Progress', tasks['inProgress'], TColors.primary),
      ('Done', tasks['completed'], TColors.success),
      ('Blocked', tasks['blocked'], TColors.error),
    ];
    return Row(children: statuses.map((s) => Expanded(child: Column(children: [
      Text('${s.$2 ?? 0}', style: TextStyle(
        fontSize: TResponsive.sp(context, 16),
        fontWeight: FontWeight.w700,
        color: s.$3,
      )),
      Text(s.$1, style: TextStyle(
        fontSize: TResponsive.sp(context, 10),
        color: isDark ? TColors.darkMuted : TColors.lightMuted,
      )),
    ]))).toList());
  }
}

class _PerformerRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final bool isDark;
  const _PerformerRow({required this.rank, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(children: [
        SizedBox(
          width: 22,
          child: Text('$rank', style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: TResponsive.sp(context, 13),
            color: rank <= 3 ? TColors.warning : (isDark ? TColors.darkMuted : TColors.lightMuted),
          )),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 16,
          backgroundColor: TColors.primary.withValues(alpha: 0.15),
          child: Text((data['name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(color: TColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(data['name'] as String? ?? '', style: TextStyle(
          fontSize: TResponsive.sp(context, 13),
          fontWeight: FontWeight.w500,
          color: isDark ? TColors.textDark : TColors.textLight,
        ))),
        Text('${data['tasksCompleted'] ?? 0} tasks', style: TextStyle(
          fontSize: TResponsive.sp(context, 12),
          fontWeight: FontWeight.w600,
          color: TColors.success,
        )),
      ]),
    );
  }
}
