import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/user_repository.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ─── UserState ───────────────────────────────────────────────────────────────

class UserState {
  final Map<String, dynamic>? userInfo;
  final bool isLoading;

  const UserState({this.userInfo, this.isLoading = false});

  UserState copyWith({Map<String, dynamic>? userInfo, bool? isLoading}) =>
      UserState(
        userInfo: userInfo ?? this.userInfo,
        isLoading: isLoading ?? this.isLoading,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  final Ref _ref;

  UserNotifier(this._ref) : super(const UserState()) {
    _init();
  }

  void _init() {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      state = UserState(userInfo: user.toJson());
    }
  }

  Future<void> fetchAllUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _ref.read(userRepositoryProvider).getUsers();
      final usersJson = users.map((u) => u.toJson()).toList();
      state = UserState(
        userInfo: {...?state.userInfo, 'users': usersJson},
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>?> fetchUserByInviteCodeOrEmail({
    String? inviteCode,
    String? email,
  }) async {
    final query = email ?? inviteCode;
    if (query == null) return null;
    final users = await _ref.read(userRepositoryProvider).getUsers(query: query);
    return users.isNotEmpty ? users.first.toJson() : null;
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) => UserNotifier(ref));

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
