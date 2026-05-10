import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/global/user_provider.dart';
import 'package:flutter_realtime_workspace/core/services/auth_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/login.dart';
import 'package:local_auth/local_auth.dart';

class DeleteAccount extends ConsumerStatefulWidget {
  final String confirmWord;
  final bool isDarkMode;

  const DeleteAccount({
    super.key,
    required this.confirmWord,
    required this.isDarkMode,
  });

  @override
  ConsumerState<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<DeleteAccount> {
  bool _agreeTerms = false;
  bool _agreeRecovery = false;
  final TextEditingController _deleteConfirmController =
      TextEditingController();
  bool _isDeleting = false;
  bool _biometricSuccess = false;

  @override
  void dispose() {
    _deleteConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final confirmWord = widget.confirmWord;
    const borderDark = Color(0xFF334155);
    const borderLight = Color(0xFFE2E8F0);
    const cardDark = Color(0xFF1E293B);
    const cardLight = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const lightBlue = Color(0xFF3B82F6);
    const primaryBlue = Color(0xFF1E40AF);

    final canDelete = (_agreeTerms &&
        _agreeRecovery &&
        (_deleteConfirmController.text.trim() == confirmWord ||
            _biometricSuccess));

    return StatefulBuilder(
      builder: (context, setModalState) {
        return SingleChildScrollView(
          // Prevent overflow when keyboard is up
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isDeleting
                      ? null
                      : () => _triggerFingerprint(setModalState),
                  child: Icon(
                    Icons.fingerprint,
                    color: _biometricSuccess
                        ? Colors.green
                        : (isDarkMode ? Colors.white70 : Colors.deepPurple),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 38),
                const SizedBox(height: 10),
                const Text(
                  "Delete Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This action is irreversible. All your data, teams, and settings will be permanently deleted. Please read and confirm the following:",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _agreeTerms,
                  onChanged: (v) =>
                      setModalState(() => _agreeTerms = v ?? false),
                  title: const Text("I understand this cannot be undone.",
                      style: TextStyle(fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _agreeRecovery,
                  onChanged: (v) =>
                      setModalState(() => _agreeRecovery = v ?? false),
                  title: const Text("I have exported or recovered my data.",
                      style: TextStyle(fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : textPrimary,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: "Type "),
                        TextSpan(
                          text: confirmWord,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " to confirm:"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _deleteConfirmController,
                  enabled: !_isDeleting && !_biometricSuccess,
                  decoration: InputDecoration(
                    hintText: confirmWord,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white24 : Colors.black26,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDarkMode ? borderDark : borderLight,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : textPrimary,
                    fontSize: 13,
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 10),
                FutureBuilder<bool>(
                  future: StorageService.isBiometricEnabled(),
                  builder: (context, snap) {
                    if (snap.data == true && !_biometricSuccess) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.fingerprint,
                              color: Colors.white),
                          label: const Text("Use Fingerprint to Confirm"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isDeleting
                              ? null
                              : () => _triggerFingerprint(setModalState),
                        ),
                      );
                    }
                    if (_biometricSuccess) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text("Fingerprint verified",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!canDelete || _isDeleting)
                          ? (isDarkMode
                              ? const Color(0xFF23272F)
                              : Colors.grey[300])
                          : Colors.redAccent,
                      foregroundColor: (!canDelete || _isDeleting)
                          ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: (!canDelete || _isDeleting)
                        ? null
                        : () async {
                            setModalState(() => _isDeleting = true);
                            try {
                              await ref
                                  .read(userProvider.notifier)
                                  .deleteUserInfo();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const Authentication()),
                                  (route) => false,
                                );
                                context.showToast(
                                  'Account deleted successfully.',
                                  type: ToastType.success,
                                  gravity: ToastGravity.TOP,
                                );
                              }
                            } catch (e) {
                              context.showToast(
                                'Delete failed: $e',
                                type: ToastType.error,
                                gravity: ToastGravity.TOP,
                              );
                            } finally {
                              setModalState(() => _isDeleting = false);
                            }
                          },
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Delete Account",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed:
                      _isDeleting ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerFingerprint(StateSetter setModalState) async {
    setModalState(() => _isDeleting = true);
    try {
      final localAuth = LocalAuthentication();
      final didAuth = await localAuth.authenticate(
        localizedReason: 'Authenticate to delete your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuth) {
        setModalState(() {
          _biometricSuccess = true;
          _deleteConfirmController.text = widget.confirmWord;
        });
      }
    } catch (e) {
      context.showToast(
        'Biometric failed: $e',
        type: ToastType.error,
        gravity: ToastGravity.TOP,
      );
    } finally {
      setModalState(() => _isDeleting = false);
    }
  }
}
