import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/analytics_provider.dart';

class AIInsightsScreen extends ConsumerWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final dashAsync = ref.watch(analyticsDashboardProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'AI Insights', showBack: true),
      body: dashAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(hPad),
          child: const Column(children: [
            TSkeleton(height: 100),
            SizedBox(height: TSizes.md),
            Row(children: [
              Expanded(child: TSkeleton(height: 80)),
              SizedBox(width: TSizes.sm),
              Expanded(child: TSkeleton(height: 80)),
            ]),
            SizedBox(height: TSizes.md),
            TSkeleton(height: 160),
            SizedBox(height: TSizes.md),
            TSkeleton(height: 160),
          ]),
        ),
        error: (_, __) => const Center(child: Text('Failed to load AI insights')),
        data: (data) {
          final summary = data['summary'] as Map<String, dynamic>? ?? {};
          final insights = (data['insights'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final recommendations = (data['recommendations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final productivity = data['productivityScore'] as num? ?? 0;
          final sentiment = data['sentimentScore'] as num? ?? 0;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(analyticsDashboardProvider),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
              children: [
                // Score banner
                TCard(
                  hasBorder: false,
                  hasShadow: true,
                  padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
                  child: Row(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(TSizes.radiusLg),
                      ),
                      child: const Icon(Iconsax.cpu, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AI Summary', style: TextStyle(
                        fontSize: TResponsive.sp(context, 12),
                        color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                      )),
                      const SizedBox(height: 4),
                      Text(summary['headline'] as String? ?? 'Your team is performing well this week.', style: TextStyle(
                        fontSize: TResponsive.sp(context, 15),
                        fontWeight: FontWeight.w700,
                        color: isDark ? TColors.textDark : TColors.textLight,
                      )),
                    ])),
                  ]),
                ),
                const SizedBox(height: TSizes.md),

                // Score row
                Row(children: [
                  Expanded(child: _ScoreCard(
                    label: 'Productivity',
                    value: productivity.toDouble(),
                    color: TColors.success,
                    icon: Iconsax.trend_up,
                    isDark: isDark,
                  )),
                  const SizedBox(width: TSizes.sm),
                  Expanded(child: _ScoreCard(
                    label: 'Team Sentiment',
                    value: sentiment.toDouble(),
                    color: const Color(0xFF8B5CF6),
                    icon: Iconsax.emoji_happy,
                    isDark: isDark,
                  )),
                ]),
                const SizedBox(height: TSizes.md),

                // Key Insights
                if (insights.isNotEmpty) ...[
                  Text('Key Insights', style: TextStyle(
                    fontSize: TResponsive.sp(context, 16),
                    fontWeight: FontWeight.w700,
                    color: isDark ? TColors.textDark : TColors.textLight,
                  )),
                  const SizedBox(height: TSizes.sm),
                  ...insights.map((ins) => Padding(
                    padding: const EdgeInsets.only(bottom: TSizes.sm),
                    child: TCard(
                      hasBorder: true,
                      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _insightColor(ins['type'] as String? ?? '').withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_insightIcon(ins['type'] as String? ?? ''), size: 18, color: _insightColor(ins['type'] as String? ?? '')),
                        ),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ins['title'] as String? ?? '', style: TextStyle(
                            fontSize: TResponsive.sp(context, 13),
                            fontWeight: FontWeight.w600,
                            color: isDark ? TColors.textDark : TColors.textLight,
                          )),
                          const SizedBox(height: 4),
                          Text(ins['description'] as String? ?? '', style: TextStyle(
                            fontSize: TResponsive.sp(context, 12),
                            color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                          )),
                        ])),
                      ]),
                    ),
                  )),
                  const SizedBox(height: TSizes.md),
                ] else ...[
                  _PlaceholderInsights(isDark: isDark),
                  const SizedBox(height: TSizes.md),
                ],

                // Recommendations
                Text('Recommendations', style: TextStyle(
                  fontSize: TResponsive.sp(context, 16),
                  fontWeight: FontWeight.w700,
                  color: isDark ? TColors.textDark : TColors.textLight,
                )),
                const SizedBox(height: TSizes.sm),
                if (recommendations.isNotEmpty)
                  ...recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: TSizes.sm),
                    child: TCard(
                      hasBorder: true,
                      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                      child: Row(children: [
                        Icon(Iconsax.lamp_on, size: 20, color: TColors.warning),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: Text(r['text'] as String? ?? '', style: TextStyle(
                          fontSize: TResponsive.sp(context, 13),
                          color: isDark ? TColors.textDark : TColors.textLight,
                        ))),
                      ]),
                    ),
                  ))
                else
                  ..._defaultRecommendations(isDark, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _insightColor(String type) => switch (type) {
    'risk' => TColors.error,
    'opportunity' => TColors.success,
    'trend' => TColors.primary,
    _ => const Color(0xFF8B5CF6),
  };

  IconData _insightIcon(String type) => switch (type) {
    'risk' => Iconsax.warning_2,
    'opportunity' => Iconsax.trend_up,
    'trend' => Iconsax.chart,
    _ => Iconsax.info_circle,
  };

  List<Widget> _defaultRecommendations(bool isDark, BuildContext context) {
    const recs = [
      'Schedule a team sync to address overdue tasks.',
      'Consider breaking large tasks into smaller milestones.',
      'Celebrate recent completions to boost team morale.',
    ];
    return recs.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: TCard(
        hasBorder: true,
        padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
        child: Row(children: [
          Icon(Iconsax.lamp_on, size: 20, color: TColors.warning),
          const SizedBox(width: TSizes.sm),
          Expanded(child: Text(r, style: TextStyle(
            fontSize: TResponsive.sp(context, 13),
            color: isDark ? TColors.textDark : TColors.textLight,
          ))),
        ]),
      ),
    )).toList();
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isDark;
  const _ScoreCard({required this.label, required this.value, required this.color, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0, 100));
    return TCard(
      hasBorder: true,
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: TResponsive.sp(context, 12),
            color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
          )),
        ]),
        const SizedBox(height: 8),
        Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
          fontSize: TResponsive.sp(context, 24),
          fontWeight: FontWeight.w800,
          color: color,
        )),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }
}

class _PlaceholderInsights extends StatelessWidget {
  final bool isDark;
  const _PlaceholderInsights({required this.isDark});

  static const _items = [
    ('Task completion rate improved by 12%', 'opportunity'),
    ('3 high-priority issues require attention', 'risk'),
    ('Team velocity trending upward this sprint', 'trend'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: _items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: TCard(
        hasBorder: true,
        padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _color(item.$2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(item.$2), size: 18, color: _color(item.$2)),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(child: Text(item.$1, style: TextStyle(
            fontSize: TResponsive.sp(context, 13),
            fontWeight: FontWeight.w500,
            color: isDark ? TColors.textDark : TColors.textLight,
          ))),
        ]),
      ),
    )).toList());
  }

  Color _color(String t) => switch (t) {
    'risk' => TColors.error,
    'opportunity' => TColors.success,
    _ => TColors.primary,
  };
  IconData _icon(String t) => switch (t) {
    'risk' => Iconsax.warning_2,
    'opportunity' => Iconsax.trend_up,
    _ => Iconsax.chart,
  };
}
