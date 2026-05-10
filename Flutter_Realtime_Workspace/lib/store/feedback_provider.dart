import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/feedback_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/feedback_repository.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((_) {
  return FeedbackRepository();
});

final feedbackListProvider = FutureProvider.autoDispose
    .family<List<FeedbackModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(feedbackRepositoryProvider).getFeedbacks(
        workspaceId: filters['workspaceId'],
        type: filters['type'],
      );
});

final feedbackSubmitProvider =
    StateNotifierProvider<FeedbackSubmitNotifier, AsyncValue<FeedbackModel?>>(
        (ref) => FeedbackSubmitNotifier(ref));

class FeedbackSubmitNotifier extends StateNotifier<AsyncValue<FeedbackModel?>> {
  final Ref _ref;
  FeedbackSubmitNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<FeedbackModel> submit(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final feedback =
          await _ref.read(feedbackRepositoryProvider).submitFeedback(body);
      state = AsyncValue.data(feedback);
      return feedback;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
