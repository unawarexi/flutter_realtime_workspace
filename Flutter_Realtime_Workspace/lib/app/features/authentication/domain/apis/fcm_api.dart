import 'package:dio/dio.dart';

class FcmApi {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'http://192.168.172.155:5000/api/v1//fcm/send';

  static Future<void> send2FACode({required String fcmToken, required String code}) async {
    try {
      await _dio.post(
        _baseUrl,
        data: {
          'fcmToken': fcmToken,
          'code': code,
        },
      );
    } catch (e) {
      // Handle error as needed
      rethrow;
    }
  }
}
