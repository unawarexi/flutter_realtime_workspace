import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// The reset token passed via deep-link query parameter `?token=`.
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = widget.token ??
        GoRouterState.of(context).uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or missing reset token. Please request a new link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await AuthUseCase.resetPassword(
      context: context,
      ref: ref,
      token: token,
      newPassword: _passwordController.text,
    );
    if (mounted) setState(() => _loading = false);
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
                seed: 33,
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
                    onPressed: () => context.go('/login'),
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
                                TIcons.password,
                                size: 26,
                                color: TColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.md),
                          TWidgetAnimations.slideUp(
                            child: Text(
                              'Reset Password',
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
                              'Enter your new password below.',
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
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TWidgetAnimations.fadeIn(
                                  delay: const Duration(milliseconds: 100),
                                  child: TInput(
                                    controller: _passwordController,
                                    hint: 'New password',
                                    prefixIcon: TIcons.password,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthUseCase.validatePassword,
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                      icon: Icon(
                                        _obscurePassword
                                            ? TIcons.passwordHidden
                                            : TIcons.passwordVisible,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TSizes.sm),
                                TWidgetAnimations.fadeIn(
                                  delay: const Duration(milliseconds: 140),
                                  child: TInput(
                                    controller: _confirmController,
                                    hint: 'Confirm new password',
                                    prefixIcon: TIcons.password,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      final err = AuthUseCase.validatePassword(value);
                                      if (err != null) return err;
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? TIcons.passwordHidden
                                            : TIcons.passwordVisible,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TSizes.md),
                                TWidgetAnimations.fadeIn(
                                  delay: const Duration(milliseconds: 180),
                                  child: TButton(
                                    text: 'Reset Password',
                                    onPressed: _loading ? null : _submit,
                                    isLoading: _loading,
                                    prefixIcon: TIcons.password,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TSizes.md),
                          TWidgetAnimations.fadeIn(
                            delay: const Duration(milliseconds: 220),
                            child: Center(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
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
