import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Custom scheme used by the Android launcher shortcuts.
///
/// Declared in `AndroidManifest.xml` and used by
/// `android/app/src/main/res/xml/shortcuts.xml`, so long-pressing the launcher
/// icon can open the library, the services list, or the next service.
const String kLauncherLinkScheme = 'hosanna';

/// Maps a `hosanna://…` launcher link to a go_router location.
///
/// Returns null for links that aren't ours (or that we don't know how to
/// open). Both the host form (`hosanna://songs`) and the path form
/// (`hosanna:///songs`) are accepted, since either can reach the app.
String? launcherLinkLocation(Uri uri) {
  if (uri.scheme != kLauncherLinkScheme) return null;
  final segments = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((segment) => segment.isNotEmpty),
  ];
  return switch (segments.join('/')) {
    'songs' => '/songs',
    'services' => '/services',
    // Resolved to a real service once the database is ready (see
    // NextServicePage) — static shortcuts can't know a service id.
    'services/next' => '/services/next',
    _ => null,
  };
}

/// Subscribes to incoming `hosanna://` links, calling [onLocation] with the
/// go_router location each one maps to.
///
/// [AppLinks.uriLinkStream] also replays the link the app was launched with,
/// so a single subscription covers both cold and warm starts.
StreamSubscription<Uri> listenToLauncherLinks(
  void Function(String location) onLocation,
) {
  return AppLinks().uriLinkStream.listen(
    (uri) {
      final location = launcherLinkLocation(uri);
      if (location != null) onLocation(location);
    },
    onError: (Object error) =>
        debugPrint('Failed to read launcher link: $error'),
  );
}
