import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/store/search_provider.dart';

/// Business logic for the Search feature.
///
/// Orchestrates global search and resource-scoped search through
/// [searchRepositoryProvider]. UI calls these static methods.
class SearchUseCase {
  SearchUseCase._();

  // ── Global search ────────────────────────────────────────────────────────

  static void updateQuery(WidgetRef ref, String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  static void clearQuery(WidgetRef ref) {
    ref.read(searchQueryProvider.notifier).state = '';
  }

  // ── Resource-scoped search ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> searchResource({
    required BuildContext context,
    required WidgetRef ref,
    required String resource,
    required String query,
  }) async {
    try {
      return await ref
          .read(searchRepositoryProvider)
          .searchResource(resource, query);
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return [];
    }
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String resourceLabel(String resource) {
    switch (resource) {
      case 'users': return 'People';
      case 'projects': return 'Projects';
      case 'tasks': return 'Tasks';
      case 'meetings': return 'Meetings';
      case 'documents': return 'Documents';
      case 'channels': return 'Channels';
      case 'issues': return 'Issues';
      case 'tickets': return 'Tickets';
      default: return resource;
    }
  }

  static const List<String> searchableResources = [
    'users',
    'projects',
    'tasks',
    'meetings',
    'documents',
    'channels',
    'issues',
    'tickets',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
