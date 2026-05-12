import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/notification_repository.dart';
import 'package:flutter_realtime_workspace/core/services/websocket.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Unread notification count (for badges) — updated via WebSocket events.
final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);

/// Listens to real-time notification events via WebSocket and increments
/// the unread badge counter. In-app notification REST routes do not exist
/// in the backend; state is maintained client-side from WebSocket pushes.
class NotificationWebSocketListener {
  final Ref _ref;
  StreamSubscription? _wsSub;

  NotificationWebSocketListener(this._ref) {
    _wsSub = WebSocketService().stream('notification:received').listen((data) {
      _ref.read(unreadNotificationCountProvider.notifier).state++;
    });
  }

  void dispose() => _wsSub?.cancel();
}
