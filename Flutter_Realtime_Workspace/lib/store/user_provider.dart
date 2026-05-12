import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/user_repository.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Update user profile and sync with auth state.
final updateProfileProvider = Provider<
    Future<UserModel> Function({String? fullName, String? bio})>((ref) {
  return ({String? fullName, String? bio}) async {
    final user = await ref.read(userRepositoryProvider).updateProfile(
          fullName: fullName,
          bio: bio,
        );
    ref.read(currentUserProvider.notifier).setUser(user);
    return user;
  };
});

/// Update avatar and sync with auth state.
final updateAvatarProvider =
    Provider<Future<UserModel> Function(String filePath)>((ref) {
  return (String filePath) async {
    final user = await ref.read(userRepositoryProvider).updateAvatar(filePath);
    ref.read(currentUserProvider.notifier).setUser(user);
    return user;
  };
});

/// All workspace users — used for participant selection sheets.
final allUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return ref.read(userRepositoryProvider).getUsers();
});


/// Fetch a user's public profile by ID.
final userInfoByIdProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) => ref.read(userRepositoryProvider).getUserById(userId),
);
