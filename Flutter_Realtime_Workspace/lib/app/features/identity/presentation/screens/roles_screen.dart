import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/models/role_model.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/role_provider.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Roles & Permissions',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () => _showCreateRoleSheet(context, ref, isDark),
          ),
        ],
      ),
      body: rolesAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(children: List.generate(4, (_) => const Padding(
            padding: EdgeInsets.only(bottom: TSizes.md),
            child: TSkeleton(height: 88),
          ))),
        ),
        error: (_, __) => const Center(child: Text('Failed to load roles')),
        data: (roles) {
          if (roles.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Iconsax.shield, size: 56, color: isDark ? TColors.darkMuted : TColors.lightMuted),
              const SizedBox(height: TSizes.md),
              Text('No roles defined', style: TextStyle(
                fontSize: TResponsive.sp(context, 16),
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.textDark : TColors.textLight,
              )),
              const SizedBox(height: 6),
              Text('Create custom roles to manage permissions.', style: TextStyle(
                fontSize: TResponsive.sp(context, 14),
                color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
              )),
              const SizedBox(height: TSizes.lg),
              TButton(text: 'Create Role', prefixIcon: Iconsax.add, onPressed: () => _showCreateRoleSheet(context, ref, isDark)),
            ]));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rolesProvider),
            child: ListView(
              padding: EdgeInsets.all(hPad),
              children: [
                // System roles banner
                Container(
                  padding: EdgeInsets.all(TResponsive.sp(context, TSizes.sm)),
                  decoration: BoxDecoration(
                    color: TColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(TSizes.radiusMd),
                    border: Border.all(color: TColors.info.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Iconsax.info_circle, size: 16, color: TColors.info),
                    const SizedBox(width: 8),
                    Expanded(child: Text('System roles cannot be deleted or modified.', style: TextStyle(
                      fontSize: TResponsive.sp(context, 12),
                      color: TColors.info,
                    ))),
                  ]),
                ),
                const SizedBox(height: TSizes.md),

                // Roles list
                ...roles.map((role) => Padding(
                  padding: const EdgeInsets.only(bottom: TSizes.sm),
                  child: _RoleCard(role: role, isDark: isDark, ref: ref),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateRoleSheet(BuildContext context, WidgetRef ref, bool isDark) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? TColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            TResponsive.pagePadding(context), TSizes.lg,
            TResponsive.pagePadding(context),
            MediaQuery.of(context).viewInsets.bottom + TSizes.lg,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create Role', style: TextStyle(
              fontSize: TResponsive.sp(context, 18),
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textDark : TColors.textLight,
            )),
            const SizedBox(height: TSizes.md),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
              ),
            ),
            const SizedBox(height: TSizes.sm),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
              ),
            ),
            const SizedBox(height: TSizes.md),
            TButton(
              text: 'Create',
              isLoading: isSubmitting,
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                setState(() => isSubmitting = true);
                await ref.read(roleNotifierProvider.notifier).createRole({
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                });
                ref.invalidate(rolesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final bool isDark;
  final WidgetRef ref;
  const _RoleCard({required this.role, required this.isDark, required this.ref});

  static const _systemColors = {
    'super_admin': TColors.error,
    'admin': TColors.warning,
    'manager': TColors.primary,
    'employee': TColors.success,
    'member': TColors.info,
    'guest': TColors.neutralGray,
  };

  Color get _color => _systemColors[role.slug ?? role.name.toLowerCase()] ?? TColors.primary;

  @override
  Widget build(BuildContext context) {
    return TCard(
      hasBorder: true,
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
            ),
            child: Icon(Iconsax.shield, size: 20, color: _color),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(role.name, style: TextStyle(
                fontSize: TResponsive.sp(context, 15),
                fontWeight: FontWeight.w700,
                color: isDark ? TColors.textDark : TColors.textLight,
              )),
              if (role.isSystem) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: TColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(TSizes.radiusFull),
                  ),
                  child: Text('System', style: TextStyle(
                    fontSize: TResponsive.sp(context, 10),
                    fontWeight: FontWeight.w600,
                    color: TColors.info,
                  )),
                ),
              ],
            ]),
            if (role.description != null) Text(role.description!, style: TextStyle(
              fontSize: TResponsive.sp(context, 12),
              color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
            )),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? TColors.darkElevated : TColors.lightElevated),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
            ),
            child: Text('Level ${role.hierarchy}', style: TextStyle(
              fontSize: TResponsive.sp(context, 11),
              fontWeight: FontWeight.w600,
              color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
            )),
          ),
        ]),

        if (role.permissions.isNotEmpty) ...[
          const SizedBox(height: TSizes.sm),
          const Divider(height: 1),
          const SizedBox(height: TSizes.sm),
          Wrap(spacing: 6, runSpacing: 6, children: role.permissions.take(5).map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(TSizes.radiusFull),
            ),
            child: Text(p.resource, style: TextStyle(
              fontSize: TResponsive.sp(context, 10),
              fontWeight: FontWeight.w500,
              color: _color,
            )),
          )).toList()
            ..addAll(role.permissions.length > 5 ? [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkElevated : TColors.lightElevated,
                  borderRadius: BorderRadius.circular(TSizes.radiusFull),
                ),
                child: Text('+${role.permissions.length - 5} more', style: TextStyle(
                  fontSize: TResponsive.sp(context, 10),
                  color: isDark ? TColors.darkMuted : TColors.lightMuted,
                )),
              )
            ] : [])),
        ],
      ]),
    );
  }
}
