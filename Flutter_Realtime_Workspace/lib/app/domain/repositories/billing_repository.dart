import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/subscription_model.dart';

class BillingRepository {
  final _api = ApiClient.instance;

  Future<SubscriptionModel?> getSubscription() async {
    final res = await _api.get(ApiEndpoints.subscription);
    final data = res.data['data'];
    if (data == null) return null;
    return SubscriptionModel.fromJson(data);
  }

  Future<SubscriptionModel> updateSubscription(
      Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.subscription, data: body);
    return SubscriptionModel.fromJson(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final res = await _api.get(ApiEndpoints.billingInvoices);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    final res = await _api.get(ApiEndpoints.billingInvoice(id));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsage() async {
    final res = await _api.get(ApiEndpoints.billingUsage);
    return res.data['data'] as Map<String, dynamic>;
  }
}
