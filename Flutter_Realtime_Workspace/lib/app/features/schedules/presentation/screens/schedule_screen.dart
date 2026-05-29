import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/schedule_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});
  @override
  ConsumerState<ScheduleScreen> createState() => _State();
}

class _State extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final scheduleAsync = ref.watch(schedulesProvider({'workspaceId': null, 'from': null, 'to': null}));
    final canCreate = ScheduleUseCase.canCreateSchedule(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Schedule',
        showBack: true,
        actions: [if (canCreate) IconButton(onPressed: () => context.go('/schedule/create'), icon: const Icon(Icons.add_rounded))],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: TColors.primary,
          labelColor: TColors.primary,
          unselectedLabelColor: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
          labelStyle: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: scheduleAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 72))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (schedules) {
          final upcoming = ScheduleUseCase.filterUpcoming(schedules);
          final past = ScheduleUseCase.filterPast(schedules);

          return TabBarView(controller: _tabCtrl, children: [
            _buildList(context, upcoming, isDark, hPad, 'No upcoming events'),
            _buildList(context, past, isDark, hPad, 'No past events'),
          ]);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List items, bool isDark, double hPad, String emptyText) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_outlined, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
        const SizedBox(height: TSizes.sm),
        Text(emptyText, style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(schedulesProvider({'workspaceId': null, 'from': null, 'to': null})),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
        itemBuilder: (_, i) {
          final s = items[i];
          final isUpcoming = s.startTime.isAfter(DateTime.now());
          return TCard(
            hasBorder: true,
            padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: (isUpcoming ? TColors.primary : TColors.neutralGray).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(TSizes.radiusMd),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${s.startTime.day}', style: TextStyle(fontSize: TResponsive.sp(context, 16), fontWeight: FontWeight.w700, color: isUpcoming ? TColors.primary : TColors.neutralGray)),
                  Text(_monthAbbr(s.startTime.month), style: TextStyle(fontSize: TResponsive.sp(context, 10), color: isUpcoming ? TColors.primary : TColors.neutralGray)),
                ]),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                const SizedBox(height: 2),
                Text('${_formatTime(s.startTime)}', style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
              ])),
              Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? TColors.darkMuted : TColors.lightMuted),
            ]),
          );
        },
      ),
    );
  }

  String _monthAbbr(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
