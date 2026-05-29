import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:go_router/go_router.dart';

/// Top bar with profile avatar, notification button, and add button.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.isDark,
    required this.unreadCount,
    required this.roleLabel,
  });
  final bool isDark;
  final int unreadCount;
  final String roleLabel;

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
            onTap: () => context.push('/account?userId=$userId'),
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
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(TSizes.radiusFull),
                  border: Border.all(
                    color: TColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? TColors.blue400 : TColors.primary,
                  ),
                ),
              ),
            ),
          ),
          // ── Action buttons ───────────────────────────────────
          Row(
            children: [
              _HeaderIconBtn(
                icon: TIcons.notification,
                isDark: isDark,
                badge: unreadCount > 0,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: TSizes.xs + 2),
              _HeaderIconBtn(
                icon: TIcons.add,
                isDark: isDark,
                primary: true,
                onTap: () => context.push('/tasks/create'),
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
