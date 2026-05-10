import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/auth/auth_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:sign_button/sign_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_navigiation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

class GithubAuthentication extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final Function(String)? onAuthError;

  const GithubAuthentication({
    super.key,
    this.onAuthSuccess,
    this.onAuthError,
  });

  @override
  State<GithubAuthentication> createState() => _GithubAuthenticationState();
}

class _GithubAuthenticationState extends State<GithubAuthentication> {
  bool _isLoading = false;

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
                buttonType: ButtonType.github,
                onPressed: _isLoading ? null : () => _handleGithubSignIn(ref),
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

  Future<void> _handleGithubSignIn(WidgetRef ref) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    debugPrint('[GithubAuthentication] Starting GitHub sign-in...');
    try {
      final UserCredential userCredential =
          await AuthService.signInWithGithub();
      debugPrint(
          '[GithubAuthentication] GitHub sign-in successful. User: ${userCredential.user?.uid}');
      if (mounted) {
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.success,
          message: 'Successfully signed in with GitHub!',
          actionLabel: "Continue",
        );
        widget.onAuthSuccess?.call();
        await _navigateToHome(ref, userCredential.user!);
      }
    } catch (e) {
      debugPrint('[GithubAuthentication] GitHub sign-in error: $e');
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        widget.onAuthError?.call(errorMessage);
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.failure,
          message: errorMessage,
          actionLabel: "Try Again",
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
      debugPrint('[GithubAuthentication] GitHub sign-in flow ended.');
    }
  }

  Future<void> _navigateToHome(WidgetRef ref, User user) async {
    debugPrint(
        '[GithubAuthentication] Navigating to home with user: ${user.uid}');
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
      debugPrint('[GithubAuthentication] Navigation error: $e');
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
