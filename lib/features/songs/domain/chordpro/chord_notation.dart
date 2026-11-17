/// Chord symbol display conventions. Chord content and fingering use
/// international note names internally; conversions happen only for labels.
abstract class ChordNotationSystem {
  const ChordNotationSystem({required this.id, required this.name});

  final String id;
  final String name;
  Map<String, String> get noteNames;
}

class _MappedChordNotation extends ChordNotationSystem {
  const _MappedChordNotation({
    required super.id,
    required super.name,
    required this.noteNames,
  });

  @override
  final Map<String, String> noteNames;
}

class ChordNotationRegistry {
  static const international = _MappedChordNotation(
    id: 'international',
    name: 'International',
    noteNames: {
      'C': 'C', 'C#': 'C#', 'Db': 'Db', 'D': 'D', 'D#': 'D#', 'Eb': 'Eb',
      'E': 'E', 'F': 'F', 'F#': 'F#', 'Gb': 'Gb', 'G': 'G', 'G#': 'G#',
      'Ab': 'Ab', 'A': 'A', 'A#': 'A#', 'Bb': 'Bb', 'B': 'B',
    },
  );

  static const latin = _MappedChordNotation(
    id: 'latin',
    name: 'Latin',
    noteNames: {
      'C': 'Do', 'C#': 'Do#', 'Db': 'Reb', 'D': 'Re', 'D#': 'Re#',
      'Eb': 'Mib', 'E': 'Mi', 'F': 'Fa', 'F#': 'Fa#', 'Gb': 'Solb',
      'G': 'Sol', 'G#': 'Sol#', 'Ab': 'Lab', 'A': 'La', 'A#': 'La#',
      'Bb': 'Sib', 'B': 'Si',
    },
  );

  static const german = _MappedChordNotation(
    id: 'german',
    name: 'German',
    noteNames: {
      'C': 'C', 'C#': 'Cis', 'Db': 'Des', 'D': 'D', 'D#': 'Dis',
      'Eb': 'Es', 'E': 'E', 'F': 'F', 'F#': 'Fis', 'Gb': 'Ges', 'G': 'G',
      'G#': 'Gis', 'Ab': 'As', 'A': 'A', 'A#': 'Ais', 'Bb': 'B', 'B': 'H',
    },
  );

  static const sargam = _MappedChordNotation(
    id: 'sargam',
    name: 'Indian / Sargam',
    noteNames: {
      'C': 'Sa', 'C#': 'Sa#', 'Db': 'Reb', 'D': 'Re', 'D#': 'Re#',
      'Eb': 'Gab', 'E': 'Ga', 'F': 'Ma', 'F#': 'Ma#', 'Gb': 'Pab',
      'G': 'Pa', 'G#': 'Pa#', 'Ab': 'Dhab', 'A': 'Dha', 'A#': 'Dha#',
      'Bb': 'Nib', 'B': 'Ni',
    },
  );

  static const systems = [international, latin, german, sargam];

  static ChordNotationSystem resolve(String? id) => systems.firstWhere(
    (system) => system.id == id,
    orElse: () => international,
  );
}

class ChordNotationConverter {
  static final _chordPattern = RegExp(r'^([A-G](?:#|b)?)(.*)$');
  static final _bassPattern = RegExp(r'^(.*)/([A-G](?:#|b)?)$');

  static String formatNote(String note, ChordNotationSystem notation) =>
      notation.noteNames[note] ?? note;

  static String formatChord(String chord, ChordNotationSystem notation) {
    if (notation.id == ChordNotationRegistry.international.id) return chord;
    final rootMatch = _chordPattern.firstMatch(chord);
    if (rootMatch == null) return chord;

    final root = rootMatch.group(1)!;
    final suffix = rootMatch.group(2)!;
    final bassMatch = _bassPattern.firstMatch(suffix);
    if (bassMatch == null) {
      return '${formatNote(root, notation)}$suffix';
    }
    return '${formatNote(root, notation)}${bassMatch.group(1)!}/${formatNote(bassMatch.group(2)!, notation)}';
  }
}
