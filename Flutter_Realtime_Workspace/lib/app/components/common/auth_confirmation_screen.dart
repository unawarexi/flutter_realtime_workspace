import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

enum AuthConfirmationStatus { success, failure }

class AuthConfirmationScreen extends StatelessWidget {
  final AuthConfirmationStatus status;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AuthConfirmationScreen({
    super.key,
    required this.status,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required AuthConfirmationStatus status,
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AuthConfirmationScreen(
        status: status,
        message: message,
        onAction: onAction,
        actionLabel: actionLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == AuthConfirmationStatus.success;
    final Color accent = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final isDarkMode = THelperFunctions.isDarkMode(context);

    // Colors matching home.dart
    final bgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final shadowColor = (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.12);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.95,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24), // reduced
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // reduced
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24), // reduced
                  color: bgColor.withOpacity(isDarkMode ? 0.98 : 0.98),
                  border: Border.all(
                    color: borderColor.withOpacity(0.9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 16, // reduced
                      offset: const Offset(0, 6), // reduced
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20), // reduced
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emblem at the top center
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.13),
                            blurRadius: 16, // reduced
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                        radius: 26, // reduced
                        child: Padding(
                          padding: const EdgeInsets.all(5.0), // reduced
                          child: Image.asset(
                            TImages.lightEmblem,
                            height: 28, // reduced
                            width: 28, // reduced
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // reduced
                    // Animated status icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isSuccess
                          ? Icon(Icons.check_circle_rounded, key: const ValueKey('success'), color: accent, size: 32) // reduced
                          : Icon(Icons.error_rounded, key: const ValueKey('fail'), color: accent, size: 32), // reduced
                    ),
                    const SizedBox(height: 10), // reduced
                    // Message
                    Text(
                      isSuccess ? "Success!" : "Oops!",
                      style: TextStyle(
                        fontSize: 16, // reduced
                        fontWeight: FontWeight.bold,
                        color: accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6), // reduced
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, // reduced
                        color: isDarkMode ? Colors.white.withOpacity(0.92) : const Color(0xFF0F172A).withOpacity(0.92),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16), // reduced
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // reduced
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10), // reduced
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13, // reduced
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).maybePop();
                          if (onAction != null) onAction!();
                        },
                        child: Text(actionLabel ?? (isSuccess ? "Continue" : "Try Again")),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

