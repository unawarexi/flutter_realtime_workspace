import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/tickets/usecases/ticket_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/ticket_provider.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final ticketId = GoRouterState.of(context).pathParameters['ticketId'];
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Ticket Detail', showBack: true),
      body: ticketsAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 60))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (tickets) {
          final ticket = tickets.where((t) => t.id == ticketId).firstOrNull;
          if (ticket == null) return const Center(child: Text('Ticket not found'));

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
            children: [
              // Title + number
              if (ticket.ticketNumber != null)
                Text('#${ticket.ticketNumber}', style: TextStyle(fontSize: TResponsive.sp(context, 12), fontWeight: FontWeight.w600, color: TColors.primary)),
              const SizedBox(height: 4),
              Text(ticket.title, style: TextStyle(fontSize: TResponsive.sp(context, 20), fontWeight: FontWeight.w700, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
              const SizedBox(height: TSizes.md),

              // Status + Priority
              Row(
                children: [
                  _badge(TicketUseCase.statusLabel(ticket.status), _statusColor(ticket.status)),
                  const SizedBox(width: 8),
                  _badge(TicketUseCase.priorityLabel(ticket.priority), _priorityColor(ticket.priority)),
                ],
              ),
              const SizedBox(height: TSizes.lg),

              // Description
              if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                _sectionLabel(context, 'DESCRIPTION', isDark),
                const SizedBox(height: TSizes.sm),
                TCard(
                  hasBorder: true,
                  child: Text(ticket.description!, style: TextStyle(fontSize: TResponsive.sp(context, 14), height: 1.5, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                ),
                const SizedBox(height: TSizes.lg),
              ],

              // Meta info
              _sectionLabel(context, 'DETAILS', isDark),
              const SizedBox(height: TSizes.sm),
              TCard(
                hasBorder: true,
                child: Column(
                  children: [
                    _row(context, 'Created', _formatDate(ticket.createdAt), isDark),
                    Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
                    _row(context, 'Status', TicketUseCase.statusLabel(ticket.status), isDark),
                    Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
                    _row(context, 'Priority', TicketUseCase.priorityLabel(ticket.priority), isDark),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _sectionLabel(BuildContext context, String label, bool isDark) => Text(label,
      style: TextStyle(fontSize: TResponsive.sp(context, 11), fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight));

  Widget _row(BuildContext context, String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: TResponsive.sp(context, 13), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
      Text(value, style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
    ]),
  );

  String _formatDate(DateTime? d) => d != null ? '${d.day}/${d.month}/${d.year}' : '–';
  Color _statusColor(String s) => switch (s) { 'open' => TColors.info, 'in_progress' => TColors.warning, 'resolved' => TColors.success, 'closed' => TColors.neutralGray, _ => TColors.neutralGray };
  Color _priorityColor(String p) => switch (p) { 'critical' => TColors.error, 'high' => TColors.warning, 'medium' => TColors.info, _ => TColors.neutralGray };
}
