import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:intl/intl.dart';

class HomeUpcomingSchedule extends StatelessWidget {
  const HomeUpcomingSchedule({
    super.key,
    required this.isDark,
    required this.schedules, // Expecting list of schedule maps
    required this.isLoading,
  });

  final bool isDark;
  final List<dynamic> schedules;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 540),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/schedule'), // Navigate to schedule
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? TColors.blue400 : TColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm, vertical: TSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          SizedBox(
            height: 90,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: TSizes.sm),
                      child: TSkeleton(width: 200, height: 90),
                    ),
                  )
                : schedules.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: TCard(
                          hasBorder: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: TSizes.md, horizontal: TSizes.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                                size: TSizes.iconMd,
                              ),
                              const SizedBox(width: TSizes.sm),
                              Text(
                                'No upcoming meetings',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? TColors.darkMuted
                                      : TColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: index == schedules.length - 1
                                    ? 0
                                    : TSizes.sm),
                            child: TWidgetAnimations.fadeIn(
                              delay: Duration(milliseconds: 50 * index),
                              child: _ScheduleCard(
                                  schedule: schedule, isDark: isDark),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.isDark});
  final dynamic schedule; // Map representing a schedule item
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = schedule['title'] ?? 'Untitled Event';
    final startTimeStr = schedule['startTime'];
    DateTime? startTime =
        startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;

    final timeFormatted =
        startTime != null ? DateFormat('h:mm a').format(startTime) : 'Time TBA';
    final dateFormatted =
        startTime != null ? DateFormat('MMM d').format(startTime) : '';

    final type = schedule['type'] ?? 'meeting';
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'video_call':
        icon = Icons.videocam_outlined;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'event':
        icon = Icons.celebration_outlined;
        iconColor = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.people_outline;
        iconColor = const Color(0xFF3B82F6);
    }

    return SizedBox(
      width: 200,
      child: TCard(
        hasBorder: true,
        hasShadow: true,
        padding: const EdgeInsets.all(TSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: iconColor, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : TColors.cardColorDark,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 12,
                    color: isDark ? Colors.white60 : TColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(
                  '$dateFormatted • $timeFormatted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : TColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
