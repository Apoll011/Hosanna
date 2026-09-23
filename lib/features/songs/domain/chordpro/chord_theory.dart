/// Instrument-agnostic chord theory, ported from
/// `@hosanna/shared/src/chordpro/chordDictionary.ts`.
///
/// This library knows about note names (English + Portuguese solfège), the
/// chord-quality registry (intervals + aliases) and how to parse a chord
/// symbol into a root + quality + optional bass. It knows nothing about how
/// any particular instrument voices those notes — see
/// `instruments/instrument.dart` for that seam.
library;

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

/// Resolves a note name (any supported spelling) to a semitone 0..11.
int? resolveRootSemitone(String raw) {
  if (_noteAliases.containsKey(raw)) return _noteAliases[raw];
  final titleCase = raw.isEmpty
      ? raw
      : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  if (_noteAliases.containsKey(titleCase)) return _noteAliases[titleCase];
  final upper = raw.toUpperCase();
  if (_noteAliases.containsKey(upper)) return _noteAliases[upper];
  return null;
}

/// Canonical sharp-based name for [semitone] (e.g. 1 → `C#`).
String pitchClassName(int semitone) =>
    _semitoneNames[((semitone % 12) + 12) % 12];

/// Folds [semitone] into 0..11.
int pitchClass(int semitone) => ((semitone % 12) + 12) % 12;

// ── Chord quality registry ─────────────────────────────────────────────────

/// A chord quality (major, minor, dominant 7th, …) expressed as intervals
/// from the root, in semitones.
class ChordQuality {
  const ChordQuality({
    required this.id,
    required this.label,
    required this.intervals,
    required this.aliases,
  });

  /// Stable identifier used by instrument shape tables.
  final String id;

  /// Human-readable label (English).
  final String label;

  /// Semitone intervals from the root.
  final List<int> intervals;

  /// Chord-symbol suffixes that map to this quality.
  final List<String> aliases;
}

const List<ChordQuality> chordQualities = [
  ChordQuality(id: 'major', label: 'Major', intervals: [0, 4, 7], aliases: ['', 'M', 'maj', 'Maj', 'MAJ']),
  ChordQuality(id: 'minor', label: 'Minor', intervals: [0, 3, 7], aliases: ['m', 'min', 'Min', 'MIN', '-']),
  ChordQuality(id: 'dim', label: 'Diminished', intervals: [0, 3, 6], aliases: ['dim', 'o', '\u00B0']),
  ChordQuality(id: 'aug', label: 'Augmented', intervals: [0, 4, 8], aliases: ['aug', '+']),
  ChordQuality(id: 'sus2', label: 'Suspended 2nd', intervals: [0, 2, 7], aliases: ['sus2']),
  ChordQuality(id: 'sus4', label: 'Suspended 4th', intervals: [0, 5, 7], aliases: ['sus4', 'sus']),
  ChordQuality(id: 'five', label: 'Power chord', intervals: [0, 7], aliases: ['5']),
  ChordQuality(id: 'six', label: '6th', intervals: [0, 4, 7, 9], aliases: ['6']),
  ChordQuality(id: 'm6', label: 'Minor 6th', intervals: [0, 3, 7, 9], aliases: ['m6', 'min6']),
  ChordQuality(id: 'six9', label: '6/9', intervals: [0, 4, 7, 9, 14], aliases: ['6/9', '69']),
  ChordQuality(id: 'dom7', label: 'Dominant 7th', intervals: [0, 4, 7, 10], aliases: ['7']),
  ChordQuality(id: 'maj7', label: 'Major 7th', intervals: [0, 4, 7, 11], aliases: ['maj7', 'Maj7', 'MAJ7', 'M7', '\u0394', '\u03947']),
  ChordQuality(id: 'm7', label: 'Minor 7th', intervals: [0, 3, 7, 10], aliases: ['m7', 'min7', 'Min7']),
  ChordQuality(id: 'mMaj7', label: 'Minor Major 7th', intervals: [0, 3, 7, 11], aliases: ['mMaj7', 'm(maj7)', 'mM7', 'minMaj7']),
  ChordQuality(id: 'm7b5', label: 'Half-diminished 7th', intervals: [0, 3, 6, 10], aliases: ['m7b5', 'm7-5', '\u00F8', '\u00F87']),
  ChordQuality(id: 'dim7', label: 'Diminished 7th', intervals: [0, 3, 6, 9], aliases: ['dim7', 'o7', '\u00B07']),
  ChordQuality(id: 'aug7', label: '7#5', intervals: [0, 4, 8, 10], aliases: ['7#5', 'aug7']),
  ChordQuality(id: 'dom7b5', label: '7b5', intervals: [0, 4, 6, 10], aliases: ['7b5']),
  ChordQuality(id: 'dom7sus4', label: '7sus4', intervals: [0, 5, 7, 10], aliases: ['7sus4']),
  ChordQuality(id: 'dom7sus2', label: '7sus2', intervals: [0, 2, 7, 10], aliases: ['7sus2']),
  ChordQuality(id: 'nine', label: '9th', intervals: [0, 4, 7, 10, 14], aliases: ['9']),
  ChordQuality(id: 'maj9', label: 'Major 9th', intervals: [0, 4, 7, 11, 14], aliases: ['maj9', 'Maj9', 'M9']),
  ChordQuality(id: 'm9', label: 'Minor 9th', intervals: [0, 3, 7, 10, 14], aliases: ['m9', 'min9']),
  ChordQuality(id: 'add9', label: 'Add 9', intervals: [0, 4, 7, 14], aliases: ['add9']),
  ChordQuality(id: 'madd9', label: 'Minor Add 9', intervals: [0, 3, 7, 14], aliases: ['madd9', 'minAdd9']),
  ChordQuality(id: 'eleven', label: '11th', intervals: [0, 4, 7, 10, 14, 17], aliases: ['11']),
  ChordQuality(id: 'm11', label: 'Minor 11th', intervals: [0, 3, 7, 10, 14, 17], aliases: ['m11']),
  ChordQuality(id: 'thirteen', label: '13th', intervals: [0, 4, 7, 10, 14, 17, 21], aliases: ['13']),
  ChordQuality(id: 'm13', label: 'Minor 13th', intervals: [0, 3, 7, 10, 14, 17, 21], aliases: ['m13']),
  ChordQuality(id: 'dom7sharp9', label: '7#9', intervals: [0, 4, 7, 10, 15], aliases: ['7#9']),
  ChordQuality(id: 'dom7flat9', label: '7b9', intervals: [0, 4, 7, 10, 13], aliases: ['7b9']),
  ChordQuality(id: 'maj7sharp5', label: 'maj7#5', intervals: [0, 4, 8, 11], aliases: ['maj7#5']),
  ChordQuality(id: 'maj7flat5', label: 'maj7b5', intervals: [0, 4, 6, 11], aliases: ['maj7b5']),
];

final Map<String, ChordQuality> chordQualityById = {
  for (final q in chordQualities) q.id: q,
};

final List<({String alias, ChordQuality quality})> _qualityAliasTable = [
  for (final q in chordQualities)
    for (final alias in q.aliases) (alias: alias, quality: q),
]..sort((a, b) => b.alias.length.compareTo(a.alias.length));

/// Resolves a chord-quality suffix (e.g. `m7`) to its [ChordQuality].
/// Unknown suffixes fall back to major.
ChordQuality resolveChordQuality(String qualitySymbol) {
  if (qualitySymbol.isEmpty) return chordQualityById['major']!;
  for (final e in _qualityAliasTable) {
    if (e.alias.isNotEmpty && e.alias == qualitySymbol) return e.quality;
  }
  final lower = qualitySymbol.toLowerCase();
  for (final e in _qualityAliasTable) {
    if (e.alias.isNotEmpty && e.alias.toLowerCase() == lower) return e.quality;
  }
  return chordQualityById['major']!;
}

/// Simpler quality to fall back to when an instrument has no shape for the
/// requested one.
const Map<String, String> chordQualitySimplification = {
  'dim': 'minor', 'dim7': 'minor', 'aug': 'major', 'six': 'major',
  'm6': 'minor', 'six9': 'major', 'mMaj7': 'm7', 'm7b5': 'm7',
  'aug7': 'dom7', 'dom7b5': 'dom7', 'dom7sus4': 'sus4', 'dom7sus2': 'sus2',
  'nine': 'dom7', 'maj9': 'maj7', 'm9': 'm7', 'add9': 'major',
  'madd9': 'minor', 'eleven': 'dom7', 'm11': 'm7', 'thirteen': 'dom7',
  'm13': 'm7', 'dom7sharp9': 'dom7', 'dom7flat9': 'dom7',
  'maj7sharp5': 'maj7', 'maj7flat5': 'maj7',
};

/// Canonical chord-symbol suffix used to look up curated shapes.
const Map<String, String> chordQualityCanonicalSuffix = {
  'major': '', 'minor': 'm', 'dom7': '7', 'maj7': 'maj7', 'm7': 'm7',
  'sus4': 'sus4', 'sus2': 'sus2', 'six': '6', 'add9': 'add9', 'nine': '9',
};

// ── Chord symbol parsing ───────────────────────────────────────────────────

/// A parsed chord symbol: root, quality and optional slash bass.
class ParsedChord {
  const ParsedChord({
    required this.raw,
    required this.rootSemitone,
    required this.rootDisplay,
    required this.quality,
    this.bassSemitone,
  });

  /// The cleaned symbol as written (e.g. `C#m7/G#`).
  final String raw;
  final int rootSemitone;

  /// Canonical sharp-based root name.
  final String rootDisplay;
  final ChordQuality quality;
  final int? bassSemitone;

  bool get hasBass => bassSemitone != null;
}

/// Parses a chord symbol into a [ParsedChord], or null when the root is not
/// recognizable.
ParsedChord? parseChordSymbol(String chord) {
  final cleaned = chord.replaceAll(RegExp(r'[()]'), '').trim();
  if (cleaned.isEmpty) return null;

  final rootMatch = _rootPattern.firstMatch(cleaned);
  if (rootMatch == null) return null;

  final rootText = rootMatch.group(1)!;
  final rootSemitone = resolveRootSemitone(rootText);
  if (rootSemitone == null) return null;

  final remainder = cleaned.substring(rootText.length);

  // Slash-containing aliases (e.g. "6/9") before treating "/" as bass.
  final slashAliases = _qualityAliasTable
      .where((e) => e.alias.contains('/'))
      .toList()
    ..sort((a, b) => b.alias.length.compareTo(a.alias.length));

  String qualitySymbol;
  String? bassPart;
  ({String alias, ChordQuality quality})? slashAlias;
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

  final quality = resolveChordQuality(qualitySymbol);

  int? bassSemitone;
  if (bassPart != null && bassPart.isNotEmpty) {
    final bassMatch = _rootPattern.firstMatch(bassPart);
    if (bassMatch != null) {
      bassSemitone = resolveRootSemitone(bassMatch.group(1)!);
    }
  }

  return ParsedChord(
    raw: cleaned,
    rootSemitone: rootSemitone,
    rootDisplay: pitchClassName(rootSemitone),
    quality: quality,
    bassSemitone: bassSemitone,
  );
}
