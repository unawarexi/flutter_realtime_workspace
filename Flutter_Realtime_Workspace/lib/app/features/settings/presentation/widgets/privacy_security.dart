import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/referral_usecase.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/settings_usecase.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/delete_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/settings_provider.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

class PrivacySecurity extends ConsumerStatefulWidget {
  const PrivacySecurity({super.key});

  @override
  ConsumerState<PrivacySecurity> createState() => _PrivacySecurityState();
}

class _PrivacySecurityState extends ConsumerState<PrivacySecurity> {
  bool _isRegenerating = false;
  String? _regenerateError;
  String? _regenerateSuccess;

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final current = currentPasswordCtrl.text.trim();
              final next = newPasswordCtrl.text.trim();
              if (current.isEmpty || next.isEmpty) return;

              await SettingsUseCase.changePassword(
                context: context,
                ref: ref,
                oldPassword: current,
                newPassword: next,
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateInviteCode() async {
    setState(() {
      _isRegenerating = true;
      _regenerateError = null;
      _regenerateSuccess = null;
    });
    try {
      await ReferralUseCase.regenerateInviteCode(ref);
      setState(() {
        _regenerateSuccess = "Invite code regenerated!";
      });
      // Refresh user profile so UI shows the new code
      await ref.read(userRepositoryProvider).getProfile();
    } catch (e) {
      setState(() {
        _regenerateError = e.toString();
      });
    } finally {
      setState(() {
        _isRegenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors (same as account.dart)
    const primaryBlue = Color(0xFF1E40AF);
    const lightBlue = Color(0xFF3B82F6);
    const backgroundLight = Color(0xFFFAFBFC);
    const backgroundDark = Color(0xFF0F172A);
    const textPrimary = Color(0xFF0F172A);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    // Get user info from provider
    final userState = ref.watch(currentUserProvider);
    final userInfo = userState.valueOrNull?.toJson() ?? {};
    final permissionsLevel = userInfo['permissionsLevel'];
    final inviteCode = userInfo['inviteCode'];
    final inviteCodeExpiry = userInfo['inviteCodeExpiry'];

    return Scaffold(
      backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
      appBar: AppBar(
        backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
        elevation: 0,
        title: Text(
          "Privacy & Security",
          style: TextStyle(
            color: isDarkMode ? lightBlue : primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : textPrimary,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _sectionTitle("Security", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.fingerprint_rounded,
            title: "Biometric Login",
            subtitle: "Use fingerprint or face to unlock",
            value: settings.biometricLogin,
            onChanged: (v) => ref.read(settingsProvider.notifier).setBiometricLogin(v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.phonelink_lock_rounded,
            title: "Two-Factor Authentication",
            subtitle: "Extra layer of security",
            value: settings.twoFactorAuth,
            onChanged: (v) async {
              if (v) {
                await SettingsUseCase.enable2FA(context: context, ref: ref);
              }
              ref.read(settingsProvider.notifier).setTwoFactorAuth(v);
            },
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 18),
          _sectionTitle("Privacy", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.search_rounded,
            title: "Allow Search",
            subtitle: "Let others find you by email",
            value: settings.allowSearch,
            onChanged: (v) => ref.read(settingsProvider.notifier).setAllowSearch(v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.visibility_rounded,
            title: "Show Online Status",
            subtitle: "Display when you are active",
            value: settings.showOnlineStatus,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowOnlineStatus(v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.analytics_rounded,
            title: "Data Collection",
            subtitle: "Allow anonymous usage analytics",
            value: settings.dataCollection,
            onChanged: (v) => ref.read(settingsProvider.notifier).setDataCollection(v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 18),
          _sectionTitle("Account", isDarkMode, textPrimary),
          _actionTile(
            icon: Icons.lock_reset_rounded,
            title: "Change Password",
            onTap: _showChangePasswordDialog,
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _actionTile(
            icon: Icons.delete_forever_rounded,
            title: "Delete Account",
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => DeleteAccount(
                confirmWord: 'DELETE',
                isDarkMode: isDarkMode,
              ),
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),

          // --- ADMIN SECTION ---
          if (permissionsLevel == "admin") ...[
            const SizedBox(height: 18),
            _sectionTitle("Admin Controls", isDarkMode, textPrimary),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invite Code Management",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Current Code: ",
                          style: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        SelectableText(
                          inviteCode?.toString() ?? "N/A",
                          style: TextStyle(
                            color: isDarkMode ? lightBlue : primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (inviteCodeExpiry != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Expires: ${inviteCodeExpiry.toString()}",
                          style: TextStyle(
                            color:
                                isDarkMode ? Colors.white54 : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isRegenerating ? null : _regenerateInviteCode,
                      icon: _isRegenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text("Regenerate Invite Code"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_regenerateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _regenerateError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    if (_regenerateSuccess != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _regenerateSuccess!,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Add more admin-only controls here as needed
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDarkMode, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2, top: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : textPrimary,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
    required Color primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: primaryBlue,
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14, color: isDarkMode ? Colors.white54 : Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }
}
