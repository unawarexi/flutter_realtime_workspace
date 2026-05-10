import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/issue_repository.dart';

final issueRepositoryProvider = Provider<IssueRepository>((_) {
  return IssueRepository();
});

/// Issues for a project.
final issuesProvider = FutureProvider.autoDispose
    .family<List<IssueModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(issueRepositoryProvider).getIssues(
        projectId: filters['projectId'],
        workspaceId: filters['workspaceId'],
        assigneeId: filters['assigneeId'],
        status: filters['status'],
        priority: filters['priority'],
      );
});

/// Issue detail.
final issueDetailProvider =
    FutureProvider.autoDispose.family<IssueModel, String>((ref, id) {
  return ref.watch(issueRepositoryProvider).getIssue(id);
});

/// Issue CRUD notifier.
final issueNotifierProvider =
    StateNotifierProvider<IssueNotifier, AsyncValue<IssueModel?>>(
        (ref) => IssueNotifier(ref));

class IssueNotifier extends StateNotifier<AsyncValue<IssueModel?>> {
  final Ref _ref;
  IssueNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<IssueModel> createIssue(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final issue = await _ref.read(issueRepositoryProvider).createIssue(body);
      state = AsyncValue.data(issue);
      return issue;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<IssueModel> updateIssue(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final issue =
          await _ref.read(issueRepositoryProvider).updateIssue(id, body);
      state = AsyncValue.data(issue);
      return issue;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteIssue(String id) async {
    await _ref.read(issueRepositoryProvider).deleteIssue(id);
  }
}
