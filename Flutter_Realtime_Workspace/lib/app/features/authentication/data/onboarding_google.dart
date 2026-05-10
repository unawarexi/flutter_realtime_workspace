import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/auth/auth_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:sign_button/sign_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_navigiation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

class GoogleAuthentication extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final Function(String)? onAuthError;

  const GoogleAuthentication({
    super.key,
    this.onAuthSuccess,
    this.onAuthError,
  });

  @override
  State<GoogleAuthentication> createState() => _GoogleAuthenticationState();
}

class _GoogleAuthenticationState extends State<GoogleAuthentication> {
  bool _isLoading = false;

  // Use Consumer to access Riverpod providers
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          padding: const EdgeInsets.only(top: 10),
          height: 60,
          child: Stack(
            children: [
              SignInButton.mini(
                buttonType: ButtonType.google,
                onPressed: _isLoading ? null : () => _handleGoogleSignIn(ref),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Google
      final UserCredential userCredential =
          await AuthService.signInWithGoogle();

      if (mounted) {
        // Show success message
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.success,
          message: 'Successfully signed in with Google!',
          actionLabel: "Continue",
        );

        // Call success callback
        widget.onAuthSuccess?.call();

        // Navigate to home screen
        await _navigateToHome(ref, userCredential.user!);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');

        // Call error callback
        widget.onAuthError?.call(errorMessage);

        // Show error message
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.failure,
          message: errorMessage,
          actionLabel: "Try Again",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToHome(WidgetRef ref, User user) async {
    try {
      // Set Firebase user in provider
      ref.read(userProvider.notifier).setFirebaseUser(
            UserModel(
              uid: user.uid,
              displayName: user.displayName ?? 'User',
              email: user.email ?? '',
              photoURL: user.photoURL ?? '',
              phoneNumber: user.phoneNumber ?? '',
            ),
          );
      // Fetch and set user info from custom API
      await ref.read(userProvider.notifier).fetchUserInfo();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationBarWidget(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationBarWidget(),
          ),
        );
      }
    }
  }
}
