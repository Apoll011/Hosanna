import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/local_notification_service.dart';
import '../domain/notification_route.dart';

/// Subscribes to foreground FCM messages and re-posts them as proper OS
/// notifications.
///
/// On Android, FCM suppresses the system notification while the app is in the
/// foreground.  This widget intercepts those messages and dispatches them via
/// [LocalNotificationService] so they appear as a standard heads-up banner at
/// the top of the screen — exactly the same as when the app is in the
/// background — instead of the previous in-app SnackBar popup at the bottom.
///
/// The widget is mounted from `MaterialApp.builder` (above the Navigator) so
/// it is always active regardless of which route is showing.
class ForegroundNotificationListener extends ConsumerStatefulWidget {
  const ForegroundNotificationListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ForegroundNotificationListener> createState() =>
      _ForegroundNotificationListenerState();
}

class _ForegroundNotificationListenerState
    extends ConsumerState<ForegroundNotificationListener> {
  StreamSubscription<RemoteMessage>? _subscription;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(fcmServiceProvider).onMessage.listen(_present);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _present(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    // Build a payload so that tapping the notification can open the right
    // screen (handled by the existing onNotificationTap stream in FcmService).
    final location = notificationTapLocation(message.data);

    await LocalNotificationService.instance.show(
      id: _nextId++,
      title: title,
      body: body,
      payload: location,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
