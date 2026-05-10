import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/template_model.dart';

class TemplateRepository {
  final _api = ApiClient.instance;

  Future<List<TemplateModel>> getTemplates(
      {Map<String, dynamic>? query}) async {
    final res = await _api.get(ApiEndpoints.templates,
        queryParameters: query);
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => TemplateModel.fromJson(e)).toList();
  }

  Future<TemplateModel> getTemplate(String id) async {
    final res = await _api.get(ApiEndpoints.template(id));
    return TemplateModel.fromJson(res.data['data']);
  }

  Future<TemplateModel> createTemplate(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.templates, data: body);
    return TemplateModel.fromJson(res.data['data']);
  }

  Future<TemplateModel> updateTemplate(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.template(id), data: body);
    return TemplateModel.fromJson(res.data['data']);
  }

  Future<void> deleteTemplate(String id) async {
    await _api.delete(ApiEndpoints.template(id));
  }

  Future<Map<String, dynamic>> previewTemplate(
      String id, Map<String, dynamic> variables) async {
    final res = await _api.post(ApiEndpoints.templatePreview(id),
        data: variables);
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }
}
