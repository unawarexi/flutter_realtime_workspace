import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/feedback_model.dart';

class FeedbackRepository {
  final _api = ApiClient.instance;

  Future<FeedbackModel> submitFeedback(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.feedbacks, data: body);
    return FeedbackModel.fromJson(res.data['data']);
  }

  Future<List<FeedbackModel>> getFeedbacks({
    String? workspaceId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiEndpoints.feedbacks, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (type != null) 'type': type,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => FeedbackModel.fromJson(e)).toList();
  }

  Future<FeedbackModel> getFeedback(String id) async {
    final res = await _api.get(ApiEndpoints.feedback(id));
    return FeedbackModel.fromJson(res.data['data']);
  }

  Future<void> updateFeedbackStatus(String id, String status) async {
    await _api.put(ApiEndpoints.feedback(id), data: {'status': status});
  }

  Future<void> deleteFeedback(String id) async {
    await _api.delete(ApiEndpoints.feedback(id));
  }

  Future<void> respondToFeedback(String id, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.feedbackRespond(id), data: body);
  }
}
