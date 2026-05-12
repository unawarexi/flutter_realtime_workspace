import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/recording_repository.dart';

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository();
});

// Recording endpoints do not exist in the backend.
// This provider file is kept as a placeholder.
