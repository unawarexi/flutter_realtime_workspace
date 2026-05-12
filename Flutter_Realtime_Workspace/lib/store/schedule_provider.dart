import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/schedule_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((_) {
  return ScheduleRepository();
});

final schedulesProvider = FutureProvider.autoDispose
    .family<List<ScheduleModel>, Map<String, dynamic>>((ref, filters) {
  return ref.watch(scheduleRepositoryProvider).getSchedules(
        workspaceId: filters['workspaceId'] as String?,
        from: filters['from'] as DateTime?,
        to: filters['to'] as DateTime?,
      );
});

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<ScheduleModel?>>(
        (ref) => ScheduleNotifier(ref));

class ScheduleNotifier extends StateNotifier<AsyncValue<ScheduleModel?>> {
  final Ref _ref;
  ScheduleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<ScheduleModel> createSchedule(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final schedule =
          await _ref.read(scheduleRepositoryProvider).createSchedule(body);
      state = AsyncValue.data(schedule);
      return schedule;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<ScheduleModel> updateSchedule(
      String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final schedule =
          await _ref.read(scheduleRepositoryProvider).updateSchedule(id, body);
      state = AsyncValue.data(schedule);
      return schedule;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelSchedule(String id) async {
    await _ref.read(scheduleRepositoryProvider).cancelSchedule(id);
  }

  Future<void> rsvp(String id, String response) async {
    await _ref.read(scheduleRepositoryProvider).rsvp(id, response);
  }
}
