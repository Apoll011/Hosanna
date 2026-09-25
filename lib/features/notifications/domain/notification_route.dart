import '../../../app/launcher_links.dart';

/// Maps an FCM message's `data` payload to a go_router location.
///
/// Kept pure (no Firebase types, no async) so the routing rules are trivially
/// unit-testable. Returns null when the payload does not point anywhere we
/// know how to open — the caller then simply leaves the user where they are.
///
/// Recognised payload shapes (all values are strings in FCM `data`):
///
///   1. An explicit destination in `url` / `link` / `location`, either
///      `hosanna://songs` (parsed like a launcher link), an `https://…/songs/1`
///      URL (its path is used), or an app path like `/services/abc`.
///   2. A `type` (+ optional `id` / `songId` / `serviceId`), e.g.
///      `{type: "song", id: "123"}` → `/songs/123`.
String? notificationTapLocation(Map<String, dynamic> data) {
  final explicit = _firstNonEmpty([
    data['url'],
    data['link'],
    data['location'],
  ]);
  if (explicit != null) {
    final uri = Uri.tryParse(explicit);
    if (uri != null && uri.hasScheme) {
      final fromLauncherLink = launcherLinkLocation(uri);
      if (fromLauncherLink != null) return fromLauncherLink;
      if (uri.path.isNotEmpty && uri.path != '/') return uri.path;
    } else if (explicit.startsWith('/')) {
      return explicit;
    }
  }

  final type = _firstNonEmpty([data['type']])?.toLowerCase();
  final id = _firstNonEmpty([data['id'], data['songId'], data['serviceId']]);

  return switch (type) {
    'song' || 'song_added' || 'song_updated' =>
      id != null ? '/songs/$id' : '/songs',
    'service' || 'service_added' || 'service_updated' =>
      id != null ? '/services/$id' : '/services',
    'next_service' => '/services/next',
    'library' || 'songs' => '/songs',
    'services' => '/services',
    'folder' || 'folders' => '/folders',
    'metronome' => '/metronome',
    'circle_of_fifths' => '/circle-of-fifths',
    'settings' => '/settings',
    _ => null,
  };
}

String? _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return null;
}
