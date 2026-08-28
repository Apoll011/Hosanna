/// Interval-driven chord dictionary, ported from
/// `@hosanna/shared/src/chordpro/chordDictionary.ts`.
///
/// Piano voicings are computed from quality intervals; guitar shapes use a
/// curated open-position table + movable CAGED barre templates + a power-chord
/// formula, falling back to the nearest simpler shape (flagged `approximate`).
library;

class GuitarFingering {
  const GuitarFingering({
    required this.frets,
    this.fingers,
    this.barre,
    this.approximate = false,
  });

  final List<int> frets; // 6 numbers, low-E to high-E; -1 = muted.
  final List<int>? fingers;
  final int? barre;
  final bool approximate;
}

class PianoFingering {
  const PianoFingering({required this.notes, required this.highlightKeys});

  final List<String> notes;
  final List<int> highlightKeys;
}

class ChordFingering {
  const ChordFingering({
    required this.chord,
    required this.qualityId,
    required this.qualityLabel,
    required this.piano,
    this.guitar,
  });

  final String chord;
  final String qualityId;
  final String qualityLabel;
  final PianoFingering piano;
  final GuitarFingering? guitar;
}

// ── Note naming (English + Portuguese solfège), semitone 0 = C ──────────────

const Map<String, int> _noteAliases = {
  'C': 0, 'B#': 0, 'Do': 0, 'DO': 0,
  'C#': 1, 'Db': 1,
  'D': 2, 'Re': 2, 'RE': 2, 'Ré': 2, 'RÉ': 2,
  'D#': 3, 'Eb': 3,
  'E': 4, 'Fb': 4, 'Mi': 4, 'MI': 4,
  'F': 5, 'E#': 5, 'Fa': 5, 'FA': 5, 'Fá': 5, 'FÁ': 5,
  'F#': 6, 'Gb': 6,
  'G': 7, 'Sol': 7, 'SOL': 7,
  'G#': 8, 'Ab': 8,
  'A': 9, 'La': 9, 'LA': 9, 'Lá': 9, 'LÁ': 9,
  'A#': 10, 'Bb': 10,
  'B': 11, 'Cb': 11, 'Si': 11, 'SI': 11,
};

final List<String> _rootKeys = _noteAliases.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

final RegExp _rootPattern =
    RegExp('^(${_rootKeys.join('|')})', caseSensitive: false);

const List<String> _semitoneNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

int? _resolveRootSemitone(String raw) {
  if (_noteAliases.containsKey(raw)) return _noteAliases[raw];
  final titleCase = raw.isEmpty
      ? raw
      : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  if (_noteAliases.containsKey(titleCase)) return _noteAliases[titleCase];
  final upper = raw.toUpperCase();
  if (_noteAliases.containsKey(upper)) return _noteAliases[upper];
  return null;
}

String _pitchClassName(int semitone) =>
    _semitoneNames[((semitone % 12) + 12) % 12];

// ── Chord quality registry ─────────────────────────────────────────────────

class _ChordQuality {
  const _ChordQuality({
    required this.id,
    required this.label,
    required this.intervals,
    required this.aliases,
  });

  final String id;
  final String label;
  final List<int> intervals;
  final List<String> aliases;
}

const List<_ChordQuality> _chordQualities = [
  _ChordQuality(id: 'major', label: 'Major', intervals: [0, 4, 7], aliases: ['', 'M', 'maj', 'Maj', 'MAJ']),
  _ChordQuality(id: 'minor', label: 'Minor', intervals: [0, 3, 7], aliases: ['m', 'min', 'Min', 'MIN', '-']),
  _ChordQuality(id: 'dim', label: 'Diminished', intervals: [0, 3, 6], aliases: ['dim', 'o', '\u00B0']),
  _ChordQuality(id: 'aug', label: 'Augmented', intervals: [0, 4, 8], aliases: ['aug', '+']),
  _ChordQuality(id: 'sus2', label: 'Suspended 2nd', intervals: [0, 2, 7], aliases: ['sus2']),
  _ChordQuality(id: 'sus4', label: 'Suspended 4th', intervals: [0, 5, 7], aliases: ['sus4', 'sus']),
  _ChordQuality(id: 'five', label: 'Power chord', intervals: [0, 7], aliases: ['5']),
  _ChordQuality(id: 'six', label: '6th', intervals: [0, 4, 7, 9], aliases: ['6']),
  _ChordQuality(id: 'm6', label: 'Minor 6th', intervals: [0, 3, 7, 9], aliases: ['m6', 'min6']),
  _ChordQuality(id: 'six9', label: '6/9', intervals: [0, 4, 7, 9, 14], aliases: ['6/9', '69']),
  _ChordQuality(id: 'dom7', label: 'Dominant 7th', intervals: [0, 4, 7, 10], aliases: ['7']),
  _ChordQuality(id: 'maj7', label: 'Major 7th', intervals: [0, 4, 7, 11], aliases: ['maj7', 'Maj7', 'MAJ7', 'M7', '\u0394', '\u03947']),
  _ChordQuality(id: 'm7', label: 'Minor 7th', intervals: [0, 3, 7, 10], aliases: ['m7', 'min7', 'Min7']),
  _ChordQuality(id: 'mMaj7', label: 'Minor Major 7th', intervals: [0, 3, 7, 11], aliases: ['mMaj7', 'm(maj7)', 'mM7', 'minMaj7']),
  _ChordQuality(id: 'm7b5', label: 'Half-diminished 7th', intervals: [0, 3, 6, 10], aliases: ['m7b5', 'm7-5', '\u00F8', '\u00F87']),
  _ChordQuality(id: 'dim7', label: 'Diminished 7th', intervals: [0, 3, 6, 9], aliases: ['dim7', 'o7', '\u00B07']),
  _ChordQuality(id: 'aug7', label: '7#5', intervals: [0, 4, 8, 10], aliases: ['7#5', 'aug7']),
  _ChordQuality(id: 'dom7b5', label: '7b5', intervals: [0, 4, 6, 10], aliases: ['7b5']),
  _ChordQuality(id: 'dom7sus4', label: '7sus4', intervals: [0, 5, 7, 10], aliases: ['7sus4']),
  _ChordQuality(id: 'dom7sus2', label: '7sus2', intervals: [0, 2, 7, 10], aliases: ['7sus2']),
  _ChordQuality(id: 'nine', label: '9th', intervals: [0, 4, 7, 10, 14], aliases: ['9']),
  _ChordQuality(id: 'maj9', label: 'Major 9th', intervals: [0, 4, 7, 11, 14], aliases: ['maj9', 'Maj9', 'M9']),
  _ChordQuality(id: 'm9', label: 'Minor 9th', intervals: [0, 3, 7, 10, 14], aliases: ['m9', 'min9']),
  _ChordQuality(id: 'add9', label: 'Add 9', intervals: [0, 4, 7, 14], aliases: ['add9']),
  _ChordQuality(id: 'madd9', label: 'Minor Add 9', intervals: [0, 3, 7, 14], aliases: ['madd9', 'minAdd9']),
  _ChordQuality(id: 'eleven', label: '11th', intervals: [0, 4, 7, 10, 14, 17], aliases: ['11']),
  _ChordQuality(id: 'm11', label: 'Minor 11th', intervals: [0, 3, 7, 10, 14, 17], aliases: ['m11']),
  _ChordQuality(id: 'thirteen', label: '13th', intervals: [0, 4, 7, 10, 14, 17, 21], aliases: ['13']),
  _ChordQuality(id: 'm13', label: 'Minor 13th', intervals: [0, 3, 7, 10, 14, 17, 21], aliases: ['m13']),
  _ChordQuality(id: 'dom7sharp9', label: '7#9', intervals: [0, 4, 7, 10, 15], aliases: ['7#9']),
  _ChordQuality(id: 'dom7flat9', label: '7b9', intervals: [0, 4, 7, 10, 13], aliases: ['7b9']),
  _ChordQuality(id: 'maj7sharp5', label: 'maj7#5', intervals: [0, 4, 8, 11], aliases: ['maj7#5']),
  _ChordQuality(id: 'maj7flat5', label: 'maj7b5', intervals: [0, 4, 6, 11], aliases: ['maj7b5']),
];

final Map<String, _ChordQuality> _qualityById = {
  for (final q in _chordQualities) q.id: q,
};

final List<({String alias, _ChordQuality quality})> _qualityAliasTable = [
  for (final q in _chordQualities)
    for (final alias in q.aliases) (alias: alias, quality: q),
]..sort((a, b) => b.alias.length.compareTo(a.alias.length));

_ChordQuality _resolveQuality(String qualitySymbol) {
  if (qualitySymbol.isEmpty) return _qualityById['major']!;
  for (final e in _qualityAliasTable) {
    if (e.alias.isNotEmpty && e.alias == qualitySymbol) return e.quality;
  }
  final lower = qualitySymbol.toLowerCase();
  for (final e in _qualityAliasTable) {
    if (e.alias.isNotEmpty && e.alias.toLowerCase() == lower) return e.quality;
  }
  return _qualityById['major']!;
}

const Map<String, String> _qualitySimplification = {
  'dim': 'minor', 'dim7': 'minor', 'aug': 'major', 'six': 'major',
  'm6': 'minor', 'six9': 'major', 'mMaj7': 'm7', 'm7b5': 'm7',
  'aug7': 'dom7', 'dom7b5': 'dom7', 'dom7sus4': 'sus4', 'dom7sus2': 'sus2',
  'nine': 'dom7', 'maj9': 'maj7', 'm9': 'm7', 'add9': 'major',
  'madd9': 'minor', 'eleven': 'dom7', 'm11': 'm7', 'thirteen': 'dom7',
  'm13': 'm7', 'dom7sharp9': 'dom7', 'dom7flat9': 'dom7',
  'maj7sharp5': 'maj7', 'maj7flat5': 'maj7',
};

const Map<String, String> _canonicalSuffix = {
  'major': '', 'minor': 'm', 'dom7': '7', 'maj7': 'maj7', 'm7': 'm7',
  'sus4': 'sus4', 'sus2': 'sus2', 'six': '6', 'add9': 'add9', 'nine': '9',
};

class _ParsedChord {
  const _ParsedChord({
    required this.raw,
    required this.rootSemitone,
    required this.rootDisplay,
    required this.quality,
    this.bassSemitone,
  });

  final String raw;
  final int rootSemitone;
  final String rootDisplay;
  final _ChordQuality quality;
  final int? bassSemitone;
}

_ParsedChord? _parseChordSymbol(String chord) {
  final cleaned = chord.replaceAll(RegExp(r'[()]'), '').trim();
  if (cleaned.isEmpty) return null;

  final rootMatch = _rootPattern.firstMatch(cleaned);
  if (rootMatch == null) return null;

  final rootText = rootMatch.group(1)!;
  final rootSemitone = _resolveRootSemitone(rootText);
  if (rootSemitone == null) return null;

  final remainder = cleaned.substring(rootText.length);

  // Slash-containing aliases (e.g. "6/9") before treating "/" as bass.
  final slashAliases = _qualityAliasTable
      .where((e) => e.alias.contains('/'))
      .toList()
    ..sort((a, b) => b.alias.length.compareTo(a.alias.length));

  String qualitySymbol;
  String? bassPart;
  ({String alias, _ChordQuality quality})? slashAlias;
  for (final e in slashAliases) {
    if (remainder.startsWith(e.alias)) {
      slashAlias = e;
      break;
    }
  }
  if (slashAlias != null) {
    qualitySymbol = slashAlias.alias;
    final rest = remainder.substring(slashAlias.alias.length);
    bassPart = rest.startsWith('/') ? rest.substring(1).trim() : null;
  } else {
    final slashIndex = remainder.indexOf('/');
    if (slashIndex == -1) {
      qualitySymbol = remainder;
    } else {
      qualitySymbol = remainder.substring(0, slashIndex);
      bassPart = remainder.substring(slashIndex + 1).trim();
    }
  }

  final quality = _resolveQuality(qualitySymbol);

  int? bassSemitone;
  if (bassPart != null && bassPart.isNotEmpty) {
    final bassMatch = _rootPattern.firstMatch(bassPart);
    if (bassMatch != null) {
      bassSemitone = _resolveRootSemitone(bassMatch.group(1)!);
    }
  }

  return _ParsedChord(
    raw: cleaned,
    rootSemitone: rootSemitone,
    rootDisplay: _pitchClassName(rootSemitone),
    quality: quality,
    bassSemitone: bassSemitone,
  );
}

PianoFingering _computePianoVoicing(
  int rootSemitone,
  List<int> intervals, [
  int? bassSemitone,
]) {
  final rootPc = ((rootSemitone % 12) + 12) % 12;

  if (bassSemitone != null) {
    final bassPc = ((bassSemitone % 12) + 12) % 12;
    final notes = <String>[_pitchClassName(bassPc)];
    final highlightKeys = <int>[bassPc];
    for (final iv in intervals) {
      final key = ((rootPc + iv) % 12) + 12;
      final name = _pitchClassName(rootPc + iv);
      highlightKeys.add(key);
      if (!notes.contains(name)) notes.add(name);
    }
    return PianoFingering(notes: notes, highlightKeys: highlightKeys);
  }

  final notes = intervals.map((iv) => _pitchClassName(rootPc + iv)).toList();
  final highlightKeys = intervals.map((iv) => (rootPc + iv) % 24).toList();
  return PianoFingering(notes: notes, highlightKeys: highlightKeys);
}

// ── Guitar shapes ───────────────────────────────────────────────────────────

class _GuitarShape {
  const _GuitarShape(this.frets, {this.fingers, this.barre});

  final List<int> frets;
  final List<int>? fingers;
  final int? barre;
}

const Map<String, _GuitarShape> _openChordShapes = {
  'C': _GuitarShape([-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
  'Cm': _GuitarShape([-1, 3, 5, 5, 4, 3], fingers: [0, 1, 3, 4, 2, 1], barre: 3),
  'C7': _GuitarShape([-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0]),
  'Cmaj7': _GuitarShape([-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0]),
  'Cm7': _GuitarShape([-1, 3, 5, 3, 4, 3], fingers: [0, 1, 3, 1, 2, 1], barre: 3),
  'Csus4': _GuitarShape([-1, 3, 3, 0, 1, 1], fingers: [0, 3, 4, 0, 1, 1]),
  'Csus2': _GuitarShape([-1, 3, 0, 0, 1, 3], fingers: [0, 2, 0, 0, 1, 4]),
  'Cadd9': _GuitarShape([-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0]),
  'C9': _GuitarShape([-1, 3, 2, 3, 3, 3], fingers: [0, 2, 1, 3, 3, 3], barre: 3),
  'C6': _GuitarShape([-1, 3, 2, 2, 1, 0], fingers: [0, 4, 2, 3, 1, 0]),

  'C#': _GuitarShape([-1, 4, 6, 6, 6, 4], fingers: [0, 1, 2, 3, 4, 1], barre: 4),
  'C#m': _GuitarShape([-1, 4, 6, 6, 5, 4], fingers: [0, 1, 3, 4, 2, 1], barre: 4),
  'C#7': _GuitarShape([-1, 4, 3, 4, 2, -1], fingers: [0, 3, 2, 4, 1, 0]),
  'C#maj7': _GuitarShape([-1, 4, 6, 5, 6, 4], fingers: [0, 1, 3, 2, 4, 1], barre: 4),
  'C#m7': _GuitarShape([-1, 4, 6, 4, 5, 4], fingers: [0, 1, 3, 1, 2, 1], barre: 4),

  'D': _GuitarShape([-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
  'Dm': _GuitarShape([-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
  'D7': _GuitarShape([-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3]),
  'Dmaj7': _GuitarShape([-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1], barre: 2),
  'Dm7': _GuitarShape([-1, -1, 0, 2, 1, 1], fingers: [0, 0, 0, 2, 1, 1], barre: 1),
  'Dsus4': _GuitarShape([-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 2, 3]),
  'Dsus2': _GuitarShape([-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 2, 0]),
  'Dadd9': _GuitarShape([-1, -1, 0, 2, 5, 2], fingers: [0, 0, 0, 1, 4, 2]),
  'D6': _GuitarShape([-1, -1, 0, 2, 0, 2], fingers: [0, 0, 0, 2, 0, 3]),
  'D9': _GuitarShape([-1, -1, 0, 2, 1, 0], fingers: [0, 0, 0, 2, 1, 0]),

  'Eb': _GuitarShape([-1, 6, 8, 8, 8, 6], fingers: [0, 1, 2, 3, 4, 1], barre: 6),
  'Ebm': _GuitarShape([-1, 6, 8, 8, 7, 6], fingers: [0, 1, 3, 4, 2, 1], barre: 6),
  'Eb7': _GuitarShape([-1, 6, 5, 6, 4, -1], fingers: [0, 3, 2, 4, 1, 0]),

  'E': _GuitarShape([0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
  'Em': _GuitarShape([0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0]),
  'E7': _GuitarShape([0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0]),
  'Emaj7': _GuitarShape([0, 2, 1, 1, 0, 0], fingers: [0, 3, 1, 2, 0, 0]),
  'Em7': _GuitarShape([0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0]),
  'Esus4': _GuitarShape([0, 2, 2, 2, 0, 0], fingers: [0, 2, 3, 4, 0, 0]),
  'Eadd9': _GuitarShape([0, 2, 4, 1, 0, 0], fingers: [0, 2, 4, 1, 0, 0]),
  'E6': _GuitarShape([0, 2, 2, 1, 2, 0], fingers: [0, 2, 3, 1, 4, 0]),
  'E9': _GuitarShape([0, 2, 0, 1, 3, 0], fingers: [0, 2, 0, 1, 4, 0]),

  'F': _GuitarShape([1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1),
  'Fm': _GuitarShape([1, 3, 3, 1, 1, 1], fingers: [1, 3, 4, 1, 1, 1], barre: 1),
  'F7': _GuitarShape([1, 3, 1, 2, 1, 1], fingers: [1, 3, 1, 2, 1, 1], barre: 1),
  'Fmaj7': _GuitarShape([-1, 3, 3, 2, 1, 0], fingers: [0, 3, 4, 2, 1, 0]),
  'Fm7': _GuitarShape([1, 3, 1, 1, 1, 1], fingers: [1, 3, 1, 1, 1, 1], barre: 1),

  'F#': _GuitarShape([2, 4, 4, 3, 2, 2], fingers: [1, 3, 4, 2, 1, 1], barre: 2),
  'F#m': _GuitarShape([2, 4, 4, 2, 2, 2], fingers: [1, 3, 4, 1, 1, 1], barre: 2),
  'F#7': _GuitarShape([2, 4, 2, 3, 2, 2], fingers: [1, 3, 1, 2, 1, 1], barre: 2),
  'F#m7': _GuitarShape([2, 4, 2, 2, 2, 2], fingers: [1, 3, 1, 1, 1, 1], barre: 2),

  'G': _GuitarShape([3, 2, 0, 0, 3, 3], fingers: [2, 1, 0, 0, 3, 4]),
  'Gm': _GuitarShape([3, 5, 5, 3, 3, 3], fingers: [1, 3, 4, 1, 1, 1], barre: 3),
  'G7': _GuitarShape([3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1]),
  'Gmaj7': _GuitarShape([3, 2, 0, 0, 0, 2], fingers: [2, 1, 0, 0, 0, 3]),
  'Gm7': _GuitarShape([3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3),
  'Gsus4': _GuitarShape([3, 3, 0, 0, 3, 3], fingers: [2, 3, 0, 0, 1, 4]),
  'Gadd9': _GuitarShape([3, 2, 0, 2, 0, 3], fingers: [2, 1, 0, 3, 0, 4]),
  'G6': _GuitarShape([3, 2, 0, 0, 0, 0], fingers: [3, 2, 0, 0, 0, 0]),

  'Ab': _GuitarShape([4, 6, 6, 5, 4, 4], fingers: [1, 3, 4, 2, 1, 1], barre: 4),
  'Abm': _GuitarShape([4, 6, 6, 4, 4, 4], fingers: [1, 3, 4, 1, 1, 1], barre: 4),

  'A': _GuitarShape([-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
  'Am': _GuitarShape([-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
  'A7': _GuitarShape([-1, 0, 2, 0, 2, 0], fingers: [0, 0, 1, 0, 2, 0]),
  'Amaj7': _GuitarShape([-1, 0, 2, 1, 2, 0], fingers: [0, 0, 2, 1, 3, 0]),
  'Am7': _GuitarShape([-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0]),
  'Asus4': _GuitarShape([-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 4, 0]),
  'Asus2': _GuitarShape([-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0]),
  'Aadd9': _GuitarShape([-1, 0, 2, 4, 2, 0], fingers: [0, 0, 1, 3, 2, 0]),
  'A6': _GuitarShape([-1, 0, 2, 2, 2, 2], fingers: [0, 0, 1, 1, 1, 1], barre: 2),
  'A9': _GuitarShape([-1, 0, 2, 4, 2, 3], fingers: [0, 0, 1, 3, 2, 4]),

  'Bb': _GuitarShape([-1, 1, 3, 3, 3, 1], fingers: [0, 1, 2, 3, 4, 1], barre: 1),
  'Bbm': _GuitarShape([-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1),
  'Bb7': _GuitarShape([-1, 1, 3, 1, 3, 1], fingers: [0, 1, 3, 1, 4, 1], barre: 1),

  'B': _GuitarShape([-1, 2, 4, 4, 4, 2], fingers: [0, 1, 2, 3, 4, 1], barre: 2),
  'Bm': _GuitarShape([-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2),
  'B7': _GuitarShape([-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4]),
  'Bmaj7': _GuitarShape([-1, 2, 4, 3, 4, 2], fingers: [0, 1, 3, 2, 4, 1], barre: 2),
  'Bm7': _GuitarShape([-1, 2, 4, 2, 3, 2], fingers: [0, 1, 3, 1, 2, 1], barre: 2),
};

const Map<String, _GuitarShape> _slashChordShapes = {
  'C/E': _GuitarShape([0, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
  'C/G': _GuitarShape([3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0]),
  'C/Bb': _GuitarShape([-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0]),
  'D/F#': _GuitarShape([2, 0, 0, 2, 3, 2], fingers: [1, 0, 0, 2, 4, 3]),
  'D/A': _GuitarShape([-1, 0, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
  'E/G#': _GuitarShape([4, 2, 2, 1, 0, 0], fingers: [4, 2, 3, 1, 0, 0]),
  'E/B': _GuitarShape([0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
  'F/A': _GuitarShape([-1, 0, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1]),
  'F/C': _GuitarShape([8, 8, 10, 10, 10, 8], fingers: [1, 1, 2, 3, 4, 1], barre: 8),
  'G/B': _GuitarShape([-1, 2, 0, 0, 3, 3], fingers: [0, 1, 0, 0, 3, 4]),
  'G/D': _GuitarShape([-1, -1, 0, 0, 3, 3], fingers: [0, 0, 0, 0, 3, 4]),
  'G/F': _GuitarShape([3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1]),
  'A/C#': _GuitarShape([-1, 4, 2, 2, 2, -1], fingers: [0, 4, 1, 1, 1, 0]),
  'A/E': _GuitarShape([0, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
  'A/G': _GuitarShape([3, 0, 2, 2, 2, 0], fingers: [4, 0, 1, 2, 3, 0]),
  'B/D#': _GuitarShape([-1, 6, 4, 4, 4, -1], fingers: [0, 3, 1, 1, 1, 0]),
  'B/F#': _GuitarShape([2, 2, 4, 4, 4, 2], fingers: [1, 1, 2, 3, 4, 1], barre: 2),
  'Am/G': _GuitarShape([3, 0, 2, 2, 1, 0], fingers: [4, 0, 2, 3, 1, 0]),
  'Am/F#': _GuitarShape([2, 0, 2, 2, 1, 0], fingers: [2, 0, 3, 4, 1, 0]),
  'Am/E': _GuitarShape([0, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
  'Dm/C': _GuitarShape([-1, 3, 0, 2, 3, 1], fingers: [0, 3, 0, 2, 4, 1]),
  'Dm/B': _GuitarShape([-1, 2, 0, 2, 3, 1], fingers: [0, 2, 0, 3, 4, 1]),
  'Dm/A': _GuitarShape([-1, 0, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
  'Dm/F': _GuitarShape([1, -1, 0, 2, 3, 1], fingers: [1, 0, 0, 2, 4, 3]),
  'Em/D': _GuitarShape([0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0]),
  'Em/C#': _GuitarShape([0, 4, 2, 0, 0, 0], fingers: [0, 3, 1, 0, 0, 0]),
  'Em/B': _GuitarShape([7, 7, 9, 9, 8, 7], fingers: [1, 1, 3, 4, 2, 1], barre: 7),
  'Em/G': _GuitarShape([3, 2, 2, 0, 0, 0], fingers: [3, 1, 2, 0, 0, 0]),
  'Fm/Eb': _GuitarShape([-1, 6, 6, 5, 6, -1], fingers: [0, 2, 3, 1, 4, 0]),
  'Gm/F': _GuitarShape([3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3),
  'Bm/A': _GuitarShape([-1, 0, 4, 4, 3, 2], fingers: [0, 0, 3, 4, 2, 1]),
};

class _BarreTemplate {
  const _BarreTemplate({
    required this.formRootSemitone,
    required this.frets,
    this.openFingers,
    required this.barreFingers,
  });

  final int formRootSemitone;
  final List<int> frets;
  final List<int>? openFingers;
  final List<int> barreFingers;
}

const Map<String, _BarreTemplate> _eForm = {
  'major': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 2, 1, 0, 0], openFingers: [0, 2, 3, 1, 0, 0], barreFingers: [1, 3, 4, 2, 1, 1]),
  'minor': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 2, 0, 0, 0], openFingers: [0, 2, 3, 0, 0, 0], barreFingers: [1, 3, 4, 1, 1, 1]),
  'dom7': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 0, 1, 0, 0], openFingers: [0, 2, 0, 1, 0, 0], barreFingers: [1, 3, 1, 2, 1, 1]),
  'm7': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 0, 0, 0, 0], openFingers: [0, 2, 0, 0, 0, 0], barreFingers: [1, 3, 1, 1, 1, 1]),
  'maj7': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 1, 1, 0, 0], openFingers: [0, 3, 1, 2, 0, 0], barreFingers: [1, 3, 2, 2, 1, 1]),
  'sus4': _BarreTemplate(formRootSemitone: 4, frets: [0, 2, 2, 2, 0, 0], openFingers: [0, 2, 3, 4, 0, 0], barreFingers: [1, 3, 4, 4, 1, 1]),
};

const Map<String, _BarreTemplate> _aForm = {
  'major': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 2, 2, 0], openFingers: [0, 0, 1, 2, 3, 0], barreFingers: [0, 1, 3, 4, 4, 1]),
  'minor': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 2, 1, 0], openFingers: [0, 0, 2, 3, 1, 0], barreFingers: [0, 1, 3, 4, 2, 1]),
  'dom7': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 0, 2, 0], openFingers: [0, 0, 1, 0, 2, 0], barreFingers: [0, 1, 3, 1, 4, 1]),
  'm7': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 0, 1, 0], openFingers: [0, 0, 2, 0, 1, 0], barreFingers: [0, 1, 3, 1, 2, 1]),
  'maj7': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 1, 2, 0], openFingers: [0, 0, 2, 1, 3, 0], barreFingers: [0, 1, 3, 2, 4, 1]),
  'sus4': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 2, 3, 0], openFingers: [0, 0, 1, 2, 4, 0], barreFingers: [0, 1, 3, 3, 4, 1]),
  'sus2': _BarreTemplate(formRootSemitone: 9, frets: [-1, 0, 2, 2, 0, 0], openFingers: [0, 0, 1, 2, 0, 0], barreFingers: [0, 1, 3, 4, 1, 1]),
};

_GuitarShape _realizeTemplate(_BarreTemplate t, int targetSemitone) {
  final shift = ((targetSemitone - t.formRootSemitone) % 12 + 12) % 12;
  final frets = t.frets.map((f) => f < 0 ? f : f + shift).toList();
  if (shift == 0) {
    return _GuitarShape(frets, fingers: t.openFingers ?? t.barreFingers);
  }
  return _GuitarShape(frets, fingers: t.barreFingers, barre: shift);
}

int _maxFret(_GuitarShape shape) {
  var max = 0;
  for (final f in shape.frets) {
    if (f > max) max = f;
  }
  return max;
}

_GuitarShape? _templateFingering(String qualityId, int targetSemitone) {
  final e = _eForm[qualityId];
  final a = _aForm[qualityId];
  if (e == null && a == null) return null;
  if (e != null && a == null) return _realizeTemplate(e, targetSemitone);
  if (a != null && e == null) return _realizeTemplate(a, targetSemitone);
  final eShape = _realizeTemplate(e!, targetSemitone);
  final aShape = _realizeTemplate(a!, targetSemitone);
  return _maxFret(aShape) <= _maxFret(eShape) ? aShape : eShape;
}

_GuitarShape _powerChordShape(int targetSemitone) {
  final shift = ((targetSemitone - 4) % 12 + 12) % 12;
  return _GuitarShape(
    [shift, shift + 2, shift + 2, -1, -1, -1],
    fingers: [1, 3, 4, 0, 0, 0],
  );
}

const Set<String> _templateQualities = {
  'major', 'minor', 'dom7', 'm7', 'maj7', 'sus4', 'sus2',
};

({_GuitarShape shape, bool approximate})? _getGuitarFingering(
  _ParsedChord parsed,
) {
  final rootSemitone = parsed.rootSemitone;
  final quality = parsed.quality;
  final raw = parsed.raw;
  final rootDisplay = parsed.rootDisplay;

  if (_slashChordShapes.containsKey(raw)) {
    return (shape: _slashChordShapes[raw]!, approximate: false);
  }
  if (_openChordShapes.containsKey(raw)) {
    return (shape: _openChordShapes[raw]!, approximate: false);
  }

  final suffix = _canonicalSuffix[quality.id];
  if (suffix != null) {
    final canonical = rootDisplay + suffix;
    if (_openChordShapes.containsKey(canonical)) {
      return (shape: _openChordShapes[canonical]!, approximate: false);
    }
  }

  if (quality.id == 'five') {
    return (shape: _powerChordShape(rootSemitone), approximate: false);
  }

  if (_templateQualities.contains(quality.id)) {
    final shape = _templateFingering(quality.id, rootSemitone);
    if (shape != null) return (shape: shape, approximate: false);
  }

  var fallbackId = _qualitySimplification[quality.id];
  var hops = 0;
  while (fallbackId != null && hops < 4) {
    if (_templateQualities.contains(fallbackId)) {
      final shape = _templateFingering(fallbackId, rootSemitone);
      if (shape != null) return (shape: shape, approximate: true);
    }
    final suf = _canonicalSuffix[fallbackId];
    if (suf != null) {
      final canonical = rootDisplay + suf;
      if (_openChordShapes.containsKey(canonical)) {
        return (shape: _openChordShapes[canonical]!, approximate: true);
      }
    }
    fallbackId = _qualitySimplification[fallbackId];
    hops += 1;
  }

  return null;
}

// ── Public dictionary ───────────────────────────────────────────────────────

class ChordDictionary {
  const ChordDictionary();

  ChordFingering? getFingering(String chord) {
    final parsed = _parseChordSymbol(chord);
    if (parsed == null) return null;

    final piano = _computePianoVoicing(
      parsed.rootSemitone,
      parsed.quality.intervals,
      parsed.bassSemitone,
    );
    final guitar = _getGuitarFingering(parsed);

    return ChordFingering(
      chord: parsed.raw,
      qualityId: parsed.quality.id,
      qualityLabel: parsed.quality.label,
      piano: piano,
      guitar: guitar == null
          ? null
          : GuitarFingering(
              frets: guitar.shape.frets,
              fingers: guitar.shape.fingers,
              barre: guitar.shape.barre,
              approximate: guitar.approximate,
            ),
    );
  }
}

const ChordDictionary chordDictionary = ChordDictionary();
