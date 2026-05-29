import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Email + password login form using shared TInput / TButton primitives.
class PasswordAuthentication extends ConsumerStatefulWidget {
  const PasswordAuthentication({super.key});

  @override
  ConsumerState<PasswordAuthentication> createState() =>
      _PasswordAuthenticationState();
}

class _PasswordAuthenticationState
    extends ConsumerState<PasswordAuthentication> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await AuthUseCase.signInWithEmailPassword(
      context: context,
      ref: ref,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TWidgetAnimations.fadeIn(
            duration: const Duration(milliseconds: 260),
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
          TWidgetAnimations.fadeIn(
            duration: const Duration(milliseconds: 300),
            child: TInput(
              controller: _passwordController,
              hint: 'Password',
              prefixIcon: TIcons.password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: AuthUseCase.validatePassword,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? TIcons.passwordHidden : TIcons.passwordVisible,
                  size: 18,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),
          TButton(
            text: 'Sign In',
            onPressed: _loading ? null : _submit,
            isLoading: _loading,
            prefixIcon: TIcons.email,
          ),
        ],
      ),
    );
  }
}

