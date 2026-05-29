import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/admin_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';
  String _roleFilter = 'all';

  static const _roles = ['all', 'super_admin', 'admin', 'manager', 'employee', 'member', 'guest'];

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final usersAsync = ref.watch(allUsersProvider);
    final canImpersonate = AdminUseCase.canImpersonate(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Manage Users', showBack: true),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xs),
          child: TSearchBar(hint: 'Search by name or email...', onChanged: (v) => setState(() => _query = v)),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _roles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final role = _roles[i];
              final active = _roleFilter == role;
              return GestureDetector(
                onTap: () => setState(() => _roleFilter = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? TColors.primary : (isDark ? TColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(TSizes.radiusFull),
                    border: Border.all(color: active ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                  ),
                  child: Text(role, style: TextStyle(
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
          child: usersAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(children: List.generate(6, (_) => const Padding(
                padding: EdgeInsets.only(bottom: TSizes.sm),
                child: TSkeleton(height: 72),
              ))),
            ),
            error: (_, __) => const Center(child: Text('Failed to load users')),
            data: (users) {
              var filtered = users.where((u) {
                final q = _query.toLowerCase();
                final matchQuery = q.isEmpty || u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
                final matchRole = _roleFilter == 'all' || u.permissionsLevel == _roleFilter;
                return matchQuery && matchRole;
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.people, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(height: TSizes.sm),
                  Text('No users found', style: TextStyle(color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary)),
                ]));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allUsersProvider),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: TSizes.xs),
                  itemBuilder: (_, i) {
                    final u = filtered[i];
                    return TCard(
                      hasBorder: true,
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: TColors.primary.withValues(alpha: 0.15),
                          backgroundImage: u.profilePicture != null ? NetworkImage(u.profilePicture!) : null,
                          child: u.profilePicture == null
                              ? Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.fullName, style: TextStyle(
                            fontSize: TResponsive.sp(context, 14),
                            fontWeight: FontWeight.w600,
                            color: isDark ? TColors.textDark : TColors.textLight,
                          )),
                          Text(u.email, style: TextStyle(
                            fontSize: TResponsive.sp(context, 12),
                            color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                          )),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          _RoleBadge(role: u.permissionsLevel),
                          const SizedBox(height: 4),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: u.isOnline ? TColors.success : (isDark ? TColors.darkMuted : TColors.lightMuted),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(u.isOnline ? 'Online' : 'Offline', style: TextStyle(
                              fontSize: TResponsive.sp(context, 11),
                              color: u.isOnline ? TColors.success : (isDark ? TColors.darkMuted : TColors.lightMuted),
                            )),
                          ]),
                        ]),
                        if (canImpersonate) ...[
                          const SizedBox(width: TSizes.sm),
                          IconButton(
                            onPressed: () => _showUserActions(context, ref, u.id, u.fullName),
                            icon: const Icon(Iconsax.more, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
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

  void _showUserActions(BuildContext context, WidgetRef ref, String userId, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Actions for $name', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: TSizes.md),
          ListTile(
            leading: const Icon(Iconsax.user_octagon, color: TColors.warning),
            title: const Text('Impersonate User'),
            onTap: () {
              Navigator.pop(context);
              AdminUseCase.impersonate(context: context, ref: ref, userId: userId);
            },
          ),
        ]),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color => switch (role) {
    'super_admin' => TColors.error,
    'admin' => TColors.warning,
    'manager' => TColors.primary,
    'employee' || 'member' => TColors.success,
    _ => TColors.neutralGray,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TSizes.radiusFull),
      ),
      child: Text(role.replaceAll('_', ' '), style: TextStyle(
        fontSize: TResponsive.sp(context, 10),
        fontWeight: FontWeight.w600,
        color: _color,
      )),
    );
  }
}
