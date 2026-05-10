// Core Riverpod providers — wraps singleton services so any widget or
// Notifier can depend on an interface rather than a concrete singleton.
// Add feature-level providers in their respective feature/providers/ files.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/network/connectivity_service.dart';
import 'package:flutter_realtime_workspace/core/network/account_guard.dart';
import 'package:flutter_realtime_workspace/core/services/websocket.dart';

// ── Networking ───────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>(
  (_) => ApiClient.instance,
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService.instance,
);

/// Emits [true] when the device is online, [false] when offline.
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onConnectivityChanged,
);

// ── Auth guard ───────────────────────────────────────────────────────────────

final accountGuardProvider = Provider<AccountGuard>(
  (_) => AccountGuard.instance,
);

// ── Real-time ────────────────────────────────────────────────────────────────

final webSocketProvider = Provider<WebSocketService>(
  (_) => WebSocketService.instance,
);

// NOTE: StorageService and HiveService expose only static methods —
//       consume them directly without a provider.
