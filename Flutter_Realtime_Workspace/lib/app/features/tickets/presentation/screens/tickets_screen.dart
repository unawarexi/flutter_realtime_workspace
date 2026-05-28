import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/tickets/usecases/ticket_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/ticket_provider.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});
  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _query = '';

  static const _tabs = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final ticketsAsync = ref.watch(ticketsProvider);
    final canCreate = TicketUseCase.canCreateTicket(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Tickets',
        showBack: true,
        actions: [
          if (canCreate)
            IconButton(onPressed: () => context.go('/tickets/create'), icon: const Icon(Icons.add_rounded)),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: TColors.primary,
          labelColor: TColors.primary,
          unselectedLabelColor: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
          labelStyle: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm),
            child: TSearchBar(hint: 'Search tickets...', onChanged: (q) => setState(() => _query = q)),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.all(hPad),
                child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 80)))),
              ),
              error: (_, __) => const Center(child: Text('Failed to load tickets')),
              data: (tickets) {
                return TabBarView(
                  controller: _tabCtrl,
                  children: _tabs.map((tab) {
                    var list = TicketUseCase.searchTickets(tickets, _query);
                    if (tab != 'All') {
                      final statusKey = tab.toLowerCase().replaceAll(' ', '_');
                      list = list.where((t) => t.status == statusKey).toList();
                    }
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.confirmation_number_outlined, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                            const SizedBox(height: TSizes.sm),
                            Text('No tickets', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(ticketsProvider),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.sm),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
                        itemBuilder: (_, i) {
                          final t = list[i];
                          return TCard(
                            hasBorder: true,
                            onTap: () => context.go('/tickets/${t.id}'),
                            padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (t.ticketNumber != null)
                                      Text('#${t.ticketNumber}  ', style: TextStyle(fontSize: TResponsive.sp(context, 11), fontWeight: FontWeight.w600, color: TColors.primary)),
                                    Expanded(
                                      child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _badge(TicketUseCase.statusLabel(t.status), _statusColor(t.status)),
                                    const SizedBox(width: 6),
                                    _badge(TicketUseCase.priorityLabel(t.priority), _priorityColor(t.priority)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
    child: Text(label, style: TextStyle(fontSize: TResponsive.sp(context, 10), fontWeight: FontWeight.w600, color: color)),
  );

  Color _statusColor(String s) => switch (s) { 'open' => TColors.info, 'in_progress' => TColors.warning, 'resolved' => TColors.success, 'closed' => TColors.neutralGray, 'escalated' => TColors.error, _ => TColors.neutralGray };
  Color _priorityColor(String p) => switch (p) { 'critical' => TColors.error, 'high' => TColors.warning, 'medium' => TColors.info, _ => TColors.neutralGray };
}
