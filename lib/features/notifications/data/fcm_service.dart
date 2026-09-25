import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_route.dart';

/// Handles messages received while the app is terminated/backgrounded.
///
/// Must be a top-level function annotated for the background isolate. It only
/// needs to exist for the platform to wake the isolate; routing happens when
/// the user taps the notification (`onMessageOpenedApp`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('FCM background handler: init failed: $e');
  }
}

/// Thin, defensive wrapper around `firebase_messaging`.
///
/// This is the **only** place in the app that talks to Firebase Cloud
/// Messaging. The auth layer stays agnostic of Firebase: it merely accepts an
/// optional `fcm` token string and persists it on the Better Auth session.
///
/// Every call is guarded because Firebase may be unconfigured (no
/// `firebase_options.dart` values / no `google-services.json`) or unsupported
/// on the current platform. In that case calls resolve to `null` / an empty
/// stream instead of throwing, so the app keeps working without push support.
class FcmService {
  FcmService();

  bool _available = false;

  /// Whether FCM is usable on this platform **and** Firebase initialized
  /// successfully. When false, [getToken] always returns `null` and
  /// [onTokenRefresh] never emits.
  bool get isAvailable => _available;

  /// Marks FCM as usable. Called by `main()` after `Firebase.initializeApp`
  /// succeeds; nothing here is Firebase-specific, which keeps the service
  /// constructible (and testable) without the plugin.
  void markAvailable() {
    _available = true;
  }

  /// The current device's FCM registration token, or `null` when FCM is
  /// unavailable or the token cannot be fetched.
  Future<String?> getToken() async {
    if (!_available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FcmService: getToken failed: $e');
      return null;
    }
  }

  /// Emits a new token whenever Firebase rotates the registration token.
  ///
  /// Yields nothing while FCM is unavailable. The auth layer listens to this
  /// once and pushes the new token onto the *current* session.
  Stream<String> get onTokenRefresh {
    if (!_available) return const Stream<String>.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Messages received while the app is in the foreground.
  ///
  /// A foreground message is **not** shown by the OS, so the app presents it
  /// itself (see `ForegroundNotificationListener`). Yields nothing while FCM
  /// is unavailable.
  Stream<RemoteMessage> get onMessage {
    if (!_available) return const Stream<RemoteMessage>.empty();
    return FirebaseMessaging.onMessage;
  }

  /// go_router locations for notifications the user tapped while the app was
  /// backgrounded (or running). Emits only payloads we know how to open.
  Stream<String> get onNotificationTap {
    if (!_available) return const Stream<String>.empty();
    return FirebaseMessaging.onMessageOpenedApp
        .map((message) => notificationTapLocation(message.data))
        .where((location) => location != null)
        .cast<String>();
  }

  /// The location for the notification that cold-started the app, if any.
  ///
  /// Must be read once on startup; returns null when the app was launched
  /// normally or the payload points nowhere we know.
  Future<String?> initialNotificationLocation() async {
    if (!_available) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return null;
      return notificationTapLocation(message.data);
    } catch (e) {
      debugPrint('FcmService: getInitialMessage failed: $e');
      return null;
    }
  }

  /// Asks the OS for notification permission (independent of Better Auth's
  /// `session.notify`). Returns true when permission was granted (or when the
  /// platform does not require an explicit prompt).
  Future<bool> requestPermission() async {
    if (!_available) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FcmService: requestPermission failed: $e');
      return false;
    }
  }
}
