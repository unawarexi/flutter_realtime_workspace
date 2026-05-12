import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

class AnalyticsRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _api.get(ApiEndpoints.analyticsDashboard);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateReport(
      Map<String, dynamic> params) async {
    final res = await _api.get(ApiEndpoints.analyticsReportsGenerate,
        queryParameters: params);
    return res.data['data'] as Map<String, dynamic>;
  }
}
