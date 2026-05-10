import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/services/auth_service.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/login.dart';

class SignOutSection extends StatelessWidget {
  final bool isDarkMode;
  const SignOutSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    const cardDark = Color(0xFF1E293B);
    const cardLight = Color(0xFFFFFFFF);
    const borderLight = Color(0xFFE2E8F0);
    const borderDark = Color(0xFF334155);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? cardDark : cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? borderDark : borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 20,
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        onTap: () async {
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const Authentication()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
