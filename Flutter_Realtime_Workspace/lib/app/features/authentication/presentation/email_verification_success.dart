import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Shown after successful email/OTP verification (e.g. post-signup).
/// Auto-navigates to [nextRoute] after [autoNavigateSeconds] seconds.
class EmailVerificationSuccessScreen extends StatefulWidget {
  final String? nextRoute;
  final String? title;
  final String? message;

  const EmailVerificationSuccessScreen({
    super.key,
    this.nextRoute,
    this.title,
    this.message,
  });

  @override
  State<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends State<EmailVerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  Timer? _navTimer;
  int _countdown = 5;

  String get _nextRoute => widget.nextRoute ?? '/login';
  String get _title => widget.title ?? 'Check Your Email';
  String get _message =>
      widget.message ??
      'We\'ve sent a verification link to your email.\nClick the link to verify your account.';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _controller.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _navTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          t.cancel();
          context.go(_nextRoute);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.success, TColors.primary],
                orbCount: 3,
                isDark: isDark,
                seed: 99,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.4),
                spacing: 28,
                dotRadius: 1.0,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: TResponsive.maxContentWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: TSizes.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated success badge
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildSuccessBadge(isDark),
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),
                      // Logo
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 300),
                        child: Image.asset(
                          isDark ? TImages.darkEmblem : TImages.lightEmblem,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: TSizes.lg),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 400),
                        child: TWidgetAnimations.slideUp(
                          child: Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? TColors.textDark
                                      : TColors.textLight,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xxl),
                      // Countdown ring
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 600),
                        child: _CountdownRing(
                          countdown: _countdown,
                          total: 5,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 650),
                        child: Text(
                          'Redirecting in $_countdown second${_countdown == 1 ? '' : 's'}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 700),
                        child: TButton(
                          text: 'Continue Now',
                          onPressed: () => context.go(_nextRoute),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBadge(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TColors.success.withValues(alpha: 0.08),
            border: Border.all(
              color: TColors.success.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
        ),
        // Middle ring
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TColors.success.withValues(alpha: 0.12),
            border: Border.all(
              color: TColors.success.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
        ),
        // Inner badge
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TColors.success.withValues(alpha: 0.18),
            border: Border.all(
              color: TColors.success.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: TColors.success,
          ),
        ),
      ],
    );
  }
}

/// A circular countdown widget that visually counts down.
class _CountdownRing extends StatelessWidget {
  final int countdown;
  final int total;
  final bool isDark;

  const _CountdownRing({
    required this.countdown,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = countdown / total;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor:
                (isDark ? TColors.darkBorder : TColors.lightBorder),
            valueColor:
                const AlwaysStoppedAnimation<Color>(TColors.primary),
          ),
          Text(
            '$countdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textDark : TColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
