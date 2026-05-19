import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_realtime_workspace/firebase_options.dart';
import 'package:flutter_realtime_workspace/router/app_router.dart';
import 'package:flutter/widgets.dart';

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase may already be initialized in some app lifecycles.
  }
  await NotificationService.instance.handleBackgroundRemoteMessage(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _callkitEventsBound = false;

  // ── Android Notification Channels ──

  static const _meetingChannel = AndroidNotificationChannel(
    'meeting_reminders',
    'Meeting Reminders',
    description: 'Notifications for upcoming and starting meetings',
    importance: Importance.high,
    enableVibration: true,
  );

  static const _callChannel = AndroidNotificationChannel(
    'incoming_calls',
    'Incoming Calls',
    description: 'Incoming call notifications with ringtone and vibration',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
  );

  static const _chatChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    enableVibration: true,
  );

  static const _systemChannel = AndroidNotificationChannel(
    'system_notifications',
    'System Notifications',
    description: 'General system notifications, recording ready, etc.',
    importance: Importance.defaultImportance,
  );

  /// Initialize local notifications + FCM listeners + CallKit.
  Future<void> init() async {
    // Skip all notification initialization on iOS/macOS (no developer account required)
    if (Platform.isIOS || Platform.isMacOS) return;

    // --- Local notifications setup ---
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS/macOS local notification initialization is intentionally disabled.
    // const darwinInit = DarwinInitializationSettings(
    //   requestAlertPermission: true,
    //   requestBadgePermission: true,
    //   requestSoundPermission: true,
    // );
    const initSettings = InitializationSettings(
      android: androidInit,
      // iOS: darwinInit,
      // macOS: darwinInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android channels
    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_meetingChannel);
      await androidPlugin?.createNotificationChannel(_callChannel);
      await androidPlugin?.createNotificationChannel(_chatChannel);
      await androidPlugin?.createNotificationChannel(_systemChannel);
    }

    // --- FCM setup ---
    final messaging = FirebaseMessaging.instance;

    // iOS/macOS FCM permission request is intentionally disabled.
    // if (Platform.isIOS || Platform.isMacOS) {
    //   await messaging.requestPermission(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //     criticalAlert: true,
    //   );
    // }

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);

    // Handle notification tap when app is opened from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateFromMessage(initialMessage.data);
    }

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromMessage(message.data);
    });

    _bindCallkitEvents();
  }

  /// Get the FCM token for device registration.
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  /// Listen for token refresh.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  /// Route incoming FCM message to the right notification type.
  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    final isInstant = data['isInstant'] == 'true';

    // Incoming call → show CallKit (native call UI with ring + vibrate)
    if (type == 'MEETING_INVITE' && isInstant) {
      await _showIncomingCall(message);
      return;
    }

    // All other notifications → local notification with appropriate channel
    await _showLocalNotification(message);
  }

  /// Background isolate-safe handler.
  ///
  /// Keep this minimal: some plugins/channels (for example CallKit event
  /// streams) are not safe to use from background isolates on all devices.
  Future<void> handleBackgroundRemoteMessage(RemoteMessage message) async {
    if (!Platform.isAndroid) return;
    await _showLocalNotification(message);
  }

  /// Show an incoming call notification using local notifications (CallKit removed).
  Future<void> _showIncomingCall(RemoteMessage message) async {
    final data = message.data;
    final callId =
        (data['callId'] ?? message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final callerName =
        (data['callerName'] ?? data['title'] ?? message.notification?.title ?? 'Incoming Call')
            .toString();
    final handle = (data['handle'] ?? data['meetingCode'] ?? 'TeamSpot').toString();
    final isVideo = (data['isVideo']?.toString().toLowerCase() == 'true') ||
        (data['callType']?.toString().toLowerCase() == 'video');

    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'TeamSpot',
        handle: handle,
        type: isVideo ? 1 : 0,
        duration: 45000,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        extra: Map<String, dynamic>.from(data),
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0A0A0A',
          actionColor: '#4CAF50',
          textColor: '#FFFFFF',
          incomingCallNotificationChannelName: 'Incoming Calls',
          missedCallNotificationChannelName: 'Missed Calls',
          isShowCallID: false,
        ),
        ios: const IOSParams(
          iconName: 'AppIcon',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      ),
    );
  }

  /// Show a local notification with the right channel based on type.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final type = data['type'] ?? '';

    final title = notification?.title ?? data['title'] ?? 'TeamSpot';
    final body = notification?.body ?? data['body'] ?? '';

    // Pick channel based on notification type
    final channel = _channelForType(type);

    if (Platform.isAndroid) {
      await _local.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: type == 'CHAT_MESSAGE' ? Priority.high : Priority.defaultPriority,
            enableVibration: true,
            category: type == 'CHAT_MESSAGE'
                ? AndroidNotificationCategory.message
                : AndroidNotificationCategory.event,
          ),
          // iOS: const DarwinNotificationDetails(
          //   presentAlert: true,
          //   presentBadge: true,
          //   presentSound: true,
          // ),
        ),
        payload: jsonEncode(data),
      );
    }
    // else: do nothing for iOS
  }

  AndroidNotificationChannel _channelForType(String type) {
    switch (type) {
      case 'MEETING_INVITE':
        return _callChannel;
      case 'CHAT_MESSAGE':
        return _chatChannel;
      case 'MEETING_REMINDER':
      case 'MEETING_CANCELLED':
        return _meetingChannel;
      case 'RECORDING_READY':
      default:
        return _systemChannel;
    }
  }

  /// Handle notification tap — navigate to the right screen.
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromMessage(data);
    } catch (_) {}
  }

  /// Navigate based on notification data payload.
  void _navigateFromMessage(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'MEETING_INVITE':
        final meetingCode = data['meetingCode'] ?? data['code'];
        if (meetingCode != null) {
          appRouter.go('/join/$meetingCode');
        } else {
          appRouter.go('/meetings');
        }
        break;
      case 'CHAT_MESSAGE':
        final chatRoomId = data['chatRoomId'];
        if (chatRoomId != null) {
          appRouter.go('/chat/$chatRoomId');
        } else {
          appRouter.go('/chat');
        }
        break;
      case 'RECORDING_READY':
        appRouter.go('/recordings');
        break;
      case 'MEETING_REMINDER':
      case 'MEETING_CANCELLED':
        appRouter.go('/meetings');
        break;
      default:
        appRouter.go('/home');
    }
  }

  void _bindCallkitEvents() {
    if (_callkitEventsBound) return;
    _callkitEventsBound = true;

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      final body = event.body;
      final extra = body['extra'] as Map<dynamic, dynamic>?;
      final payload = <String, dynamic>{};
      if (extra != null) {
        for (final entry in extra.entries) {
          payload[entry.key.toString()] = entry.value;
        }
      }

      switch (event.event) {
        case Event.actionCallAccept:
          _navigateFromMessage(payload);
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          FlutterCallkitIncoming.endAllCalls();
          break;
        default:
          break;
      }
    });
  }
}
