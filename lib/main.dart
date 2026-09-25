import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';
import 'core/network/cookie_jar_factory.dart';
import 'features/notifications/data/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final cookieJar = await createCookieJar();
  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

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
