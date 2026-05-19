import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await AuthUseCase.forgotPassword(
      context: context,
      ref: ref,
      email: _emailController.text.trim(),
    );
    if (mounted) setState(() {
      _loading = false;
      _sent = true;
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
                orbCount: 3,
                isDark: isDark,
                seed: 42,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.5),
                spacing: 28,
                dotRadius: 1.0,
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Fixed back button top-left
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? TColors.textDark : TColors.textLight,
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: TResponsive.maxContentWidth(context),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          hPad, TSizes.xxl + TSizes.lg, hPad, TSizes.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon badge
                          TWidgetAnimations.scaleIn(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: TColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: TColors.primary.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                TIcons.email,
                                size: 26,
                                color: TColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.md),
                          TWidgetAnimations.slideUp(
                            child: Text(
                              'Forgot Password?',
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
                              _sent
                                  ? 'A reset link has been sent to your email.\nCheck your inbox and follow the instructions.'
                                  : 'Enter your email address and we\'ll send you a link to reset your password.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? TColors.textSecondaryDark
                                    : TColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.xl),
                          if (_sent) ...[
                            // Success state
                            TWidgetAnimations.scaleIn(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: TColors.success.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: TColors.success,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: TSizes.xl),
                            TButton(
                              text: 'Back to Sign In',
                              onPressed: () => context.go('/login'),
                            ),
                            const SizedBox(height: TSizes.sm),
                            TextButton(
                              onPressed: () => setState(() => _sent = false),
                              child: const Text(
                                'Resend email',
                                style: TextStyle(color: TColors.primary),
                              ),
                            ),
                          ] else ...[
                            // Input form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TWidgetAnimations.fadeIn(
                                    delay: const Duration(milliseconds: 120),
                                    child: TInput(
                                      controller: _emailController,
                                      hint: 'Email address',
                                      prefixIcon: TIcons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      validator: AuthUseCase.validateEmail,
                                    ),
                                  ),
                                  const SizedBox(height: TSizes.md),
                                  TWidgetAnimations.fadeIn(
                                    delay: const Duration(milliseconds: 160),
                                    child: TButton(
                                      text: 'Send Reset Link',
                                      onPressed: _loading ? null : _submit,
                                      isLoading: _loading,
                                      prefixIcon: TIcons.email,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: TSizes.md),
                            TWidgetAnimations.fadeIn(
                              delay: const Duration(milliseconds: 200),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Back to Sign In',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
