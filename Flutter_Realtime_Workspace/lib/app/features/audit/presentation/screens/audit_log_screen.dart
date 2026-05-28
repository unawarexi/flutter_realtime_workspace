import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/audit/usecases/audit_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/audit_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _State();
}

class _State extends ConsumerState<AuditLogScreen> {
  String _query = '';
  String? _actionFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    if (!AuditUseCase.canViewAuditLogs(ref)) {
      return Scaffold(
        appBar: const SAppBar(title: 'Audit Log', showBack: true),
        body: Center(child: Text('Access denied', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight))),
      );
    }

    final logsAsync = ref.watch(auditLogsProvider({}));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Audit Log', showBack: true),
      body: logsAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(6, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 56))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (logs) {
          var filtered = AuditUseCase.searchLogs(logs, _query);
          if (_actionFilter != null) filtered = AuditUseCase.filterByAction(filtered, _actionFilter!);

          return Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm),
              child: TSearchBar(hint: 'Search logs...', onChanged: (q) => setState(() => _query = q)),
            ),
            // Filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                children: [null, 'create', 'update', 'delete', 'login', 'logout'].map((a) {
                  final selected = a == _actionFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(a == null ? 'All' : AuditUseCase.actionLabel(a)),
                      selected: selected,
                      onSelected: (_) => setState(() => _actionFilter = selected ? null : a),
                      selectedColor: TColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(fontSize: TResponsive.sp(context, 11), color: selected ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                      side: BorderSide(color: selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No logs', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(auditLogsProvider({})),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: TSizes.xs),
                        itemBuilder: (_, i) {
                          final log = filtered[i];
                          return TCard(
                            hasBorder: true,
                            padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                            child: Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: _actionColor(log.action).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Icon(_actionIcon(log.action), size: 16, color: _actionColor(log.action)),
                              ),
                              const SizedBox(width: TSizes.sm),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(AuditUseCase.actionLabel(log.action), style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                Text(log.target?.name ?? log.target?.type ?? '–', style: TextStyle(fontSize: TResponsive.sp(context, 11), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                              ])),
                              Text('${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: TResponsive.sp(context, 10), color: isDark ? TColors.textTertiaryDark : TColors.textTertiaryLight)),
                            ]),
                          );
                        },
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Color _actionColor(String a) => switch (a) { 'create' => TColors.success, 'update' => TColors.info, 'delete' => TColors.error, 'login' => TColors.quickActionGreen, 'logout' => TColors.warning, _ => TColors.neutralGray };
  IconData _actionIcon(String a) => switch (a) { 'create' => Icons.add_rounded, 'update' => Icons.edit_outlined, 'delete' => Icons.delete_outline, 'login' => Icons.login_rounded, 'logout' => Icons.logout_rounded, _ => Icons.history_rounded };
}
