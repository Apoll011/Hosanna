/// Chord transposition, ported from `@hosanna/shared/src/chordpro/transpose.ts`.
library;

const Map<String, int> _noteToVal = {
  'C': 0,
  'C#': 1,
  'DB': 1,
  'D': 2,
  'D#': 3,
  'EB': 3,
  'E': 4,
  'F': 5,
  'F#': 6,
  'GB': 6,
  'G': 7,
  'G#': 8,
  'AB': 8,
  'A': 9,
  'A#': 10,
  'BB': 10,
  'B': 11,
  'DO': 0,
  'RE': 2,
  'RÉ': 2,
  'MI': 4,
  'FA': 5,
  'FÁ': 5,
  'SOL': 7,
  'LA': 9,
  'LÁ': 9,
  'SI': 11,
};

const List<String> _sharps = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];
const List<String> _flats = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
];

final RegExp _noteRegex = RegExp(
  r'^([A-G][#b]?|Do|Ré|Mi|Fá|Sol|Lá|Si|DO|RE|RÉ|MI|FA|FÁ|SOL|LA|LÁ|SI)',
  caseSensitive: false,
);

int? getNoteValue(String note) {
  if (note.isEmpty) return null;
  final match = _noteRegex.firstMatch(note);
  if (match == null) return null;
  return _noteToVal[match.group(1)!.toUpperCase()];
}

({int capo, String chordShape})? getSuggestedCapo(
  String? originalKey,
  int transposeVal,
) {
  final baseKeyVal = originalKey != null ? getNoteValue(originalKey) : 0;
  final keyVal = baseKeyVal ?? 0;
  final soundingVal = (keyVal + transposeVal + 240) % 12;

  const easyShapes = {0: 'C', 7: 'G', 2: 'D', 9: 'A', 4: 'E'};
  const preferredOpenVals = [0, 7, 2, 9, 4];

  for (final targetShapeVal in preferredOpenVals) {
    final neededCapo = (soundingVal - targetShapeVal + 12) % 12;
    if (neededCapo >= 1 && neededCapo <= 7) {
      return (capo: neededCapo, chordShape: easyShapes[targetShapeVal]!);
    }
  }

  return null;
}

String transposeNote(String note, int semitones, {bool preferFlats = false}) {
  final upper = note.toUpperCase();
  final val = _noteToVal[upper];
  if (val == null) return note;

  final newVal = (val + semitones + 24) % 12;
  final targetScale = preferFlats ? _flats : _sharps;
  var transposed = targetScale[newVal];

  if (note.isNotEmpty && note[0] == note[0].toLowerCase()) {
    transposed = transposed.toLowerCase();
  }
  return transposed;
}

String transposeChord(String chord, int semitones) {
  if (chord.isEmpty || semitones == 0) return chord;

  if (chord.contains('/')) {
    return chord
        .split('/')
        .map((part) => transposeChord(part.trim(), semitones))
        .join('/');
  }

  final match = _noteRegex.firstMatch(chord);
  if (match == null) return chord;

  final note = match.group(1)!;
  final suffix = chord.substring(note.length);
  final preferFlats = chord.contains('b') || chord.contains('B');
  final transposedNote = transposeNote(note, semitones, preferFlats: preferFlats);

  return '$transposedNote$suffix';
}
