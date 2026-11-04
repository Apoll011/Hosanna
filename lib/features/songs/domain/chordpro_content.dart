/// Helpers for building / updating ChordPro directive headers used by the
/// song editor. Body (lyrics + chords) is preserved when metadata changes.
library;

final _titleRe = RegExp(r'\{title:\s*[^}]*\}', caseSensitive: false);
final _artistRe = RegExp(r'\{artist:\s*[^}]*\}', caseSensitive: false);
final _keyRe = RegExp(r'\{key:\s*[^}]*\}', caseSensitive: false);
final _tempoRe = RegExp(r'\{tempo:\s*[^}]*\}', caseSensitive: false);
final _timeRe = RegExp(r'\{time:\s*[^}]*\}', caseSensitive: false);

/// Stub ChordPro body for a brand-new song.
String defaultChordProContent({
  required String title,
  String artist = '',
  String key = 'G',
  String? tempo,
  String? timeSignature,
}) {
  final buf = StringBuffer()
    ..writeln('{title: ${title.trim().isEmpty ? 'Untitled' : title.trim()}}')
    ..writeln(
      '{artist: ${artist.trim().isEmpty ? 'Unknown' : artist.trim()}}',
    )
    ..writeln('{key: ${key.trim().isEmpty ? 'G' : key.trim()}}');
  if (tempo != null && tempo.trim().isNotEmpty) {
    buf.writeln('{tempo: ${tempo.trim()}}');
  }
  if (timeSignature != null && timeSignature.trim().isNotEmpty) {
    buf.writeln('{time: ${timeSignature.trim()}}');
  }
  buf
    ..writeln()
    ..writeln('[G]Add chords and lyrics here...');
  return buf.toString();
}

/// Reads a directive value from [content], or null if missing.
String? readChordProDirective(String content, String name) {
  final re = RegExp('\\{$name:\\s*([^}]*)\\}', caseSensitive: false);
  final match = re.firstMatch(content);
  final value = match?.group(1)?.trim();
  return (value == null || value.isEmpty) ? null : value;
}

/// Removes directives that the song editor manages via dedicated fields so the
/// body textarea only shows lyrics/chords (and any other free-form directives).
String stripManagedDirectives(String content) {
  var result = content;
  for (final re in [_titleRe, _artistRe, _keyRe, _tempoRe, _timeRe]) {
    result = result.replaceAll(re, '');
  }
  return result
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'^\s+'), '');
}

/// Upserts title/artist/key/tempo/time directives; keeps the rest of [content].
String applyChordProMetadata(
  String content, {
  String? title,
  String? artist,
  String? key,
  String? tempo,
  String? timeSignature,
}) {
  // Always start from a body without managed directives so we never duplicate.
  var result = stripManagedDirectives(content);
  result = _upsert(result, _titleRe, 'title', title);
  result = _upsert(result, _artistRe, 'artist', artist);
  result = _upsert(result, _keyRe, 'key', key);
  result = _upsert(result, _tempoRe, 'tempo', tempo);
  result = _upsert(result, _timeRe, 'time', timeSignature);
  return result;
}

String _upsert(String content, RegExp re, String name, String? value) {
  if (value == null) return content;
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return content.replaceFirst(re, '').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
  final directive = '{$name: $trimmed}';
  if (re.hasMatch(content)) {
    return content.replaceFirst(re, directive);
  }
  // Insert after any existing header block (leading directives).
  final headerEnd = _headerEndIndex(content);
  if (headerEnd <= 0) {
    return '$directive\n$content';
  }
  return '${content.substring(0, headerEnd)}$directive\n'
      '${content.substring(headerEnd)}';
}

int _headerEndIndex(String content) {
  final lines = content.split('\n');
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trim();
    if (line.isEmpty || (line.startsWith('{') && line.endsWith('}'))) {
      i++;
      continue;
    }
    break;
  }
  if (i == 0) return 0;
  // Position just before the first non-header line.
  var offset = 0;
  for (var j = 0; j < i; j++) {
    offset += lines[j].length + 1;
  }
  return offset.clamp(0, content.length);
}

String sanitizeSongPath(String title) {
  final base = title.trim().isEmpty ? 'untitled' : title.trim();
  final safe = base
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safe.toLowerCase().endsWith('.pro') ? safe : '$safe.pro';
}
