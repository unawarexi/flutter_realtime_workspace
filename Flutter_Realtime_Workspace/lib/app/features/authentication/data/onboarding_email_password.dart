import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/auth/auth_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_navigiation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

// Sign In with Email and Password
Future<UserCredential> signInWithEmailAndPassword(
    String email, String password) async {
  return await AuthService.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Sign Up with Email and Password
Future<UserCredential> signUpWithEmailAndPassword(
    String email, String password) async {
  return await AuthService.signUpWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Forgot Password
Future<void> sendPasswordResetEmail(String email) async {
  await AuthService.sendPasswordResetEmail(email);
}

// Show Auth Confirmation Dialog
Future<void> showAuthConfirmation(
  BuildContext context, {
  required AuthConfirmationStatus status,
  required String message,
  required String actionLabel,
}) async {
  await AuthConfirmationScreen.show(
    context,
    status: status,
    message: message,
    actionLabel: actionLabel,
  );
}

// Navigate to Home
Future<void> navigateToHome(
    BuildContext context, User user, WidgetRef ref) async {
  try {
    // Set Firebase user in provider
    final firebaseUser = UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      photoURL: user.photoURL ?? '',
      phoneNumber: user.phoneNumber ?? '',
    );
    ref.read(userProvider.notifier).setFirebaseUser(firebaseUser);

    // Fetch and set user info from custom API
    await ref.read(userProvider.notifier).fetchUserInfo();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavigationBarWidget(),
        ),
      );
    }
  } catch (e) {
    debugPrint('Navigation error: $e');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavigationBarWidget(),
        ),
      );
    }
  }
}
