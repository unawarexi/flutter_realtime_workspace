import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:flutter_realtime_workspace/core/db/hive.dart';
import 'package:flutter_realtime_workspace/core/services/notification_service.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/core/auth/google_signin.dart';
import 'package:flutter_realtime_workspace/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  await dotenv.load(fileName: '.env');

  // Parallel init for independent services
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    HiveService.init(),
    LocalStorageService.init(),
  ]);

  // Initialize Google Sign-In (must be after Firebase.initializeApp)
  await GoogleSignInService.init();

  // FCM background handler + local notifications
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  // Prune expired cache entries
  await HiveService.pruneExpired();

  // Lock orientation on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style — handled per-screen by AppBar theme systemOverlayStyle
  // and AnnotatedRegion on non-AppBar screens.

  const app = ProviderScope(
    child: TeamSpotApp(),
  );

  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment(
          'SENTRY_DSN',
          defaultValue: '',
        );
        options.tracesSampleRate = 0.2;
        options.environment = 'production';
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}