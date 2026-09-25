import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Subscribes to foreground FCM messages and presents them in-app.
///
/// The OS does not display notifications for messages received while the app
/// is in the foreground, so this widget surfaces them itself. It is mounted
/// from `MaterialApp.builder` (above the Navigator), so it shows an in-app
/// banner through the app's [ScaffoldMessengerState] rather than a route.
class ForegroundNotificationListener extends ConsumerStatefulWidget {
  const ForegroundNotificationListener({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  /// The app's root `ScaffoldMessenger` key, used to show the banner.
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  final Widget child;

  @override
  ConsumerState<ForegroundNotificationListener> createState() =>
      _ForegroundNotificationListenerState();
}

class _ForegroundNotificationListenerState
    extends ConsumerState<ForegroundNotificationListener> {
  StreamSubscription<RemoteMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    // Wired on app start; the stream is empty when Firebase is unconfigured.
    _subscription = ref.read(fcmServiceProvider).onMessage.listen(_present);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _present(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final text = [
      if (title != null && title.isNotEmpty) title,
      if (body != null && body.isNotEmpty) body,
    ].join('\n');

    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
