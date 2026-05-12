import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/auth/google_signin.dart';
import 'package:flutter_realtime_workspace/core/auth/github_signin.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/core/db/hive.dart';
import 'package:flutter_realtime_workspace/app/domain/models/auth_session_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class AuthRepository {
  final _firebaseAuth = FirebaseAuth.instance;
  final _api = ApiClient.instance;

  User? get firebaseUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => firebaseUser != null;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Register user with custom backend auth.
  Future<void> signUpWithEmailPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      await _api.post(
        ApiEndpoints.authRegister,
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        },
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Login with email/password using custom backend auth.
  Future<AuthSessionModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final res = await _api.post(
        ApiEndpoints.authLogin,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );
      final session = AuthSessionModel.fromJson(res.data['data']);
      await _persistSession(session);
      return session;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> _persistSession(AuthSessionModel session) async {
    if (session.user != null &&
        session.accessToken != null &&
        session.refreshToken != null) {
      await SecureStorageService.saveSession(
        userId: session.user!.id,
        accessToken: session.accessToken!,
        refreshToken: session.refreshToken!,
      );
      await HiveService.write(
        HiveService.user,
        'current_user',
        session.user!.toJson(),
      );
    }
  }

  /// Sign in with Google OAuth → Firebase → Backend social login.
  /// Returns null when user cancels the sign-in flow.
  Future<AuthSessionModel?> signInWithGoogle() async {
    try {
      final cred = await GoogleSignInService.signIn();
      if (cred == null) return null;
      return _syncWithBackend(cred);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Sign in with GitHub OAuth → Firebase → Backend social login.
  Future<AuthSessionModel> signInWithGithub() async {
    try {
      final cred = await GithubSignInService.signIn();
      return _syncWithBackend(cred);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// After Firebase social auth, exchange idToken with backend.
  Future<AuthSessionModel> _syncWithBackend(UserCredential cred) async {
    final idToken = await cred.user!.getIdToken();
    final res = await _api.post(
      ApiEndpoints.signIn,
      data: {'idToken': idToken},
    );
    final session = AuthSessionModel.fromJson(res.data['data']);
    await _persistSession(session);
    return session;
  }

  /// Get current user profile from backend.
  Future<UserModel> getMe() async {
    final res = await _api.get(ApiEndpoints.me);
    final user = UserModel.fromJson(res.data['data']);
    await HiveService.write(HiveService.user, 'current_user', user.toJson());
    return user;
  }

  /// Get cached user (offline fallback).
  UserModel? getCachedUser() {
    final cached = HiveService.read<Map>(HiveService.user, 'current_user');
    if (cached != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(cached));
    }
    return null;
  }

  /// Sign out from Firebase + backend.
  Future<void> signOut() async {
    final refreshToken = await SecureStorageService.getRefreshToken();

    // Fire-and-forget backend signout — don't block local cleanup
    _api.post(
      ApiEndpoints.signOut,
      data: {
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
    ).catchError((_) => throw _);

    await Future.wait([
      GoogleSignInService.signOut(),
      GithubSignInService.signOut(),
      SecureStorageService.clearAll(),
      HiveService.clearBox(HiveService.user),
      HiveService.clearBox(HiveService.projects),
      HiveService.clearBox(HiveService.teams),
      HiveService.clearBox(HiveService.tasks),
      HiveService.clearBox(HiveService.notifications),
      HiveService.clearBox(HiveService.schedule),
      HiveService.clearBox(HiveService.settings),
    ]);
  }

  /// Delete user account.
  Future<void> deleteAccount() async {
    await _api.delete(ApiEndpoints.deleteAccount);
    await Future.wait([
      _firebaseAuth.currentUser?.delete() ?? Future.value(),
      SecureStorageService.clearAll(),
      HiveService.clearBox(HiveService.user),
      HiveService.clearBox(HiveService.projects),
      HiveService.clearBox(HiveService.teams),
      HiveService.clearBox(HiveService.tasks),
      HiveService.clearBox(HiveService.notifications),
      HiveService.clearBox(HiveService.schedule),
      HiveService.clearBox(HiveService.settings),
    ]);
  }
}
