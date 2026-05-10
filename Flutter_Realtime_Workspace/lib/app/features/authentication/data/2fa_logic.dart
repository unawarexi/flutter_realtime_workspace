// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_realtime_workspace/app/features/authentication/domain/apis/fcm_api.dart';

// class TwoFALogic {
//   static final _firestore = FirebaseFirestore.instance;
//   static final _auth = FirebaseAuth.instance;

//   // Generate a 6-digit code
//   static String generateCode() {
//     final rand = Random.secure();
//     return (rand.nextInt(900000) + 100000).toString();
//   }

//   // Save code and expiry to Firestore
//   static Future<void> saveCodeToFirestore(String uid, String code, DateTime expiry) async {
//     await _firestore.collection('2fa_codes').doc(uid).set({
//       'code': code,
//       'expiresAt': expiry.toUtc(),
//     });
//   }

//   // Send code via backend FCM API
//   static Future<void> sendCodeNotification(String code) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//     final fcmToken = await FirebaseMessaging.instance.getToken();
//     if (fcmToken == null) return;
//     await FcmApi.send2FACode(fcmToken: fcmToken, code: code);
//   }

//   // Generate, save, and send code
//   static Future<void> generateAndSend2FACode(String uid) async {
//     final code = generateCode();
//     final expiry = DateTime.now().add(const Duration(minutes: 5));
//     await saveCodeToFirestore(uid, code, expiry);
//     await sendCodeNotification(code);
//   }

//   // Verify code
//   static Future<bool> verifyCode(String uid, String inputCode) async {
//     final doc = await _firestore.collection('2fa_codes').doc(uid).get();
//     if (!doc.exists) return false;
//     final data = doc.data()!;
//     final code = data['code'] as String;
//     final expiresAt = (data['expiresAt'] as Timestamp).toDate();
//     if (DateTime.now().isAfter(expiresAt)) return false;
//     return code == inputCode;
//   }

//   // Get expiry for countdown
//   static Future<DateTime?> getExpiry(String uid) async {
//     final doc = await _firestore.collection('2fa_codes').doc(uid).get();
//     if (!doc.exists) return null;
//     final data = doc.data()!;
//     return (data['expiresAt'] as Timestamp).toDate();
//   }
// }
