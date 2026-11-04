/// Helpers for building / updating ChordPro directive headers used by the
/// song editor. Body (lyrics + chords) is preserved when metadata changes.
library;

/// Header directives the editor manages via form fields (stripped from the
/// body textarea). Names match what the ChordPro parser / metadata header
/// understand.
const kManagedChordProDirectives = <String>[
  'title',
  'subtitle',
  'artist',
  'composer',
  'key',
  'original_key',
  'originalKey',
  'tempo',
  'time',
  'time_signature',
  'duration',
  'capo',
  'copyright',
  'ccli',
  'song_number',
  'songNumber',
  'key_note',
  'keyNote',
  'youtube',
];

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
///
/// [aliases] are tried in order after [name] (e.g. `original_key` / `originalKey`).
String? readChordProDirective(
  String content,
  String name, {
  List<String> aliases = const [],
}) {
  for (final candidate in [name, ...aliases]) {
    final re = RegExp('\\{$candidate:\\s*([^}]*)\\}', caseSensitive: false);
    final match = re.firstMatch(content);
    final value = match?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

RegExp _directiveRe(String name) =>
    RegExp('\\{$name:\\s*[^}]*\\}', caseSensitive: false);

/// Removes directives that the song editor manages via dedicated fields so the
/// body textarea only shows lyrics/chords (and any other free-form directives).
String stripManagedDirectives(String content) {
  var result = content;
  for (final name in kManagedChordProDirectives) {
    result = result.replaceAll(_directiveRe(name), '');
  }
  return result
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceFirst(RegExp(r'^\s+'), '');
}

/// Upserts managed header directives; keeps the rest of [content].
///
/// Pass empty string to remove a directive; omit / null to leave unchanged
/// relative to stripped body (i.e. not written). Prefer always passing the
/// current field values from the editor.
String applyChordProMetadata(
  String content, {
  String? title,
  String? subtitle,
  String? artist,
  String? composer,
  String? key,
  String? originalKey,
  String? tempo,
  String? timeSignature,
  String? duration,
  String? capo,
  String? copyright,
  String? ccli,
  String? songNumber,
  String? keyNote,
  String? youtube,
}) {
  // Always start from a body without managed directives so we never duplicate.
  var result = stripManagedDirectives(content);
  result = _upsert(result, 'title', title);
  result = _upsert(result, 'subtitle', subtitle);
  result = _upsert(result, 'artist', artist);
  result = _upsert(result, 'composer', composer);
  result = _upsert(result, 'key', key);
  result = _upsert(result, 'original_key', originalKey);
  result = _upsert(result, 'tempo', tempo);
  result = _upsert(result, 'time', timeSignature);
  result = _upsert(result, 'duration', duration);
  result = _upsert(result, 'capo', capo);
  result = _upsert(result, 'copyright', copyright);
  result = _upsert(result, 'ccli', ccli);
  result = _upsert(result, 'song_number', songNumber);
  result = _upsert(result, 'key_note', keyNote);
  result = _upsert(result, 'youtube', youtube);
  return result;
}

String _upsert(String content, String name, String? value) {
  if (value == null) return content;
  final trimmed = value.trim();
  final re = _directiveRe(name);
  if (trimmed.isEmpty) {
    return content.replaceAll(re, '').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
  final directive = '{$name: $trimmed}';
  if (re.hasMatch(content)) {
    return content.replaceFirst(re, directive);
  }
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
