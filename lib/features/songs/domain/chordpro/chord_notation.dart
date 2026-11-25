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
      'C': 'C',
      'C#': 'C#',
      'Cb': 'Cb',
      'D': 'D',
      'D#': 'D#',
      'Db': 'Db',
      'E': 'E',
      'E#': 'E#',
      'Eb': 'Eb',
      'F': 'F',
      'F#': 'F#',
      'Fb': 'Fb',
      'G': 'G',
      'G#': 'G#',
      'Gb': 'Gb',
      'A': 'A',
      'A#': 'A#',
      'Ab': 'Ab',
      'B': 'B',
      'B#': 'B#',
      'Bb': 'Bb',
    },
  );

  static const latin = _MappedChordNotation(
    id: 'latin',
    name: 'Latin',
    noteNames: {
      'C': 'Do',
      'C#': 'Do#',
      'Cb': 'Dob',
      'D': 'Re',
      'D#': 'Re#',
      'Db': 'Reb',
      'E': 'Mi',
      'E#': 'Mi#',
      'Eb': 'Mib',
      'F': 'Fa',
      'F#': 'Fa#',
      'Fb': 'Fab',
      'G': 'Sol',
      'G#': 'Sol#',
      'Gb': 'Solb',
      'A': 'La',
      'A#': 'La#',
      'Ab': 'Lab',
      'B': 'Si',
      'B#': 'Si#',
      'Bb': 'Sib',
    },
  );

  static const german = _MappedChordNotation(
    id: 'german',
    name: 'German',
    noteNames: {
      'C': 'C',
      'C#': 'Cis',
      'Cb': 'Ces',
      'D': 'D',
      'D#': 'Dis',
      'Db': 'Des',
      'E': 'E',
      'E#': 'Eis',
      'Eb': 'Es',
      'F': 'F',
      'F#': 'Fis',
      'Fb': 'Fes',
      'G': 'G',
      'G#': 'Gis',
      'Gb': 'Ges',
      'A': 'A',
      'A#': 'Ais',
      'Ab': 'As',
      'B': 'H',
      'B#': 'His',
      'Bb': 'B',
    },
  );

  // Sargam is tonic-relative; this fixed-pitch display uses C as Sa.
  static const sargam = _MappedChordNotation(
    id: 'sargam',
    name: 'Indian / Sargam',
    noteNames: {
      'C': 'Sa',
      'C#': 're',
      'Cb': 'Ni',
      'D': 'Re',
      'D#': 'ga',
      'Db': 're',
      'E': 'Ga',
      'E#': 'Ma',
      'Eb': 'ga',
      'F': 'Ma',
      'F#': 'Ma#',
      'Fb': 'Ga',
      'G': 'Pa',
      'G#': 'dha',
      'Gb': 'Ma#',
      'A': 'Dha',
      'A#': 'ni',
      'Ab': 'dha',
      'B': 'Ni',
      'B#': 'Sa',
      'Bb': 'ni',
    },
  );

  static const nashville = _MappedChordNotation(
    id: 'nashville',
    name: 'Nashville',
    noteNames: {},
  );

  static const systems = [international, latin, german, sargam, nashville];

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

  static String formatChord(
    String chord,
    ChordNotationSystem notation, {
    String? key,
  }) {
    if (notation.id == ChordNotationRegistry.nashville.id) {
      if (key == null) return chord;
      return _formatNashvilleChord(chord, key);
    }
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

  static String _formatNashvilleChord(String chord, String key) {
    final rootMatch = _chordPattern.firstMatch(chord);
    final keyMatch = _chordPattern.firstMatch(key);
    if (rootMatch == null || keyMatch == null) return chord;
    final suffix = rootMatch.group(2)!;
    final bassMatch = _bassPattern.firstMatch(suffix);

    String accidental(int pitch) {
      final interval = (pitch % 12 + 12) % 12;
      const degrees = <int, String>{
        0: '1',
        1: '♭2',
        2: '2',
        3: '♭3',
        4: '3',
        5: '4',
        6: '♯4',
        7: '5',
        8: '♭6',
        9: '6',
        10: '♭7',
        11: '7',
      };
      return degrees[interval]!
          .replaceAll('♭', 'b')
          .replaceAll('♯', '#'); //TODO: See if the replace should stay or go
    }

    final keyPitch = _pitchClass(keyMatch.group(1)!);
    String degree(String note) => accidental(_pitchClass(note) - keyPitch);
    if (bassMatch == null) return '${degree(rootMatch.group(1)!)}$suffix';
    return '${degree(rootMatch.group(1)!)}${bassMatch.group(1)!}/${degree(bassMatch.group(2)!)}';
  }

  static int _pitchClass(String note) {
    const naturals = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final value = naturals[note[0]];
    if (value == null) return 0;
    return value +
        (note.endsWith('#')
            ? 1
            : note.endsWith('b')
            ? -1
            : 0);
  }
}
