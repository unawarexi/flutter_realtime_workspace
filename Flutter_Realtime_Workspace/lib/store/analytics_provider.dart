import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

/// Dashboard overview data.
final analyticsDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(analyticsRepositoryProvider).getDashboard();
});

/// Generate a report with optional params.
final analyticsReportProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, Map<String, dynamic>>((ref, params) {
  return ref.read(analyticsRepositoryProvider).generateReport(params);
});
