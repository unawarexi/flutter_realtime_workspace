import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';

class SignOutSection extends ConsumerWidget {
  final bool isDarkMode;
  const SignOutSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(
          color: isDarkMode ? TColors.darkBorder : TColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.04),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(
          TIcons.logout,
          color: TColors.error,
          size: TSizes.iconMd,
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: TColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        onTap: () async {
          await ref.read(currentUserProvider.notifier).signOut();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
    );
  }
}
