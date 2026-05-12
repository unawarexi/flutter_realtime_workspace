import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

class AIRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> chat(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.aiChat, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await _api.get(ApiEndpoints.aiConversations);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final res = await _api.get(ApiEndpoints.aiConversation(id));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteConversation(String id) async {
    await _api.delete(ApiEndpoints.aiConversation(id));
  }

  Future<Map<String, dynamic>> ragQuery(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.aiRagQuery, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> ragIngest(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.aiRagIngest, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRagStatus() async {
    final res = await _api.get(ApiEndpoints.aiRagStatus);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTools() async {
    final res = await _api.get(ApiEndpoints.aiTools);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> executeTool(
      String name, Map<String, dynamic> parameters) async {
    final res = await _api.post(ApiEndpoints.aiToolExecute(name),
        data: parameters);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summarize(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.aiSummarize, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }
}
