import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/auth/auth_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_navigiation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_realtime_workspace/app/components/common/auth_confirmation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';

class BiometricAuthentication extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final Function(String)? onAuthError;
  final bool showSettings;

  const BiometricAuthentication({
    super.key,
    this.onAuthSuccess,
    this.onAuthError,
    this.showSettings = true,
  });

  @override
  State<BiometricAuthentication> createState() =>
      _BiometricAuthenticationState();
}

class _BiometricAuthenticationState extends State<BiometricAuthentication> {
  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricSettings();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _isBiometricAvailable = isAvailable && isDeviceSupported;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final isEnabled = await StorageService.isBiometricEnabled();
      setState(() {
        _isBiometricEnabled = isEnabled;
      });
    } catch (e) {
      debugPrint('Error loading biometric settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Consumer(
      builder: (context, ref, _) {
        // Minimal UI for login (showSettings == false)
        if (!_isBiometricAvailable) {
          return Card(
            elevation: 0,
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 44,
                    color: isDarkMode ? TColors.error : Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Biometric authentication is not available on this device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode
                          ? TColors.textSecondaryDark
                          : TColors.textSecondaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!widget.showSettings) {
          // Minimal, modern fingerprint card for login
          return GestureDetector(
            onTap: _isLoading ? null : () => _handleBiometricSignIn(ref),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.10)
                        : Colors.grey.withOpacity(0.06),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.fingerprint,
                            size: 38,
                            color: isDarkMode
                                ? TColors.lightBlue
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in with biometrics',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Secure biometric authentication',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? TColors.textSecondaryDark
                          : TColors.textTertiaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ...existing full settings UI...
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.10)
                    : Colors.grey.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _getBiometricIcon(),
                      size: 26,
                      color: isDarkMode
                          ? TColors.lightBlue
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric Authentication',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getBiometricDescription(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? TColors.textSecondaryDark
                                : TColors.textTertiaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Biometric Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _handleBiometricSignIn(ref),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _getBiometricIcon(),
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _isLoading
                        ? 'Authenticating...'
                        : 'Sign In with Biometrics',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? TColors.buttonPrimary
                        : TColors.buttonPrimaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              if (widget.showSettings) ...[
                const SizedBox(height: 16),
                Divider(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),

                // Biometric Settings
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enable biometric authentication',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isBiometricEnabled,
                      onChanged: _handleBiometricToggle,
                      activeColor: isDarkMode
                          ? TColors.buttonPrimary
                          : TColors.buttonPrimaryLight,
                      inactiveThumbColor: isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFFE2E8F0),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  'When enabled, you can use ${_getBiometricTypeString()} to quickly sign in to your account.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode
                        ? TColors.textSecondaryDark
                        : TColors.textTertiaryLight,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  String _getBiometricDescription() {
    final types = <String>[];
    if (_availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Touch ID');
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }

    if (types.isEmpty) {
      return 'Secure biometric authentication';
    } else if (types.length == 1) {
      return 'Sign in with ${types.first}';
    } else {
      return 'Sign in with ${types.join(' or ')}';
    }
  }

  String _getBiometricTypeString() {
    final types = <String>[];
    if (_availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('fingerprint');
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      types.add('iris');
    }

    if (types.isEmpty) {
      return 'biometrics';
    } else if (types.length == 1) {
      return types.first;
    } else {
      return types.join(' or ');
    }
  }

  Future<void> _handleBiometricSignIn(WidgetRef ref) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    debugPrint('[BiometricAuthentication] Starting biometric sign-in...');
    try {
      final success = await AuthService.signInWithBiometrics();
      debugPrint(
          '[BiometricAuthentication] Biometric sign-in result: $success');
      if (success && mounted) {
        // Show success message
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.success,
          message: 'Successfully authenticated with biometrics!',
          actionLabel: "Continue",
        );

        // Call success callback
        widget.onAuthSuccess?.call();

        // Navigate to home screen
        await _navigateToHome(ref);
      }
    } catch (e) {
      debugPrint('[BiometricAuthentication] Biometric sign-in error: $e');
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
      debugPrint('[BiometricAuthentication] Biometric sign-in flow ended.');
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    try {
      if (value) {
        // Test biometric authentication before enabling
        final success = await AuthService.signInWithBiometrics();
        if (success) {
          await AuthService.enableBiometricAuth(true);
          setState(() {
            _isBiometricEnabled = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication enabled'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        await AuthService.enableBiometricAuth(false);
        setState(() {
          _isBiometricEnabled = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication disabled'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToHome(WidgetRef ref) async {
    try {
      // Get user data from storage
      final userData = await StorageService.getUserData();
      if (userData != null) {
        // Set Firebase user in provider
        ref
            .read(userProvider.notifier)
            .setFirebaseUser(UserModel.fromMap(userData));
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
      } else {
        throw Exception(
            'No user data found. Please sign in with another method first.');
      }
    } catch (e) {
      if (mounted) {
        await AuthConfirmationScreen.show(
          context,
          status: AuthConfirmationStatus.failure,
          message: e.toString().replaceFirst('Exception: ', ''),
          actionLabel: "OK",
        );
      }
    }
  }
}
