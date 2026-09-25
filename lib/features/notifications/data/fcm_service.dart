import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
