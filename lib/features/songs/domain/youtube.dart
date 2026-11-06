/// Helpers for the ChordPro `{youtube: …}` / `{yt: …}` header directive.
library;

final RegExp _videoIdRegex = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Extracts the 11-character YouTube video ID from [value].
///
/// Accepts a bare ID, a short link (`youtu.be/ID`), or a full URL
/// (`youtube.com/watch?v=ID`, `/embed/ID`, `/shorts/ID`, `/live/ID`, including
/// the `m.` and `music.` subdomains). Returns `null` when no ID is found.
String? parseYoutubeVideoId(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (_videoIdRegex.hasMatch(raw)) return raw;

  final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
  if (uri == null) return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  String? candidate;
  if (host == 'youtu.be' || host == 'yt.be') {
    candidate = segments.isNotEmpty ? segments.first : null;
  } else if (host.endsWith('youtube.com') ||
      host.endsWith('youtube-nocookie.com')) {
    candidate = uri.queryParameters['v'];
    if (candidate == null && segments.length >= 2) {
      const prefixes = {'embed', 'shorts', 'live', 'v', 'e'};
      if (prefixes.contains(segments.first)) candidate = segments[1];
    }
  }

  if (candidate != null && _videoIdRegex.hasMatch(candidate)) return candidate;
  return null;
}

/// The YouTube video ID declared in a song's resolved [metadata], if any.
String? youtubeVideoIdFromMetadata(Map<String, String> metadata) =>
    parseYoutubeVideoId(metadata['youtube']);
