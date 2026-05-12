import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/features/home/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/account.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/create_task_screen.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Top bar with profile avatar, notification button, and add button.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = HomeUseCase.photoUrl(ref);
    final userId = HomeUseCase.userId(ref);

    return TWidgetAnimations.fadeIn(
      duration: const Duration(milliseconds: 380),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountScreen(userId: userId),
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TColors.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TColors.primary.withValues(alpha: 0.22),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : const AssetImage(TImages.lightAppLogo)
                            as ImageProvider,
                    backgroundColor:
                        isDark ? TColors.darkCard : TColors.lightSurface,
                  ),
                ),
                // Online dot
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: TColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? TColors.darkBg : TColors.lightBg,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // ── Action buttons ───────────────────────────────────
          Row(
            children: [
              _HeaderIconBtn(
                icon: TIcons.notification,
                isDark: isDark,
                badge: true,
              ),
              const SizedBox(width: TSizes.xs + 2),
              _HeaderIconBtn(
                icon: TIcons.add,
                isDark: isDark,
                primary: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTaskScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.isDark,
    this.primary = false,
    this.badge = false,
    this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final bool primary;
  final bool badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary
                  ? TColors.primary
                  : (isDark ? TColors.darkCard : TColors.lightSurface),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
              border: primary
                  ? null
                  : Border.all(
                      color:
                          isDark ? TColors.darkBorder : TColors.lightBorder,
                      width: 0.9,
                    ),
              boxShadow: [
                BoxShadow(
                  color: primary
                      ? TColors.primary.withValues(alpha: 0.22)
                      : (isDark ? Colors.black : Colors.grey)
                          .withValues(alpha: 0.06),
                  blurRadius: primary ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: TSizes.iconSm + 2,
              color: primary
                  ? Colors.white
                  : (isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight),
            ),
          ),
          if (badge)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: TColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
