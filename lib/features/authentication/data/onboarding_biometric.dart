import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingBiometric {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate(BuildContext context) async {
    try {
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to set up biometric login.',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometricAuthenticated', true);
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication failed.')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return false;
    }
  }

  Future<void> setDevicePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('devicePasswordSet', true);
  }
}
