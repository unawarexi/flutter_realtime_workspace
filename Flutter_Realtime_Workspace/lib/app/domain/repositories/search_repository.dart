import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

class SearchRepository {
  final _api = ApiClient.instance;

  /// Global search across all resources.
  Future<Map<String, dynamic>> globalSearch(String query) async {
    final res = await _api.get(ApiEndpoints.search, queryParameters: {'q': query});
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Search within a specific resource type (e.g. 'users', 'meetings', 'tasks').
  Future<List<Map<String, dynamic>>> searchResource(
      String resource, String query) async {
    final res = await _api.get(
      ApiEndpoints.searchResource(resource),
      queryParameters: {'q': query},
    );
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }
}
