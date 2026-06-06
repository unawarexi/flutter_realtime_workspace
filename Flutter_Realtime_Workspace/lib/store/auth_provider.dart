import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/app/domain/models/auth_session_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/auth_repository.dart';
import 'package:flutter_realtime_workspace/store/notification_provider.dart';
import 'package:flutter_realtime_workspace/core/network/account_guard.dart';
import 'package:flutter_realtime_workspace/core/services/notification_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/core/services/websocket.dart';

/// Auth repository singleton provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Check if a user needs to complete the profile setup
final needsProfileSetupProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  // A user needs profile setup if profileCompletion is 0 OR they don't belong to any org/tenant yet
  return user.profileCompletion == 0 || (user.orgId == null && user.tenantId == null);
});

// ─── Utility Providers ───────────────────────────────────────────────────────

/// Stream of Firebase auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Whether user has completed OAuth sign-in successfully.
/// This gates biometric auth — biometrics can only be enabled after this is true.
final hasOAuthSessionProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

/// Current app user profile (fetched after login).
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
  return CurrentUserNotifier(ref);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;
  CurrentUserNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    // Try loading cached user immediately for fast startup
    final cached = _ref.read(authRepositoryProvider).getCachedUser();
    if (cached != null) {
      state = AsyncValue.data(cached);
      _connectWebSocket(cached);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final session = await _ref.read(authRepositoryProvider).signInWithGoogle();
      if (session == null || session.user == null) {
        // User cancelled the sign-in flow — restore idle state
        state = const AsyncValue.data(null);
        return;
      }
      final user = session.user!;
      state = AsyncValue.data(user);
      _registerFcmToken();
      _connectWebSocket(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGithub() async {
    state = const AsyncValue.loading();
    try {
      final session = await _ref.read(authRepositoryProvider).signInWithGithub();
      final user = session.user;
      if (user == null) {
        state = AsyncValue.error('No user returned from backend session.', StackTrace.current);
        return;
      }
      state = AsyncValue.data(user);
      _registerFcmToken();
      _connectWebSocket(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AuthSessionModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final session = await _ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(email, password);

      if (session.user != null) {
        state = AsyncValue.data(session.user);
        _registerFcmToken();
        _connectWebSocket(session.user);
      } else {
        state = const AsyncValue.data(null);
      }
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(
    String email,
    String password,
    String fullName, {
    bool termsAccepted = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(authRepositoryProvider)
          .signUpWithEmailPassword(email, password, fullName, termsAccepted: termsAccepted);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Verify email with 6-digit OTP. The backend activates the account and
  /// issues a JWT session automatically — user does not need to re-login.
  Future<void> verifyEmailOtp(String email, String otp) async {
    state = const AsyncValue.loading();
    try {
      final session = await _ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(email, otp);
      if (session.user != null) {
        state = AsyncValue.data(session.user);
        _registerFcmToken();
        _connectWebSocket(session.user!);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Fetch latest user profile from backend.
  Future<void> fetchProfile() async {
    try {
      final user = await _ref.read(authRepositoryProvider).getMe();
      state = AsyncValue.data(user);
    } catch (e, st) {
      // 404 from /auth/me means the account was deleted from the backend
      if (e is DioException && e.response?.statusCode == 404) {
        state = const AsyncValue.data(null);
        AccountGuard.trigger();
        return;
      }
      // If fetch fails but we have cached data, keep it
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    await _ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncValue.data(null);
  }

  /// Verify 2FA code after login. Completes the auth session.
  Future<void> verify2FA({
    required String tempToken,
    required String otp,
    required String method,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _ref.read(authRepositoryProvider).verify2FA(
            tempToken: tempToken,
            otp: otp,
            method: method,
          );
      if (session.user != null) {
        state = AsyncValue.data(session.user);
        _registerFcmToken();
        _connectWebSocket(session.user!);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void setUser(UserModel user) => state = AsyncValue.data(user);

  /// Register FCM token with the backend for push notifications.
  Future<void> _registerFcmToken() async {
    if (!Platform.isAndroid) return;

    try {
      final token = await NotificationService.instance.getToken();
      if (token != null) {
        await _ref.read(notificationRepositoryProvider).registerDevice(
          token: token,
          platform: 'android',
        );
      }
      // Listen for token refresh and re-register automatically
      NotificationService.instance.onTokenRefresh.listen((newToken) async {
        try {
          await _ref.read(notificationRepositoryProvider).registerDevice(
            token: newToken,
            platform: 'android',
          );
        } catch (e) {
          debugPrint('FCM token refresh registration failed: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Connect WebSocket and register user for personal notification room.
  void _connectWebSocket(UserModel? user) {
    if (user == null) return;
    final ws = WebSocketService();
    ws.connect().then((_) {
      ws.setUserId(user.id);
    });
  }

  void clear() => state = const AsyncValue.data(null);
}

/// Biometric lock preference — only meaningful when hasOAuthSession is true.
final biometricEnabledProvider = StateProvider<bool>((ref) {
  return LocalStorageService.biometricEnabled;
});

