import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:msal_auth/msal_auth.dart';
import 'storage_service.dart' show StorageService, LocalAuthProvider;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Stream to listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Initialize authentication state
  static Future<void> initializeAuth() async {
    try {
      // Check if user is already signed in
      final user = currentUser;
      if (user != null) {
        await _saveUserTokensAndData(user, LocalAuthProvider.unknown);
      }
    } catch (e) {
      debugPrint('Failed to initialize auth: $e');
    }
  }

  // Google Sign In
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Force refresh token after sign-in
      await userCredential.user?.getIdToken(true);

      // Save tokens and user data
      await _saveUserTokensAndData(
          userCredential.user!, LocalAuthProvider.google);

      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // GitHub Sign In
  static Future<UserCredential> signInWithGithub() async {
    debugPrint('[AuthService] Initiating GitHub sign-in...');
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();

      // Add scopes for additional user info
      githubProvider.addScope('user:email');
      githubProvider.addScope('read:user');

      debugPrint('[AuthService] Calling Firebase signInWithProvider for GitHub...');
      final UserCredential userCredential =
          await _auth.signInWithProvider(githubProvider);

      debugPrint('[AuthService] Firebase signInWithProvider succeeded. User: ${userCredential.user?.uid}');

      // Force refresh token after sign-in
      await userCredential.user?.getIdToken(true);

      // Save tokens and user data
      await _saveUserTokensAndData(
          userCredential.user!, LocalAuthProvider.github);

      debugPrint('[AuthService] GitHub sign-in completed and user data saved.');
      return userCredential;
    } catch (e) {
      debugPrint('[AuthService] GitHub sign-in failed: $e');
      throw Exception('GitHub sign in failed: $e');
    }
  }

  //------------------------------------------- Microsoft Sign In
  static Future<UserCredential> signInWithMicrosoft() async {
    try {
      // Configure MSAL
      const String clientId =
          'your-client-id-from-azure'; // <-- Set your Azure client ID
      const String authority = 'https://login.microsoftonline.com/common';
      const List<String> scopes = ['user.read', 'openid', 'profile', 'email'];

      final pca = await SingleAccountPca.create(
        clientId: clientId,
        androidConfig: AndroidConfig(
          configFilePath: 'assets/msal_config.json',
          redirectUri: authority,
        ),
        appleConfig: AppleConfig(
          authority: authority,
          // Change authority type to 'b2c' for business to customer flow.
          authorityType: AuthorityType.aad,
          // Change broker if you need. Applicable only for iOS platform.
          broker: Broker.msAuthenticator,
        ),
      );

      // Acquire token interactively
      final result = await pca.acquireToken(
        scopes: scopes,
      );

      // Create Microsoft OAuth credential for Firebase
      final OAuthCredential credential =
          OAuthProvider("microsoft.com").credential(
        accessToken: result.accessToken,
        // idToken is not always available from MSAL, so only pass if present
        idToken: result.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Force refresh token after sign-in
      await userCredential.user?.getIdToken(true);

      // Save tokens and user data
      await _saveUserTokensAndData(
          userCredential.user!, LocalAuthProvider.microsoft);

      return userCredential;
    } on MsalException catch (e) {
      throw Exception('Microsoft sign in failed: $e - ${e.message}');
    } catch (e) {
      throw Exception('Microsoft sign in failed: $e');
    }
  }

  // Email & Password Sign In
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Force refresh token after sign-in
      await userCredential.user?.getIdToken(true);

      // Save tokens and user data
      await _saveUserTokensAndData(
          userCredential.user!, LocalAuthProvider.emailPassword);

      print('SignIn: User UID: ${userCredential.user?.uid}, DisplayName: ${userCredential.user?.displayName}, Email: ${userCredential.user?.email}, PhotoURL: ${userCredential.user?.photoURL}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Email sign in failed: $e');
    }
  }

  // Email & Password Sign Up
  static Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName, // keep for compatibility, but not used
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // No display name or photoURL set for email/password sign up

      // Force refresh token after sign-up
      await userCredential.user?.getIdToken(true);

      // Save tokens and user data
      await _saveUserTokensAndData(
          userCredential.user!, LocalAuthProvider.emailPassword);

      print('SignUp: User UID: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Email sign up failed: $e');
    }
  }

  // Biometric Authentication
  static Future<bool> signInWithBiometrics() async {
    try {
      // Check if biometrics are available
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        throw Exception(
            'Biometric authentication is not available on this device');
      }

      // Check available biometric types
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        throw Exception(
            'No biometric authentication methods are set up on this device');
      }

      // Authenticate with biometrics
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        // Check if user was previously authenticated
        final userData = await StorageService.getUserData();
        if (userData == null) {
          throw Exception(
              'No previous authentication found. Please sign in with another method first.');
        }

        await StorageService.saveAuthProvider(LocalAuthProvider.biometric);
        return true;
      } else {
        throw Exception('Biometric authentication failed');
      }
    } catch (e) {
      throw Exception('Biometric authentication error: $e');
    }
  }

  // Enable/Disable Biometric Authentication
  static Future<void> enableBiometricAuth(bool enable) async {
    try {
      if (enable) {
        // Verify biometric authentication works
        final success = await signInWithBiometrics();
        if (success) {
          await StorageService.setBiometricEnabled(true);
        }
      } else {
        await StorageService.setBiometricEnabled(false);
      }
    } catch (e) {
      throw Exception('Failed to update biometric settings: $e');
    }
  }

  // Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    return await StorageService.isBiometricEnabled();
  }

  // Password Reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update Password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Update Profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();

      // Update stored user data
      final updatedUser = _auth.currentUser!;
      await _saveUserData(updatedUser);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      // Sign out from all providers
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear stored data
      await StorageService.clearAllData();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Delete Account
  static Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.delete();
      await StorageService.clearAllData();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before deleting your account');
      }
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Re-authenticate user (required for sensitive operations)
  static Future<void> reauthenticateWithCredential(
      AuthCredential credential) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Re-authentication failed: $e');
    }
  }

  // Get fresh authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await StorageService.getValidToken();
    } catch (e) {
      debugPrint('Failed to get auth token: $e');
      return null;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isAuthenticated();
  }

  // Private helper methods
  static Future<void> _saveUserTokensAndData(
      User user, LocalAuthProvider provider) async {
    try {
      // Get ID token
      final idTokenResult = await user.getIdTokenResult();

      // Save tokens
      await StorageService.saveAuthTokens(
        accessToken: idTokenResult.token,
        idToken: idTokenResult.token,
        expiryTime: idTokenResult.expirationTime,
      );

      // Save user data
      await _saveUserData(user);

      // Save auth provider
      await StorageService.saveAuthProvider(provider);
    } catch (e) {
      debugPrint('Failed to save user tokens and data: $e');
    }
  }

  static Future<void> _saveUserData(User user) async {
    print('Saving user data: UID: ${user.uid}, Email: ${user.email}, Phone: ${user.phoneNumber}');
    await StorageService.saveUserData(
      uid: user.uid,
      email: user.email ?? '',
      // No displayName or photoURL for email/password
      phoneNumber: user.phoneNumber,
    );
  }

  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
