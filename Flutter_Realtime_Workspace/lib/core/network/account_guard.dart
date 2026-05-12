import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/auth/google_signin.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/db/hive.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/router/app_router.dart';

/// Detects deleted / suspended accounts and forces sign-out with a user-facing
/// dialog.  Safe to call from interceptors — only the first invocation shows
/// the dialog; subsequent calls are no-ops until the flow completes.
class AccountGuard {
  AccountGuard._internal();
  static final AccountGuard instance = AccountGuard._internal();

  static bool _triggered = false;

  /// Call when a persistent 401 (post-refresh) or 404 on auth endpoints is
  /// detected.  Shows a modal, clears local state, and redirects to `/login`.
  static Future<void> trigger() async {
    if (_triggered) return;
    _triggered = true;

    final context = rootNavigatorKey.currentContext;

    // Clear all auth state regardless of whether we can show a dialog.
    await _forceSignOut();

    if (context != null && context.mounted) {
      await _showAccountDialog(context);
    }

    // Navigate to login via GoRouter (works without a context).
    appRouter.go('/login');
    _triggered = false;
  }

  // ────────────── Dialog ──────────────

  static Future<void> _showAccountDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: CupertinoAlertDialog(
          title: Text(
            'Account Not Found',
            style: TextStyle(
              color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: TSizes.paddingSM),
            child: Text(
              'Your account may have been suspended or deleted.\n\n'
              'Please contact customer support or sign up again.',
              style: TextStyle(
                color: isDark
                    ? TColors.textSecondaryDark
                    : TColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: TColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────── Sign-out ──────────────

  static Future<void> _forceSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignInService.signOut();
    } catch (_) {}
    try {
      await SecureStorageService.clearAll();
    } catch (_) {}
    try {
      await Future.wait([
        HiveService.clearBox(HiveService.user),
        HiveService.clearBox(HiveService.projects),
        HiveService.clearBox(HiveService.teams),
        HiveService.clearBox(HiveService.tasks),
        HiveService.clearBox(HiveService.notifications),
        HiveService.clearBox(HiveService.schedule),
        HiveService.clearBox(HiveService.settings),
      ]);
    } catch (_) {}
  }
}
