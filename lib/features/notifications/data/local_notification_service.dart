import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Channel ID and name used for all in-app FCM foreground notifications.
const String _kChannelId = 'hosanna_default';
const String _kChannelName = 'Hosanna';
const String _kChannelDescription = 'Push notifications from Hosanna';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] that initialises the
/// plugin once and exposes a simple [show] method.
///
/// Only Android and iOS are configured; on other platforms the calls are
/// no-ops so the app keeps running without crashing.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Initialises the plugin and, on Android, creates the notification channel
  /// that is also referenced in `AndroidManifest.xml`.
  ///
  /// Safe to call multiple times; subsequent calls are ignored.
  Future<void> init() async {
    if (_initialised) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings);

      // Create the notification channel on Android 8+.  This is idempotent;
      // Android ignores duplicate-channel calls for an already-registered id.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _kChannelId,
              _kChannelName,
              description: _kChannelDescription,
              importance: Importance.high,
            ),
          );

      _initialised = true;
    } catch (e) {
      debugPrint('LocalNotificationService: init failed: $e');
    }
  }

  /// Shows a notification with [title] and [body].
  ///
  /// [id] is a unique integer per notification; pass different values to show
  /// multiple notifications at once.  On Android the icon is `ic_notification`
  /// — a white monochrome drawable that adapts to the system theme.
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    String? payload,
  }) async {
    if (!_initialised) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('LocalNotificationService: show failed: $e');
    }
  }
}
