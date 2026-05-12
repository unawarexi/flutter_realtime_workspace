import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';

class AuthUseCase {
  AuthUseCase._();

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required';
    if (name.length < 2) return 'Full name must be at least 2 characters';
    return null;
  }

  static Future<void> signInWithEmailPassword({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
    required String password,
  }) async {
    try {
      final session = await ref
          .read(currentUserProvider.notifier)
          .signInWithEmailPassword(email, password);

      if (session.requires2FA) {
        if (context.mounted) {
          AppToast.show(
            '2FA is required to complete sign in.',
            type: ToastType.info,
            context: context,
          );
          context.go('/2fa');
        }
        return;
      }

      if (context.mounted) {
        AppToast.show(
          'Welcome back',
          type: ToastType.success,
          context: context,
        );
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractErrorMessage(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  static Future<void> signUpWithEmailPassword({
    required BuildContext context,
    required WidgetRef ref,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await ref
          .read(currentUserProvider.notifier)
          .signUpWithEmailPassword(email, password, fullName);
      if (context.mounted) {
        AppToast.show(
          'Account created. Please verify your email before login.',
          type: ToastType.success,
          context: context,
        );
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractErrorMessage(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  static Future<void> signInWithGoogle({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(currentUserProvider.notifier).signInWithGoogle();
      if (context.mounted) {
        AppToast.show(
          'Signed in with Google',
          type: ToastType.success,
          context: context,
        );
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractErrorMessage(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  static Future<void> signInWithGithub({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(currentUserProvider.notifier).signInWithGithub();
      if (context.mounted) {
        AppToast.show(
          'Signed in with GitHub',
          type: ToastType.success,
          context: context,
        );
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractErrorMessage(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  static String _extractErrorMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('Invalid credentials')) return 'Invalid email or password';
    if (raw.contains('verify your email')) {
      return 'Please verify your email before logging in';
    }
    return raw.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
  }
}
