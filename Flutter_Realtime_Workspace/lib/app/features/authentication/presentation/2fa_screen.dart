import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/domain/models/auth_session_model.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class TwoFAScreen extends ConsumerStatefulWidget {
  const TwoFAScreen({super.key});

  @override
  ConsumerState<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends ConsumerState<TwoFAScreen> {
  final _formKey = GlobalKey<FormState>();
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();
  Timer? _timer;
  int _secondsLeft = 300;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;
  String _otp = '';

  AuthSessionModel? get _pendingSession =>
      GoRouterState.of(context).extra as AuthSessionModel?;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = _pendingSession;
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });
    await AuthUseCase.verify2FA(
      context: context,
      ref: ref,
      otp: _otp,
      pendingSession: session,
    );
    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _resend() async {
    final session = _pendingSession;
    if (session?.tempToken == null) return;
    setState(() => _isResending = true);
    await AuthUseCase.resend2FACode(
      context: context,
      ref: ref,
      pendingSession: session!,
    );
    if (mounted) {
      setState(() => _isResending = false);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final expiredColor = _secondsLeft > 60 ? TColors.primary : TColors.error;

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      body: Stack(
        children: [
          // Ambient orbs
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.primary, TColors.blue700],
                orbCount: 3,
                isDark: isDark,
                seed: 21,
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
                      horizontal: hPad, vertical: TSizes.xxl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon badge
                        TWidgetAnimations.scaleIn(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: TColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: TColors.primary.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              TIcons.privacy,
                              size: 32,
                              color: TColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.lg),
                        TWidgetAnimations.slideUp(
                          child: Text(
                            'Two-Factor Authentication',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? TColors.textDark
                                      : TColors.textLight,
                                ),
                          ),
                        ),
                        const SizedBox(height: TSizes.sm),
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 60),
                          child: Text(
                            'Enter the 6-digit code sent to your email or authenticator app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? TColors.textSecondaryDark
                                  : TColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.md),
                        // Timer
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: TSizes.md, vertical: TSizes.xs),
                            decoration: BoxDecoration(
                              color: expiredColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(TSizes.radiusFull),
                              border: Border.all(
                                  color: expiredColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Expires in: ${_formatTime(_secondsLeft)}',
                              style: TextStyle(
                                color: expiredColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: TSizes.sm),
                          Text(
                            _errorText!,
                            style: const TextStyle(
                                color: TColors.error, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: TSizes.xl),
                        // PIN input
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 140),
                          child: PinCodeTextField(
                            appContext: context,
                            length: 6,
                            obscureText: false,
                            animationType: AnimationType.fade,
                            keyboardType: TextInputType.number,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius:
                                  BorderRadius.circular(TSizes.radiusMd),
                              fieldHeight: 52,
                              fieldWidth: 44,
                              activeFillColor: isDark
                                  ? TColors.darkCard
                                  : TColors.lightSurface,
                              inactiveFillColor: isDark
                                  ? TColors.darkSurface
                                  : TColors.lightElevated,
                              selectedFillColor:
                                  TColors.primary.withValues(alpha: 0.1),
                              activeColor: TColors.primary,
                              selectedColor: TColors.primary,
                              inactiveColor: isDark
                                  ? TColors.darkBorder
                                  : TColors.lightBorder,
                            ),
                            animationDuration:
                                const Duration(milliseconds: 200),
                            backgroundColor: Colors.transparent,
                            enableActiveFill: true,
                            onChanged: (value) {
                              _otp = value;
                              setState(() => _errorText = null);
                            },
                            onCompleted: (value) {
                              _otp = value;
                            },
                            validator: (value) {
                              if (value == null || value.length != 6) {
                                return 'Enter all 6 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: TSizes.sm),
                        // Resend
                        TextButton(
                          onPressed: (_secondsLeft > 0 || _isResending)
                              ? null
                              : _resend,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(
                                  _secondsLeft > 0
                                      ? 'Resend in ${_formatTime(_secondsLeft)}'
                                      : 'Send Again',
                                  style: TextStyle(
                                    color: _secondsLeft > 0
                                        ? (isDark
                                            ? TColors.textSecondaryDark
                                            : TColors.textSecondaryLight)
                                        : TColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: TSizes.md),
                        // Verify button
                        TButton(
                          text: 'Verify',
                          isLoading: _isVerifying,
                          onPressed: _isVerifying ? null : _verify,
                        ),
                      ],
                    ),
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
