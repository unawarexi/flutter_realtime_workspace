import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});

/// Search query state.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Global search results.
final searchResultsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return <String, dynamic>{};
  return ref.read(searchRepositoryProvider).globalSearch(query);
});

/// Resource-scoped search results (e.g. resource = 'users', 'meetings', 'tasks').
final resourceSearchProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, ({String resource, String query})>(
        (ref, params) {
  if (params.query.isEmpty) return Future.value([]);
  return ref
      .read(searchRepositoryProvider)
      .searchResource(params.resource, params.query);
});
