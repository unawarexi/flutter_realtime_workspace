import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/domain/models/auth_session_model.dart';
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
    if (password.length < 8) return 'At least 8 characters required';
    if (password.length > 128) return 'Password too long (max 128 characters)';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Add at least one uppercase letter (A–Z)';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Add at least one lowercase letter (a–z)';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Add at least one number (0–9)';
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
          context.go('/2fa', extra: session);
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
    bool termsAccepted = false,
  }) async {
    try {
      await ref
          .read(currentUserProvider.notifier)
          .signUpWithEmailPassword(email, password, fullName, termsAccepted: termsAccepted);
      if (context.mounted) {
        AppToast.show(
          'Account created. Please verify your email before continuing.',
          type: ToastType.success,
          context: context,
        );
        context.go('/verify-email-success', extra: {
          'nextRoute': '/options',
          'title': 'Almost There!',
          'message': 'We\'ve sent a verification link to your email.\nVerify your account, then choose how to get started.',
        });
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

  // ── Forgot Password ─────────────────────────────────────────────────────────
  static Future<void> forgotPassword({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
  }) async {
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (context.mounted) {
        AppToast.show(
          'Password reset link sent. Check your email.',
          type: ToastType.success,
          context: context,
        );
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

  // ── Reset Password ───────────────────────────────────────────────────────────
  static Future<void> resetPassword({
    required BuildContext context,
    required WidgetRef ref,
    required String token,
    required String newPassword,
  }) async {
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: token,
            newPassword: newPassword,
          );
      if (context.mounted) {
        AppToast.show(
          'Password reset successfully. Please sign in.',
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

  // ── Verify 2FA ───────────────────────────────────────────────────────────────
  static Future<void> verify2FA({
    required BuildContext context,
    required WidgetRef ref,
    required String otp,
    AuthSessionModel? pendingSession,
  }) async {
    final tempToken = pendingSession?.tempToken;
    final method = pendingSession?.method ?? 'email';
    if (tempToken == null) {
      if (context.mounted) {
        AppToast.show(
          'Session expired. Please sign in again.',
          type: ToastType.error,
          context: context,
        );
        context.go('/login');
      }
      return;
    }
    try {
      await ref.read(currentUserProvider.notifier).verify2FA(
            tempToken: tempToken,
            otp: otp,
            method: method,
          );
      if (context.mounted) {
        AppToast.show(
          'Verification successful. Welcome!',
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

  // ── Resend 2FA code ──────────────────────────────────────────────────────────
  static Future<void> resend2FACode({
    required BuildContext context,
    required WidgetRef ref,
    required AuthSessionModel pendingSession,
  }) async {
    final tempToken = pendingSession.tempToken;
    if (tempToken == null) return;
    try {
      await ref.read(authRepositoryProvider).resend2FACode(tempToken);
      if (context.mounted) {
        AppToast.show(
          'Verification code resent.',
          type: ToastType.success,
          context: context,
        );
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
}
