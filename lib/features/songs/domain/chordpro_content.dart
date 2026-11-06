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
  'lyricist',
  'translator',
  'arranger',
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
  'album',
  'year',
  'youtube',
  'tags',
];

/// Common major / minor keys for the song editor dropdowns.
const kMusicalKeys = <String>[
  'C',
  'C#',
  'Db',
  'D',
  'D#',
  'Eb',
  'E',
  'F',
  'F#',
  'Gb',
  'G',
  'G#',
  'Ab',
  'A',
  'A#',
  'Bb',
  'B',
  'Cm',
  'C#m',
  'Dbm',
  'Dm',
  'D#m',
  'Ebm',
  'Em',
  'Fm',
  'F#m',
  'Gbm',
  'Gm',
  'G#m',
  'Abm',
  'Am',
  'A#m',
  'Bbm',
  'Bm',
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
      .replaceFirst(RegExp(r'^\s+'), '')
      .replaceFirst(RegExp(r'\s+$'), '');
}

/// Upserts managed header directives; keeps the rest of [content].
///
/// Managed metadata is always written as a contiguous block at the top of the
/// file (title → … → tags), followed by a blank line and then the body. Body
/// directives such as `{comment: …}` stay with the lyrics — they are never
/// pulled into the header and never cause metadata to be inserted mid-body.
///
/// Pass empty string to omit a directive; omit / null to leave unchanged
/// relative to stripped body (i.e. not written). Prefer always passing the
/// current field values from the editor.
String applyChordProMetadata(
  String content, {
  String? title,
  String? subtitle,
  String? artist,
  String? composer,
  String? lyricist,
  String? translator,
  String? arranger,
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
  String? album,
  String? year,
  String? youtube,
  String? tags,
}) {
  final body = stripManagedDirectives(content);
  final header = StringBuffer();

  void write(String name, String? value) {
    if (value == null) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    header.writeln('{$name: $trimmed}');
  }

  write('title', title);
  write('subtitle', subtitle);
  write('artist', artist);
  write('composer', composer);
  write('lyricist', lyricist);
  write('translator', translator);
  write('arranger', arranger);
  write('key', key);
  write('original_key', originalKey);
  write('tempo', tempo);
  write('time', timeSignature);
  write('duration', duration);
  write('capo', capo);
  write('copyright', copyright);
  write('ccli', ccli);
  write('song_number', songNumber);
  write('key_note', keyNote);
  write('album', album);
  write('year', year);
  write('youtube', youtube);
  write('tags', tags);

  final headerText = header.toString();
  if (headerText.isEmpty) {
    return body.isEmpty ? '' : '$body\n';
  }
  if (body.isEmpty) {
    return headerText;
  }
  return '$headerText\n$body\n';
}

String sanitizeSongPath(String title) {
  final base = title.trim().isEmpty ? 'untitled' : title.trim();
  final safe = base
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safe.toLowerCase().endsWith('.pro') ? safe : '$safe.pro';
}
