import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/referral_model.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';

class ReferralUseCase {
  ReferralUseCase._();

  /// Calls the backend to regenerate the current user's invite code.
  /// Accepts both [Ref] (provider context) and [WidgetRef] (widget context).
  static Future<ReferralModel> regenerateInviteCode(WidgetRef ref) async {
    return ref.read(userRepositoryProvider).regenerateInviteCode();
  }
}
