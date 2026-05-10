import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/auth/auth_service.dart';

class LoginUseCase {
	const LoginUseCase();

	Future<UserCredential> call({
		required String email,
		required String password,
	}) {
		return AuthService.signInWithEmailAndPassword(
			email: email,
			password: password,
		);
	}
}
