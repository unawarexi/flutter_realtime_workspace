import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/audit_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

class AdminLogsScreen extends ConsumerStatefulWidget {
  const AdminLogsScreen({super.key});
  @override
  ConsumerState<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends ConsumerState<AdminLogsScreen> {
  String _query = '';
  String _category = 'all';

  static const _categories = ['all', 'auth', 'iam', 'data', 'admin', 'ai', 'billing', 'system'];

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final workspaceId = ref.watch(activeWorkspaceProvider)?.id;

    final logsAsync = ref.watch(auditLogsProvider({
      'workspaceId': workspaceId,
      'orgId': null,
      'actorId': null,
      'resourceType': null,
      'action': _category == 'all' ? null : _category,
      'from': null,
      'to': null,
    }));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'System Logs', showBack: true),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xs),
          child: TSearchBar(hint: 'Search logs...', onChanged: (v) => setState(() => _query = v)),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? TColors.primary : (isDark ? TColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(TSizes.radiusFull),
                    border: Border.all(color: active ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                  ),
                  child: Text(cat, style: TextStyle(
                    fontSize: TResponsive.sp(context, 12),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Colors.white : (isDark ? TColors.textDark : TColors.textLight),
                  )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: TSizes.sm),
        Expanded(
          child: logsAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(children: List.generate(6, (_) => const Padding(
                padding: EdgeInsets.only(bottom: TSizes.sm),
                child: TSkeleton(height: 72),
              ))),
            ),
            error: (_, __) => const Center(child: Text('Failed to load logs')),
            data: (logs) {
              final filtered = _query.isEmpty
                  ? logs
                  : logs.where((l) =>
                      l.action.toLowerCase().contains(_query.toLowerCase()) ||
                      (l.actor.email ?? '').toLowerCase().contains(_query.toLowerCase()) ||
                      (l.target?.type ?? '').toLowerCase().contains(_query.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.document_text, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(height: TSizes.sm),
                  Text('No logs found', style: TextStyle(color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary)),
                ]));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(auditLogsProvider({
                  'workspaceId': workspaceId, 'orgId': null, 'actorId': null,
                  'resourceType': null, 'action': _category == 'all' ? null : _category,
                  'from': null, 'to': null,
                })),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: TSizes.xs),
                  itemBuilder: (_, i) {
                    final log = filtered[i];
                    final isSuccess = log.status == 'success';
                    return TCard(
                      hasBorder: true,
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: (isSuccess ? TColors.success : TColors.error).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSuccess ? Iconsax.shield_tick : Iconsax.shield_cross,
                            size: 16,
                            color: isSuccess ? TColors.success : TColors.error,
                          ),
                        ),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(
                              log.action,
                              style: TextStyle(
                                fontSize: TResponsive.sp(context, 13),
                                fontWeight: FontWeight.w600,
                                color: isDark ? TColors.textDark : TColors.textLight,
                              ),
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _categoryColor(log.category).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(TSizes.radiusFull),
                              ),
                              child: Text(log.category, style: TextStyle(
                                fontSize: TResponsive.sp(context, 10),
                                fontWeight: FontWeight.w600,
                                color: _categoryColor(log.category),
                              )),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            log.actor.email ?? '',

                            style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary),
                          ),
                          if (log.target != null) Text(
                            '${log.target!.type} ${log.target!.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: TResponsive.sp(context, 11), color: isDark ? TColors.darkMuted : TColors.lightMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(log.createdAt),
                            style: TextStyle(fontSize: TResponsive.sp(context, 11), color: isDark ? TColors.darkMuted : TColors.lightMuted),
                          ),
                        ])),
                      ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Color _categoryColor(String cat) => switch (cat) {
    'auth' => TColors.primary,
    'iam' => TColors.warning,
    'data' => TColors.info,
    'admin' => TColors.error,
    'ai' => const Color(0xFF8B5CF6),
    'billing' => TColors.success,
    _ => TColors.neutralGray,
  };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
