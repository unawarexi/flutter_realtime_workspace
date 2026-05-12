import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/meeting_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/meeting_repository.dart';
import 'package:flutter_realtime_workspace/core/db/hive.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository();
});

/// All meetings list (with optional status filter).
final meetingsProvider = FutureProvider.family
    .autoDispose<List<MeetingModel>, String?>((ref, status) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final cacheKey = 'meetings_${status ?? "all"}';

  try {
    final meetings =
        await ref.read(meetingRepositoryProvider).listMeetings(status: status);
    await HiveService.write(
      HiveService.schedule, cacheKey,
      meetings.map((m) => m.toJson()).toList(),
    );
    return meetings;
  } catch (e) {
    final cached = HiveService.read<List>(HiveService.schedule, cacheKey);
    if (cached != null) {
      return cached
          .map((e) => MeetingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    rethrow;
  }
});

/// Single meeting by ID.
final meetingByIdProvider =
    FutureProvider.family.autoDispose<MeetingModel, String>((ref, id) {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);
  return ref.read(meetingRepositoryProvider).getById(id);
});

/// Active meeting state — managed entirely client-side after join.
final activeMeetingProvider =
    StateNotifierProvider<ActiveMeetingNotifier, MeetingRoomState>((ref) {
  return ActiveMeetingNotifier(ref);
});

class MeetingRoomState {
  final MeetingModel? meeting;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isScreenSharing;
  final bool isHandRaised;
  final bool isRecording;
  final Duration elapsed;

  const MeetingRoomState({
    this.meeting,
    this.isMicOn = true,
    this.isCameraOn = true,
    this.isScreenSharing = false,
    this.isHandRaised = false,
    this.isRecording = false,
    this.elapsed = Duration.zero,
  });

  bool get isInMeeting => meeting != null;

  MeetingRoomState copyWith({
    MeetingModel? meeting,
    bool? isMicOn,
    bool? isCameraOn,
    bool? isScreenSharing,
    bool? isHandRaised,
    bool? isRecording,
    Duration? elapsed,
  }) =>
      MeetingRoomState(
        meeting: meeting ?? this.meeting,
        isMicOn: isMicOn ?? this.isMicOn,
        isCameraOn: isCameraOn ?? this.isCameraOn,
        isScreenSharing: isScreenSharing ?? this.isScreenSharing,
        isHandRaised: isHandRaised ?? this.isHandRaised,
        isRecording: isRecording ?? this.isRecording,
        elapsed: elapsed ?? this.elapsed,
      );
}

class ActiveMeetingNotifier extends StateNotifier<MeetingRoomState> {
  final Ref _ref;
  Timer? _elapsedTimer;

  ActiveMeetingNotifier(this._ref) : super(const MeetingRoomState());

  Future<void> joinMeeting(String meetingId, {String? password}) async {
    final repo = _ref.read(meetingRepositoryProvider);
    final meeting = await repo.join(meetingId, password: password);
    state = MeetingRoomState(meeting: meeting);
    _startElapsedTimer();
  }

  Future<void> rsvp(String meetingId, String response) async {
    await _ref.read(meetingRepositoryProvider).rsvp(meetingId, response);
  }

  void toggleMic() => state = state.copyWith(isMicOn: !state.isMicOn);
  void toggleCamera() => state = state.copyWith(isCameraOn: !state.isCameraOn);
  void toggleScreenShare() =>
      state = state.copyWith(isScreenSharing: !state.isScreenSharing);
  void toggleHandRaise() =>
      state = state.copyWith(isHandRaised: !state.isHandRaised);
  void toggleRecording() =>
      state = state.copyWith(isRecording: !state.isRecording);

  void leaveMeeting() {
    _elapsedTimer?.cancel();
    state = const MeetingRoomState();
    _clearMeetingCacheAndRefresh();
  }

  void _clearMeetingCacheAndRefresh() {
    for (final key in ['meetings_all', 'meetings_LIVE', 'meetings_ENDED']) {
      HiveService.delete(HiveService.schedule, key);
    }
    _ref.invalidate(meetingsProvider(null));
    _ref.invalidate(meetingsProvider('LIVE'));
    _ref.invalidate(meetingsProvider('ENDED'));
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
