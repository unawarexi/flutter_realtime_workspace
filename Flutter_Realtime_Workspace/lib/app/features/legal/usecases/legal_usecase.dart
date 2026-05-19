import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

// ── Domain models ─────────────────────────────────────────────────────────────

class LegalSection {
  final String title;
  final String content;

  const LegalSection({required this.title, required this.content});

  factory LegalSection.fromJson(Map<String, dynamic> json) {
    return LegalSection(
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }
}

class LegalDoc {
  final String title;
  final String effectiveDate;
  final String lastUpdated;
  final String version;
  final List<LegalSection> sections;

  const LegalDoc({
    required this.title,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.version,
    required this.sections,
  });

  factory LegalDoc.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = <LegalSection>[];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is Map<String, dynamic>) {
          sections.add(LegalSection.fromJson(s));
        }
      }
    }
    return LegalDoc(
      title: (json['title'] as String?) ?? 'Legal Document',
      effectiveDate: (json['effectiveDate'] as String?) ?? '',
      lastUpdated: (json['lastUpdated'] as String?) ?? '',
      version: (json['version'] as String?) ?? '1.0',
      sections: sections,
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class LegalRepository {
  final _api = ApiClient.instance;

  Future<LegalDoc> fetchTermsOfService() async {
    final res = await _api.get(ApiEndpoints.legalTerms);
    final data = res.data['data'] as Map<String, dynamic>;
    return LegalDoc.fromJson(data);
  }

  Future<LegalDoc> fetchPrivacyPolicy() async {
    final res = await _api.get(ApiEndpoints.legalPrivacy);
    final data = res.data['data'] as Map<String, dynamic>;
    return LegalDoc.fromJson(data);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final legalRepositoryProvider = Provider<LegalRepository>((_) {
  return LegalRepository();
});

final termsOfServiceProvider = FutureProvider<LegalDoc>((ref) async {
  return ref.read(legalRepositoryProvider).fetchTermsOfService();
});

final privacyPolicyProvider = FutureProvider<LegalDoc>((ref) async {
  return ref.read(legalRepositoryProvider).fetchPrivacyPolicy();
});
