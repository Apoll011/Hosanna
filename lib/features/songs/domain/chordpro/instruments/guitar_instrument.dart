import 'fretted_instrument.dart';

/// Standard 6-string guitar in EADGBE tuning (low E → high E), strings
/// ordered low-E first to match the diagram.
class GuitarInstrument extends FrettedInstrument {
  const GuitarInstrument();

  @override
  String get id => 'guitar';

  @override
  String get label => 'Guitar';

  /// Low E, A, D, G, B, high E.
  @override
  List<int> get tuning => const [4, 9, 2, 7, 11, 4];

  /// Power chords use the root, fifth and octave on the two lowest strings.
  @override
  FrettedShape? powerChordShape(int rootSemitone) {
    final shift = ((rootSemitone - 4) % 12 + 12) % 12;
    return FrettedShape(
      [shift, shift + 2, shift + 2, -1, -1, -1],
      fingers: const [1, 3, 4, 0, 0, 0],
    );
  }

  @override
  Map<String, FrettedShape> get openShapes => _openShapes;

  @override
  Map<String, FrettedShape> get slashShapes => _slashShapes;

  @override
  Map<String, List<MovableShape>> get movableShapes => _movableShapes;
}

const Map<String, FrettedShape> _openShapes = {
  'C': FrettedShape([-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
  'Cm': FrettedShape([-1, 3, 5, 5, 4, 3], fingers: [0, 1, 3, 4, 2, 1], barre: 3),
  'C7': FrettedShape([-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0]),
  'Cmaj7': FrettedShape([-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0]),
  'Cm7': FrettedShape([-1, 3, 5, 3, 4, 3], fingers: [0, 1, 3, 1, 2, 1], barre: 3),
  'Csus4': FrettedShape([-1, 3, 3, 0, 1, 1], fingers: [0, 3, 4, 0, 1, 1]),
  'Csus2': FrettedShape([-1, 3, 0, 0, 1, 3], fingers: [0, 2, 0, 0, 1, 4]),
  'Cadd9': FrettedShape([-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0]),
  'C9': FrettedShape([-1, 3, 2, 3, 3, 3], fingers: [0, 2, 1, 3, 3, 3], barre: 3),
  'C6': FrettedShape([-1, 3, 2, 2, 1, 0], fingers: [0, 4, 2, 3, 1, 0]),

  'C#': FrettedShape([-1, 4, 6, 6, 6, 4], fingers: [0, 1, 2, 3, 4, 1], barre: 4),
  'C#m': FrettedShape([-1, 4, 6, 6, 5, 4], fingers: [0, 1, 3, 4, 2, 1], barre: 4),
  'C#7': FrettedShape([-1, 4, 3, 4, 2, -1], fingers: [0, 3, 2, 4, 1, 0]),
  'C#maj7': FrettedShape([-1, 4, 6, 5, 6, 4], fingers: [0, 1, 3, 2, 4, 1], barre: 4),
  'C#m7': FrettedShape([-1, 4, 6, 4, 5, 4], fingers: [0, 1, 3, 1, 2, 1], barre: 4),

  'D': FrettedShape([-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
  'Dm': FrettedShape([-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
  'D7': FrettedShape([-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3]),
  'Dmaj7': FrettedShape([-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1], barre: 2),
  'Dm7': FrettedShape([-1, -1, 0, 2, 1, 1], fingers: [0, 0, 0, 2, 1, 1], barre: 1),
  'Dsus4': FrettedShape([-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 2, 3]),
  'Dsus2': FrettedShape([-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 2, 0]),
  'Dadd9': FrettedShape([-1, -1, 0, 2, 5, 2], fingers: [0, 0, 0, 1, 4, 2]),
  'D6': FrettedShape([-1, -1, 0, 2, 0, 2], fingers: [0, 0, 0, 2, 0, 3]),
  'D9': FrettedShape([-1, -1, 0, 2, 1, 0], fingers: [0, 0, 0, 2, 1, 0]),

  'Eb': FrettedShape([-1, 6, 8, 8, 8, 6], fingers: [0, 1, 2, 3, 4, 1], barre: 6),
  'Ebm': FrettedShape([-1, 6, 8, 8, 7, 6], fingers: [0, 1, 3, 4, 2, 1], barre: 6),
  'Eb7': FrettedShape([-1, 6, 5, 6, 4, -1], fingers: [0, 3, 2, 4, 1, 0]),

  'E': FrettedShape([0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
  'Em': FrettedShape([0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0]),
  'E7': FrettedShape([0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0]),
  'Emaj7': FrettedShape([0, 2, 1, 1, 0, 0], fingers: [0, 3, 1, 2, 0, 0]),
  'Em7': FrettedShape([0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0]),
  'Esus4': FrettedShape([0, 2, 2, 2, 0, 0], fingers: [0, 2, 3, 4, 0, 0]),
  'Eadd9': FrettedShape([0, 2, 4, 1, 0, 0], fingers: [0, 2, 4, 1, 0, 0]),
  'E6': FrettedShape([0, 2, 2, 1, 2, 0], fingers: [0, 2, 3, 1, 4, 0]),
  'E9': FrettedShape([0, 2, 0, 1, 3, 0], fingers: [0, 2, 0, 1, 4, 0]),

  'F': FrettedShape([1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1),
  'Fm': FrettedShape([1, 3, 3, 1, 1, 1], fingers: [1, 3, 4, 1, 1, 1], barre: 1),
  'F7': FrettedShape([1, 3, 1, 2, 1, 1], fingers: [1, 3, 1, 2, 1, 1], barre: 1),
  'Fmaj7': FrettedShape([-1, 3, 3, 2, 1, 0], fingers: [0, 3, 4, 2, 1, 0]),
  'Fm7': FrettedShape([1, 3, 1, 1, 1, 1], fingers: [1, 3, 1, 1, 1, 1], barre: 1),

  'F#': FrettedShape([2, 4, 4, 3, 2, 2], fingers: [1, 3, 4, 2, 1, 1], barre: 2),
  'F#m': FrettedShape([2, 4, 4, 2, 2, 2], fingers: [1, 3, 4, 1, 1, 1], barre: 2),
  'F#7': FrettedShape([2, 4, 2, 3, 2, 2], fingers: [1, 3, 1, 2, 1, 1], barre: 2),
  'F#m7': FrettedShape([2, 4, 2, 2, 2, 2], fingers: [1, 3, 1, 1, 1, 1], barre: 2),

  'G': FrettedShape([3, 2, 0, 0, 3, 3], fingers: [2, 1, 0, 0, 3, 4]),
  'Gm': FrettedShape([3, 5, 5, 3, 3, 3], fingers: [1, 3, 4, 1, 1, 1], barre: 3),
  'G7': FrettedShape([3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1]),
  'Gmaj7': FrettedShape([3, 2, 0, 0, 0, 2], fingers: [2, 1, 0, 0, 0, 3]),
  'Gm7': FrettedShape([3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3),
  'Gsus4': FrettedShape([3, 3, 0, 0, 3, 3], fingers: [2, 3, 0, 0, 1, 4]),
  'Gadd9': FrettedShape([3, 2, 0, 2, 0, 3], fingers: [2, 1, 0, 3, 0, 4]),
  'G6': FrettedShape([3, 2, 0, 0, 0, 0], fingers: [3, 2, 0, 0, 0, 0]),

  'Ab': FrettedShape([4, 6, 6, 5, 4, 4], fingers: [1, 3, 4, 2, 1, 1], barre: 4),
  'Abm': FrettedShape([4, 6, 6, 4, 4, 4], fingers: [1, 3, 4, 1, 1, 1], barre: 4),

  'A': FrettedShape([-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
  'Am': FrettedShape([-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
  'A7': FrettedShape([-1, 0, 2, 0, 2, 0], fingers: [0, 0, 1, 0, 2, 0]),
  'Amaj7': FrettedShape([-1, 0, 2, 1, 2, 0], fingers: [0, 0, 2, 1, 3, 0]),
  'Am7': FrettedShape([-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0]),
  'Asus4': FrettedShape([-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 4, 0]),
  'Asus2': FrettedShape([-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0]),
  'Aadd9': FrettedShape([-1, 0, 2, 4, 2, 0], fingers: [0, 0, 1, 3, 2, 0]),
  'A6': FrettedShape([-1, 0, 2, 2, 2, 2], fingers: [0, 0, 1, 1, 1, 1], barre: 2),
  'A9': FrettedShape([-1, 0, 2, 4, 2, 3], fingers: [0, 0, 1, 3, 2, 4]),

  'Bb': FrettedShape([-1, 1, 3, 3, 3, 1], fingers: [0, 1, 2, 3, 4, 1], barre: 1),
  'Bbm': FrettedShape([-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1),
  'Bb7': FrettedShape([-1, 1, 3, 1, 3, 1], fingers: [0, 1, 3, 1, 4, 1], barre: 1),

  'B': FrettedShape([-1, 2, 4, 4, 4, 2], fingers: [0, 1, 2, 3, 4, 1], barre: 2),
  'Bm': FrettedShape([-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2),
  'B7': FrettedShape([-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4]),
  'Bmaj7': FrettedShape([-1, 2, 4, 3, 4, 2], fingers: [0, 1, 3, 2, 4, 1], barre: 2),
  'Bm7': FrettedShape([-1, 2, 4, 2, 3, 2], fingers: [0, 1, 3, 1, 2, 1], barre: 2),
};

const Map<String, FrettedShape> _slashShapes = {
  'C/E': FrettedShape([0, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
  'C/G': FrettedShape([3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0]),
  'C/Bb': FrettedShape([-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0]),
  'D/F#': FrettedShape([2, 0, 0, 2, 3, 2], fingers: [1, 0, 0, 2, 4, 3]),
  'D/A': FrettedShape([-1, 0, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
  'E/G#': FrettedShape([4, 2, 2, 1, 0, 0], fingers: [4, 2, 3, 1, 0, 0]),
  'E/B': FrettedShape([0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
  'F/A': FrettedShape([-1, 0, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1]),
  'F/C': FrettedShape([8, 8, 10, 10, 10, 8], fingers: [1, 1, 2, 3, 4, 1], barre: 8),
  'G/B': FrettedShape([-1, 2, 0, 0, 3, 3], fingers: [0, 1, 0, 0, 3, 4]),
  'G/D': FrettedShape([-1, -1, 0, 0, 3, 3], fingers: [0, 0, 0, 0, 3, 4]),
  'G/F': FrettedShape([3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1]),
  'A/C#': FrettedShape([-1, 4, 2, 2, 2, -1], fingers: [0, 4, 1, 1, 1, 0]),
  'A/E': FrettedShape([0, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
  'A/G': FrettedShape([3, 0, 2, 2, 2, 0], fingers: [4, 0, 1, 2, 3, 0]),
  'B/D#': FrettedShape([-1, 6, 4, 4, 4, -1], fingers: [0, 3, 1, 1, 1, 0]),
  'B/F#': FrettedShape([2, 2, 4, 4, 4, 2], fingers: [1, 1, 2, 3, 4, 1], barre: 2),
  'Am/G': FrettedShape([3, 0, 2, 2, 1, 0], fingers: [4, 0, 2, 3, 1, 0]),
  'Am/F#': FrettedShape([2, 0, 2, 2, 1, 0], fingers: [2, 0, 3, 4, 1, 0]),
  'Am/E': FrettedShape([0, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
  'Dm/C': FrettedShape([-1, 3, 0, 2, 3, 1], fingers: [0, 3, 0, 2, 4, 1]),
  'Dm/B': FrettedShape([-1, 2, 0, 2, 3, 1], fingers: [0, 2, 0, 3, 4, 1]),
  'Dm/A': FrettedShape([-1, 0, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
  'Dm/F': FrettedShape([1, -1, 0, 2, 3, 1], fingers: [1, 0, 0, 2, 4, 3]),
  'Em/D': FrettedShape([0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0]),
  'Em/C#': FrettedShape([0, 4, 2, 0, 0, 0], fingers: [0, 3, 1, 0, 0, 0]),
  'Em/B': FrettedShape([7, 7, 9, 9, 8, 7], fingers: [1, 1, 3, 4, 2, 1], barre: 7),
  'Em/G': FrettedShape([3, 2, 2, 0, 0, 0], fingers: [3, 1, 2, 0, 0, 0]),
  'Fm/Eb': FrettedShape([-1, 6, 6, 5, 6, -1], fingers: [0, 2, 3, 1, 4, 0]),
  'Gm/F': FrettedShape([3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3),
  'Bm/A': FrettedShape([-1, 0, 4, 4, 3, 2], fingers: [0, 0, 3, 4, 2, 1]),
};

/// The movable E-form and A-form barre shapes (CAGED's two most useful
/// forms), keyed by chord-quality id.
const Map<String, List<MovableShape>> _movableShapes = {
  'major': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 2, 1, 0, 0], fingers: [1, 3, 4, 2, 1, 1], barreFret: 0, openFingers: [0, 2, 3, 1, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 1, 3, 4, 4, 1], barreFret: 0, openFingers: [0, 0, 1, 2, 3, 0]),
  ],
  'minor': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 2, 0, 0, 0], fingers: [1, 3, 4, 1, 1, 1], barreFret: 0, openFingers: [0, 2, 3, 0, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 1, 3, 4, 2, 1], barreFret: 0, openFingers: [0, 0, 2, 3, 1, 0]),
  ],
  'dom7': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 0, 1, 0, 0], fingers: [1, 3, 1, 2, 1, 1], barreFret: 0, openFingers: [0, 2, 0, 1, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 1, 3, 1, 4, 1], barreFret: 0, openFingers: [0, 0, 1, 0, 2, 0]),
  ],
  'm7': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 0, 0, 0, 0], fingers: [1, 3, 1, 1, 1, 1], barreFret: 0, openFingers: [0, 2, 0, 0, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 1, 3, 1, 2, 1], barreFret: 0, openFingers: [0, 0, 2, 0, 1, 0]),
  ],
  'maj7': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 1, 1, 0, 0], fingers: [1, 3, 2, 2, 1, 1], barreFret: 0, openFingers: [0, 3, 1, 2, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 1, 2, 0], fingers: [0, 1, 3, 2, 4, 1], barreFret: 0, openFingers: [0, 0, 2, 1, 3, 0]),
  ],
  'sus4': [
    MovableShape(rootSemitone: 4, frets: [0, 2, 2, 2, 0, 0], fingers: [1, 3, 4, 4, 1, 1], barreFret: 0, openFingers: [0, 2, 3, 4, 0, 0]),
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 1, 3, 3, 4, 1], barreFret: 0, openFingers: [0, 0, 1, 2, 4, 0]),
  ],
  'sus2': [
    MovableShape(rootSemitone: 9, frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 1, 3, 4, 1, 1], barreFret: 0, openFingers: [0, 0, 1, 2, 0, 0]),
  ],
};
