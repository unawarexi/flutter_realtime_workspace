import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/settings_provider.dart';
import 'package:flutter_realtime_workspace/store/theme_provider.dart';

/// Business logic for the Settings feature.
///
/// Manages user preferences, notifications, security, and app settings
/// through the settings provider. No explicit repository calls — all goes through
/// the SettingsNotifier state machine.
class SettingsUseCase {
  SettingsUseCase._();

  // ── Account Settings ─────────────────────────────────────────────────────

  static bool canEditAccount(WidgetRef ref) {
    final current = ref.read(currentUserProvider).valueOrNull;
    return current != null;
  }

  static Future<bool> updateAccount({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final fullName = (updates['fullName'] ?? updates['displayName']) as String?;
      final bio = updates['bio'] as String?;

      await ref.read(updateProfileProvider)(
            fullName: (fullName != null && fullName.trim().isNotEmpty)
                ? fullName.trim()
                : null,
            bio: (bio != null && bio.trim().isNotEmpty) ? bio.trim() : null,
          );

      if (context.mounted) {
        AppToast.show(
          'Profile updated successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
  }

  static Future<bool> changePassword({
    required BuildContext context,
    required WidgetRef ref,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: oldPassword,
            newPassword: newPassword,
          );

      if (context.mounted) {
        AppToast.show(
          'Password changed successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
  }

  static Future<bool> deleteAccount({
    required BuildContext context,
    required WidgetRef ref,
    required String password,
  }) async {
    try {
      await ref.read(currentUserProvider.notifier).deleteAccount();

      if (context.mounted) {
        AppToast.show(
          'Account deleted',
          type: ToastType.success,
          context: context,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
  }

  // ── Notification Settings ────────────────────────────────────────────────

  static Future<void> toggleNotificationChannel({
    required WidgetRef ref,
    required String channel,
    required bool enabled,
  }) async {
    try {
      final notifier = ref.read(settingsProvider.notifier);
      switch (channel) {
        case 'push':
          notifier.setPushNotifications(enabled);
          break;
        case 'email':
          notifier.setEmailNotifications(enabled);
          break;
        case 'mentions':
          notifier.setMentionNotifications(enabled);
          break;
        case 'tasks':
          notifier.setTaskUpdates(enabled);
          break;
        case 'sound':
          notifier.setSound(enabled);
          break;
        case 'vibrate':
          notifier.setVibrate(enabled);
          break;
        default:
          notifier.setNotificationsEnabled(enabled);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setNotificationPreference({
    required WidgetRef ref,
    required String type,
    required bool enabled,
  }) async {
    try {
      await toggleNotificationChannel(ref: ref, channel: type, enabled: enabled);
    } catch (e) {
      rethrow;
    }
  }

  // ── Theme & Appearance ───────────────────────────────────────────────────

  static Future<void> updateTheme({
    required WidgetRef ref,
    required String theme, // 'light', 'dark', 'auto'
  }) async {
    try {
      final mode = switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      ref.read(themeModeProvider.notifier).setThemeMode(mode);
      ref.read(settingsProvider.notifier).setDarkMode(mode == ThemeMode.dark);
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> updateLanguage({
    required WidgetRef ref,
    required String locale,
  }) async {
    try {
      ref.read(settingsProvider.notifier).setLocale(locale);
    } catch (_) {
      rethrow;
    }
  }

  // ── Privacy & Security ───────────────────────────────────────────────────

  static bool canManageSecurity(WidgetRef ref) {
    final current = ref.read(currentUserProvider).valueOrNull;
    return current != null;
  }

  static Future<void> enable2FA({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(authRepositoryProvider).send2FAEmailCode();
      ref.read(settingsProvider.notifier).setTwoFactorAuth(true);

      if (context.mounted) {
        AppToast.show(
          '2FA verification code sent',
          type: ToastType.success,
          context: context,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  static Future<void> disableSessions({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(authRepositoryProvider).logoutAllSessions();

      if (context.mounted) {
        AppToast.show(
          'All sessions terminated',
          type: ToastType.success,
          context: context,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  // ── Helper methods ───────────────────────────────────────────────────────

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
