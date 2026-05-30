import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Shown after email/password registration (or when login detects unverified account).
/// The user enters the 6-digit OTP from their inbox. On success the backend
/// auto-logs them in and navigates to the verification-success screen.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  static const _otpLength = 6;

  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  /// One controller per OTP box.
  final List<TextEditingController> _boxControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _boxFocus =
      List.generate(_otpLength, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  bool _resendDisabled = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconController.forward();

    // Auto-start resend cooldown so user can't spam on first load.
    _startResendCooldown();
  }

  @override
  void dispose() {
    _iconController.dispose();
    for (final c in _boxControllers) {
      c.dispose();
    }
    for (final f in _boxFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp =>
      _boxControllers.map((c) => c.text).join();

  bool get _otpComplete => _currentOtp.length == _otpLength;

  /// Handle a digit typed in one of the OTP boxes.
  void _onBoxChanged(int index, String value) {
    if (value.length > 1) {
      // Paste scenario: distribute digits across boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength && i < digits.length; i++) {
        _boxControllers[i].text = digits[i];
      }
      final next = (digits.length < _otpLength) ? digits.length : _otpLength - 1;
      FocusScope.of(context).requestFocus(_boxFocus[next]);
      setState(() {});
      if (_otpComplete) _submitOtp();
      return;
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      FocusScope.of(context).requestFocus(_boxFocus[index + 1]);
    }
    setState(() {});
    if (_otpComplete) _submitOtp();
  }

  void _onBoxBackspace(int index) {
    if (_boxControllers[index].text.isEmpty && index > 0) {
      _boxControllers[index - 1].clear();
      FocusScope.of(context).requestFocus(_boxFocus[index - 1]);
      setState(() {});
    }
  }

  Future<void> _submitOtp() async {
    if (_verifying || !_otpComplete) return;
    setState(() => _verifying = true);
    try {
      await AuthUseCase.verifyEmailOtp(
        context: context,
        ref: ref,
        email: widget.email,
        otp: _currentOtp,
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_resendDisabled || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
      if (!mounted) return;
      AppToast.show(
        'Verification code sent. Check your inbox.',
        type: ToastType.success,
        context: context,
      );
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        'Could not resend code. Please try again.',
        type: ToastType.error,
        context: context,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startResendCooldown() {
    setState(() {
      _resendDisabled = true;
      _resendCooldown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        setState(() => _resendDisabled = false);
        return false;
      }
      return true;
    });
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
                colors: [TColors.primary, TColors.blue700],
                orbCount: 4,
                isDark: isDark,
                seed: 42,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.45),
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: TSizes.xxl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon badge
                      ScaleTransition(
                        scale: _iconScale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: TColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_outlined,
                            color: TColors.primary,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.lg),

                      // Logo
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: Image.asset(
                          isDark ? TImages.darkEmblem : TImages.lightEmblem,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: TSizes.lg),

                      // Title
                      TWidgetAnimations.slideUp(
                        child: Text(
                          'Verify Your Email',
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
                      const SizedBox(height: TSizes.sm),

                      // Subtitle
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 120),
                        child: Text(
                          'We sent a 6-digit code to',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xs),

                      // Email chip
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 160),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.md,
                            vertical: TSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: TColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xxl),

                      // OTP input boxes
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 220),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_otpLength, (i) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: _OtpBox(
                                controller: _boxControllers[i],
                                focusNode: _boxFocus[i],
                                isDark: isDark,
                                onChanged: (v) => _onBoxChanged(i, v),
                                onBackspace: () => _onBoxBackspace(i),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),

                      // Verify button
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 280),
                        child: TButton(
                          text: 'Verify Email',
                          isLoading: _verifying,
                          onPressed: _otpComplete ? _submitOtp : null,
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),

                      // Resend button
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 320),
                        child: TButton(
                          text: _resendDisabled
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend Code',
                          variant: SButtonVariant.outline,
                          isLoading: _resending,
                          onPressed: _resendDisabled ? null : _resendEmail,
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),

                      // Tip
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 360),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: isDark
                                  ? TColors.textSecondaryDark
                                  : TColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Code expires in 30 minutes. Check spam if you don\'t see it.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? TColors.textSecondaryDark
                                      : TColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
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
}

/// A single OTP digit box that handles keyboard input and backspace navigation.
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? TColors.textDark : TColors.textLight,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: isDark
                ? TColors.darkCard.withValues(alpha: 0.8)
                : TColors.lightCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? TColors.darkBorder : TColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? TColors.darkBorder : TColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: TColors.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
