import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

/// All form-logic, payload building and submission for the user-info onboarding.
/// The UI layer calls [submitUserInfo] and reacts to [UserInfoFormState].
class UserInfoUseCase {
  UserInfoUseCase._();

  // ─── Validators ────────────────────────────────────────────────────────────

  static String? requiredField(String? value, [String fieldName = 'Field']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validateInviteCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Invite code is required to join an organisation';
    return null;
  }

  // ─── Payload Builder ───────────────────────────────────────────────────────

  /// Builds a clean, non-empty map from all form controller values.
  static Map<String, dynamic> buildPayload({
    // Section 1
    required String fullName,
    required String displayName,
    required String profilePictureUrl,
    required String email,
    required String phone,
    // Section 2
    required String roleTitle,
    required String department,
    required String? workType,
    required String timezone,
    required String workingHoursStart,
    required String workingHoursEnd,
    // Section 3 — Organisation
    required String companyName,
    required String companyWebsite,
    required String industry,
    required String? teamSize,
    required String officeLocation,
    required String orgSlug,
    // Section 4 — Workspace / Join
    required String inviteCode,
    required String teamProjectName,
    required String? permissionsLevel,
    // Section 5
    required String interestsSkills,
    required String bio,
    required String linkedIn,
    required String github,
  }) {
    final data = <String, dynamic>{};

    void add(String key, String value) {
      if (value.isNotEmpty) data[key] = value;
    }

    void addOptional(String key, String? value) {
      if (value != null && value.isNotEmpty) data[key] = value;
    }

    // Section 1
    add('fullName', fullName.trim());
    add('displayName', displayName.trim());
    add('profilePicture', profilePictureUrl.trim());
    add('email', email.trim());
    add('phoneNumber', phone.trim());

    // Section 2
    add('roleTitle', roleTitle.trim());
    add('department', department.trim());
    addOptional('workType', workType);
    add('timezone', timezone.trim());
    final wStart = workingHoursStart.trim();
    final wEnd = workingHoursEnd.trim();
    if (wStart.isNotEmpty || wEnd.isNotEmpty) {
      data['workingHours'] = {
        if (wStart.isNotEmpty) 'start': wStart,
        if (wEnd.isNotEmpty) 'end': wEnd,
      };
    }

    // Section 3 — Organisation
    add('companyName', companyName.trim());
    add('orgSlug', orgSlug.trim());
    add('companyWebsite', companyWebsite.trim());
    add('industry', industry.trim());
    addOptional('teamSize', teamSize);
    add('officeLocation', officeLocation.trim());

    // Section 4 — Workspace / Join
    add('inviteCode', inviteCode.trim());
    add('teamProjectName', teamProjectName.trim());
    addOptional('permissionsLevel', permissionsLevel);

    // Section 5
    final skills = interestsSkills
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (skills.isNotEmpty) data['interestsSkills'] = skills;
    add('bio', bio.trim());
    final ln = linkedIn.trim();
    final gh = github.trim();
    if (ln.isNotEmpty || gh.isNotEmpty) {
      data['socialLinks'] = {
        if (ln.isNotEmpty) 'linkedIn': ln,
        if (gh.isNotEmpty) 'github': gh,
      };
    }

    return data;
  }

  // ─── Submission ────────────────────────────────────────────────────────────

  /// Saves profile + optional avatar, then navigates to the main app.
  /// Returns [true] on success so the caller can reset loading state.
  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> payload,
    required String? imagePath,
  }) async {
    try {
      if (imagePath != null) {
        await ref.read(updateAvatarProvider)(imagePath);
      }
      await ref.read(updateProfileProvider)(
        fullName: payload['fullName'] as String?,
        bio: payload['bio'] as String?,
      );
      if (!context.mounted) return false;
      context.go('/home');
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      context.showToast('Failed to save: $e', type: ToastType.error);
      return false;
    }
  }
}
