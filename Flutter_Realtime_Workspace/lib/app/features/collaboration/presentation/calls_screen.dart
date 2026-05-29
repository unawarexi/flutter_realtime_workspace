import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/meeting_provider.dart';

class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});
  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);

    final upcomingAsync = ref.watch(meetingsProvider('scheduled'));
    final liveAsync = ref.watch(meetingsProvider('live'));
    final endedAsync = ref.watch(meetingsProvider('ended'));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Calls & Meetings',
        showBack: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: TColors.primary,
          unselectedLabelColor: isDark ? TColors.darkMuted : TColors.lightMuted,
          indicatorColor: TColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Live'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MeetingsList(asyncValue: upcomingAsync, isDark: isDark, hPad: hPad, emptyLabel: 'No upcoming meetings', emptyIcon: Iconsax.calendar_1),
          _MeetingsList(asyncValue: liveAsync, isDark: isDark, hPad: hPad, emptyLabel: 'No live meetings', emptyIcon: Iconsax.video, highlight: true),
          _MeetingsList(asyncValue: endedAsync, isDark: isDark, hPad: hPad, emptyLabel: 'No past meetings', emptyIcon: Iconsax.clock),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/meetings/new'),
        backgroundColor: TColors.primary,
        icon: const Icon(Iconsax.video_add, color: Colors.white),
        label: const Text('New Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MeetingsList extends ConsumerWidget {
  final AsyncValue<dynamic> asyncValue;
  final bool isDark;
  final double hPad;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool highlight;

  const _MeetingsList({
    required this.asyncValue,
    required this.isDark,
    required this.hPad,
    required this.emptyLabel,
    required this.emptyIcon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => Padding(
        padding: EdgeInsets.all(hPad),
        child: Column(children: List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: TSizes.sm),
          child: TSkeleton(height: 80),
        ))),
      ),
      error: (_, __) => const Center(child: Text('Failed to load')),
      data: (meetings) {
        final list = meetings as List;
        if (list.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(emptyIcon, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
            const SizedBox(height: TSizes.sm),
            Text(emptyLabel, style: TextStyle(color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary)),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
            itemBuilder: (_, i) {
              final m = list[i];
              final isLive = m.status.name == 'live';
              return TCard(
                hasBorder: true,
                hasShadow: isLive,
                padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: (isLive ? TColors.error : TColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(TSizes.radiusMd),
                    ),
                    child: Icon(isLive ? Iconsax.video : Iconsax.calendar_1, size: 22, color: isLive ? TColors.error : TColors.primary),
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: TResponsive.sp(context, 14),
                        fontWeight: FontWeight.w600,
                        color: isDark ? TColors.textDark : TColors.textLight,
                      ))),
                      if (isLive) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: TColors.error, borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                          const SizedBox(width: 4),
                          const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Iconsax.people, size: 12, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                      const SizedBox(width: 4),
                      Text('${m.participantCount} participants', style: TextStyle(
                        fontSize: TResponsive.sp(context, 12),
                        color: isDark ? TColors.darkMuted : TColors.lightMuted,
                      )),
                      if (m.scheduledAt != null) ...[
                        const SizedBox(width: 12),
                        Icon(Iconsax.clock, size: 12, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                        const SizedBox(width: 4),
                        Text(_formatTime(m.scheduledAt!), style: TextStyle(
                          fontSize: TResponsive.sp(context, 12),
                          color: isDark ? TColors.darkMuted : TColors.lightMuted,
                        )),
                      ],
                    ]),
                  ])),
                  if (isLive) TButton(
                    text: 'Join',
                    variant: SButtonVariant.outline,
                    onPressed: () => context.go('/meeting/${m.id}'),
                  ),
                ]),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$min';
  }
}
