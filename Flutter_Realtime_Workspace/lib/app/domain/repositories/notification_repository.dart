import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

/// Push notification repository — interacts with the backend FCM push routes.
/// In-app notification routes do not exist in the backend at this time.
class NotificationRepository {
  final _api = ApiClient.instance;

  Future<void> subscribeDevice(
      {required String token, required String platform}) async {
    await _api.post(ApiEndpoints.notificationSubscribe, data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unsubscribeDevice(String token) async {
    await _api.post(ApiEndpoints.notificationUnsubscribe,
        data: {'token': token});
  }

  Future<void> send(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.notificationSend, data: body);
  }

  Future<void> sendToTopic(String topic, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.notificationSendTopic,
        data: {'topic': topic, ...body});
  }
}
