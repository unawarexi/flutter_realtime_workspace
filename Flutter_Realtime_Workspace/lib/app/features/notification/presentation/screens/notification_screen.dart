import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/notification_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/notification_provider.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationRealtimeProvider);

    final isDarkMode = THelperFunctions.isDarkMode(context);
    final unreadCount = NotificationUseCase.unreadCount(ref);

    return Scaffold(
      backgroundColor:
          isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDarkMode ? TColors.textDark : TColors.textLight,
              ),
            ),
            Text(
              'Android push and realtime badge state',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? TColors.textDarkSecondary
                    : TColors.textLightSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: TSizes.md),
            child: Center(
              child: TextButton(
                onPressed: unreadCount == 0
                    ? null
                    : () => NotificationUseCase.markAllRead(
                          context: context,
                          ref: ref,
                        ),
                child: const Text('Mark all read'),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _StatsRow(
                isDarkMode: isDarkMode,
                unreadCount: unreadCount,
              ),
              const SizedBox(height: TSizes.lg),
              _RealtimeStatusCard(
                isDarkMode: isDarkMode,
                unreadCount: unreadCount,
              ),
              const SizedBox(height: TSizes.md),
              const _CapabilitiesCard(),
              const SizedBox(height: TSizes.md),
              _ActionsCard(
                isDarkMode: isDarkMode,
                unreadCount: unreadCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.isDarkMode,
    required this.unreadCount,
  });

  final bool isDarkMode;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Unread',
            value: '$unreadCount',
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFFDC2626),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: _StatCard(
            title: 'Transport',
            value: 'Live',
            icon: Icons.wifi_tethering_rounded,
            color: const Color(0xFF1E40AF),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: _StatCard(
            title: 'Platform',
            value: 'Android',
            icon: Icons.android_rounded,
            color: const Color(0xFF16A34A),
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return TCard(
      hasBorder: true,
      hasShadow: true,
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: TSizes.iconSm),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? TColors.textDarkSecondary
                  : TColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RealtimeStatusCard extends StatelessWidget {
  const _RealtimeStatusCard({
    required this.isDarkMode,
    required this.unreadCount,
  });

  final bool isDarkMode;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return TCard(
      hasBorder: true,
      hasShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unreadCount > 0 ? 'New activity available' : 'All caught up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            unreadCount > 0
                ? 'Unread badge state is being driven from websocket notification events. Open the related screen from the push tap, or clear the badge here when you have reviewed the update.'
                : 'Push notifications, local Android channels, and websocket badge updates are wired. The backend notifications module does not expose a persisted in-app inbox endpoint yet, so this screen reflects live state instead of a stored timeline.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDarkMode
                  ? TColors.textDarkSecondary
                  : TColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard();

  @override
  Widget build(BuildContext context) {
    return const TCard(
      hasBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CapabilityRow(
            icon: Icons.notifications_outlined,
            title: 'Android local channels',
            subtitle:
                'Meeting, call, chat, and system channels are configured in NotificationService.',
          ),
          SizedBox(height: TSizes.md),
          _CapabilityRow(
            icon: Icons.route_outlined,
            title: 'Safe tap routing',
            subtitle:
                'Notification taps now navigate only to routes that exist in the app router.',
          ),
          SizedBox(height: TSizes.md),
          _CapabilityRow(
            icon: Icons.phone_android_outlined,
            title: 'Android-first rollout',
            subtitle:
                'Apple notification settings remain intentionally disabled in the client.',
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: TColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(TSizes.radiusSm),
          ),
          child: Icon(icon, size: TSizes.iconSm, color: TColors.primary),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? TColors.textDark : TColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDarkMode
                      ? TColors.textDarkSecondary
                      : TColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsCard extends ConsumerWidget {
  const _ActionsCard({
    required this.isDarkMode,
    required this.unreadCount,
  });

  final bool isDarkMode;
  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TCard(
      hasBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: TSizes.md),
          TButton(
            text: 'Open notification preferences',
            variant: SButtonVariant.outline,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(height: TSizes.sm),
          TButton(
            text:
                unreadCount > 0 ? 'Clear unread badge' : 'Unread badge is clear',
            onPressed: unreadCount > 0
                ? () => NotificationUseCase.markAllRead(
                      context: context,
                      ref: ref,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
