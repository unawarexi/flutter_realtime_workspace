import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/decorative_painters.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/onboarding_divider.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class SignUp extends ConsumerStatefulWidget {
  const SignUp({super.key});

  @override
  ConsumerState<SignUp> createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await AuthUseCase.signUpWithEmailPassword(
      context: context,
      ref: ref,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      termsAccepted: _termsAccepted,
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
          // Ambient orbs
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.primary, TColors.blue700],
                orbCount: 4,
                isDark: isDark,
                seed: 13,
              ),
            ),
          ),
          // Dot grid
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.55),
                spacing: 28,
                dotRadius: 1.0,
              ),
            ),
          ),
          // Corner accent top-right
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: TCornerArcPainter(
                  color: TColors.primary.withValues(alpha: 0.12),
                  radius: 160,
                  corner: CornerPosition.topRight,
                ),
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
                    vertical: TSizes.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TWidgetAnimations.scaleIn(
                          child: Center(
                            child: Image.asset(
                              isDark
                                  ? TImages.darkEmblem
                                  : TImages.lightEmblem,
                              height: TResponsive.sp(context, 60,
                                  tabletSize: 80),
                              width: 130,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.md),
                        TWidgetAnimations.slideUp(
                          child: Text(
                            'Create Account',
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
                        const SizedBox(height: TSizes.xs),
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 60),
                          child: Text(
                            'Join TeamSpot — sign up with email & password.',
                            style: TextStyle(
                              fontSize: TResponsive.sp(context, 13),
                              color: isDark
                                  ? TColors.textSecondaryDark
                                  : TColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.md),
                        // Full name
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 80),
                          child: TInput(
                            controller: _nameController,
                            hint: 'Full name',
                            prefixIcon: TIcons.profile,
                            textInputAction: TextInputAction.next,
                            validator: AuthUseCase.validateFullName,
                          ),
                        ),
                        const SizedBox(height: TSizes.sm),
                        // Email
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 110),
                          child: TInput(
                            controller: _emailController,
                            hint: 'Email address',
                            prefixIcon: TIcons.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: AuthUseCase.validateEmail,
                          ),
                        ),
                        const SizedBox(height: TSizes.sm),
                        // Password
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 140),
                          child: TInput(
                            controller: _passwordController,
                            hint: 'Password',
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
                        // Confirm password
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 170),
                          child: TInput(
                            controller: _confirmController,
                            hint: 'Confirm password',
                            prefixIcon: TIcons.password,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
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
                        // Terms & Privacy checkbox
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 185),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (v) =>
                                      setState(() => _termsAccepted = v ?? false),
                                  activeColor: TColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      'I agree to the ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? TColors.textSecondaryDark
                                            : TColors.textSecondaryLight,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/terms'),
                                      child: const Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: TColors.primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' and ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? TColors.textSecondaryDark
                                            : TColors.textSecondaryLight,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/privacy'),
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: TColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TSizes.lg),
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: TButton(
                            text: 'Create Account',
                            onPressed: _loading ? null : _submit,
                            isLoading: _loading,
                            prefixIcon: TIcons.invite,
                          ),
                        ),
                        const SizedBox(height: TSizes.md),
                        // Divider
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 215),
                          child: const CustomDivider(),
                        ),
                        const SizedBox(height: TSizes.md),
                        // Social sign-up buttons
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 230),
                          child: SocialLoginButton(
                            label: 'Sign up with Google',
                            icon: Image.asset(TImages.googleIcon,
                                width: 20, height: 20),
                            onPressed: () => AuthUseCase.signInWithGoogle(
                              context: context,
                              ref: ref,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.sm),
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 250),
                          child: SocialLoginButton(
                            label: 'Sign up with GitHub',
                            icon: Image.asset(TImages.githubIcon,
                                width: 20, height: 20),
                            onPressed: () => AuthUseCase.signInWithGithub(
                              context: context,
                              ref: ref,
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.xl),
                        // Login link
                        TWidgetAnimations.fadeIn(
                          delay: const Duration(milliseconds: 240),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Already have an account?  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? TColors.textSecondaryDark
                                        : TColors.textSecondaryLight,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: TColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
