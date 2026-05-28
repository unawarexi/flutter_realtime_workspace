import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/organizations/usecases/organization_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/organization_provider.dart';

class OrgMembersScreen extends ConsumerStatefulWidget {
  const OrgMembersScreen({super.key});
  @override
  ConsumerState<OrgMembersScreen> createState() => _State();
}

class _State extends ConsumerState<OrgMembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final orgAsync = ref.watch(activeOrganizationProvider);
    final canManage = OrganizationUseCase.canManageMembers(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Members', showBack: true),
      body: orgAsync.when(
        loading: () => _skeleton(hPad),
        error: (_, __) => const Center(child: Text('Unable to load')),
        data: (org) {
          if (org == null) return const Center(child: Text('No organization'));
          final membersAsync = ref.watch(orgMembersProvider(org.id));
          return membersAsync.when(
            loading: () => _skeleton(hPad),
            error: (_, __) => const Center(child: Text('Unable to load members')),
            data: (members) {
              final filtered = _query.isEmpty
                  ? members
                  : members.where((m) =>
                      (m['name'] ?? '').toString().toLowerCase().contains(_query.toLowerCase()) ||
                      (m['email'] ?? '').toString().toLowerCase().contains(_query.toLowerCase())).toList();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(orgMembersProvider(org.id)),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
                  itemCount: filtered.length + 2,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: TSizes.md),
                        child: TSearchBar(hint: 'Search members...', onChanged: (q) => setState(() => _query = q)),
                      );
                    }
                    if (i == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: TSizes.sm),
                        child: Text('${filtered.length} member${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                      );
                    }
                    final m = filtered[i - 2];
                    final role = m['role'] ?? 'member';
                    final name = m['name'] ?? m['email'] ?? 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: TSizes.xs),
                      child: TCard(
                        hasBorder: true,
                        padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 2),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                              child: Text(name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, color: _roleColor(role))),
                            ),
                            const SizedBox(width: TSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                  if (m['email'] != null)
                                    Text(m['email'], style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                              child: Text(role.replaceAll('_', ' '), style: TextStyle(fontSize: TResponsive.sp(context, 10), fontWeight: FontWeight.w600, color: _roleColor(role))),
                            ),
                            if (canManage) ...[
                              const SizedBox(width: TSizes.xs),
                              IconButton(
                                onPressed: () => OrganizationUseCase.removeMember(context: context, ref: ref, orgId: org.id, userId: m['userId'] ?? ''),
                                icon: Icon(Icons.remove_circle_outline, size: 18, color: TColors.error.withValues(alpha: 0.7)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _skeleton(double pad) => Padding(
    padding: EdgeInsets.all(pad),
    child: Column(children: List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 64)))),
  );

  Color _roleColor(String role) => switch (role) {
    'owner' => TColors.quickActionPurple,
    'admin' => TColors.quickActionBlue,
    'manager' => TColors.quickActionGreen,
    'member' => TColors.primary,
    _ => TColors.neutralGray,
  };
}
