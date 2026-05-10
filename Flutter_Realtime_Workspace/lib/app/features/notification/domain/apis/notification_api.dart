import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}fcm', 
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  String? _deviceToken;

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");
    final token = await user.getIdToken(true);
    if (token == null) throw Exception("Failed to retrieve ID token");
    return token;
  }

  Future<void> init({
    required void Function(RemoteMessage) onForegroundMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    // Request permissions if needed
    await _messaging.requestPermission();

    // Get device token
    _deviceToken = await _messaging.getToken();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    // Listen for notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }

  String? get deviceToken => _deviceToken;

  // Send notification to a single device
  Future<Response> sendNotification(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/send',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Send notification to multiple devices
  Future<Response> sendMultipleNotifications(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/send-multiple',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Send notification to topic
  Future<Response> sendTopicNotification(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/send-to-topic',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Subscribe devices to topic
  Future<Response> subscribeDevicesToTopic(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/subscribe',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Unsubscribe devices from topic
  Future<Response> unsubscribeDevicesFromTopic(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/unsubscribe',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Validate FCM token
  Future<Response> validateToken(Map<String, dynamic> data) async {
    final idToken = await _getToken();
    return _dio.post(
      '/validate-token',
      data: data,
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }

  // Get notification types
  Future<Response> getNotificationTypes() async {
    final idToken = await _getToken();
    return _dio.get(
      '/types',
      options: Options(headers: {"Authorization": "Bearer $idToken"}),
    );
  }
}
