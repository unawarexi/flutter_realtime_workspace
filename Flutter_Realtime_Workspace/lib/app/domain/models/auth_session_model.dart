import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';

class AuthSessionModel {
  final String? accessToken;
  final String? refreshToken;
  final String? sessionId;
  final bool requires2FA;
  final String? method;
  final String? tempToken;
  final UserModel? user;

  const AuthSessionModel({
    this.accessToken,
    this.refreshToken,
    this.sessionId,
    this.requires2FA = false,
    this.method,
    this.tempToken,
    this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      sessionId: json['sessionId'] as String?,
      requires2FA: json['requires2FA'] == true,
      method: json['method'] as String?,
      tempToken: json['tempToken'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
