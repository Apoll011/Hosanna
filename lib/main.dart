import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/analytics/analytics.dart';
import 'core/analytics/analytics_error_handler.dart';
import 'core/config/app_config.dart';
import 'core/db/database.dart';
import 'core/network/cookie_jar_factory.dart';
import 'features/notifications/data/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final cookieJar = await createCookieJar();
  final prefs = await SharedPreferences.getInstance();

  // Set up global error reporting before anything else can throw.
  AnalyticsErrorHandler.setupFlutterErrorHandling();

  // Initialise PostHog when a key is provided via --dart-define.
  final appConfig = AppConfig.instance;
  if (appConfig.postHogApiKey.isNotEmpty) {
    await AnalyticsService.instance.init(
      apiKey: appConfig.postHogApiKey,
      host: appConfig.postHogHost,
    );
  }

  // Firebase uses the native config: `android/app/google-services.json` (read
  // by the Google Services Gradle plugin) and `ios/Runner/GoogleService-
  // Info.plist`, so no options are passed here. It is best-effort: when the
  // config is missing, initialization throws and the app still runs — just
  // without push notifications.
  final fcm = FcmService();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    fcm.markAvailable();
  } catch (e) {
    debugPrint('Firebase not configured; push notifications disabled: $e');
  }

  // Track app launch after all services are initialised.
  await AnalyticsService.instance.track(const AppLaunched());

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        cookieJarProvider.overrideWithValue(cookieJar),
        sharedPreferencesProvider.overrideWithValue(prefs),
        fcmServiceProvider.overrideWithValue(fcm),
      ],
      child: const HosannaApp(),
    ),
  );
}
