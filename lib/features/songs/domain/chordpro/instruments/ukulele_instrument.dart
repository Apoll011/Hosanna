import 'fretted_instrument.dart';

/// Soprano/concert/tenor ukulele in standard re-entrant GCEA tuning.
///
/// Strings are ordered G → C → E → A to match how ukulele diagrams are drawn
/// (the G string is leftmost even though it is not the lowest pitch).
class UkuleleInstrument extends FrettedInstrument {
  const UkuleleInstrument();

  @override
  String get id => 'ukulele';

  @override
  String get label => 'Ukulele';

  /// G4, C4, E4, A4.
  @override
  List<int> get tuning => const [7, 0, 4, 9];

  /// Root on the C string and its fifth on the G string, two frets apart in
  /// pitch but on the same fret number.
  @override
  FrettedShape? powerChordShape(int rootSemitone) {
    final fret = ((rootSemitone % 12) + 12) % 12;
    return FrettedShape(
      [fret, fret, -1, -1],
      fingers: fret == 0 ? null : const [1, 1, 0, 0],
    );
  }

  @override
  Map<String, FrettedShape> get openShapes => _openShapes;

  /// Ukulele slash chords fall back to their parent chord (the movable engine
  /// never produces incorrect bass notes), so none are curated.
  @override
  Map<String, FrettedShape> get slashShapes => const {};

  @override
  Map<String, List<MovableShape>> get movableShapes => _movableShapes;
}

const Map<String, FrettedShape> _openShapes = {
  'C': FrettedShape([0, 0, 0, 3], fingers: [0, 0, 0, 3]),
  'Cm': FrettedShape([0, 3, 3, 3], fingers: [0, 1, 1, 1], barre: 3),
  'C7': FrettedShape([0, 0, 0, 1], fingers: [0, 0, 0, 1]),
  'Cmaj7': FrettedShape([0, 0, 0, 2], fingers: [0, 0, 0, 2]),
  'Cm7': FrettedShape([3, 3, 3, 3], fingers: [1, 1, 1, 1], barre: 3),
  'Csus4': FrettedShape([0, 0, 1, 3], fingers: [0, 0, 1, 3]),
  'Csus2': FrettedShape([0, 2, 3, 3], fingers: [0, 1, 2, 3]),
  'Cadd9': FrettedShape([0, 2, 0, 3], fingers: [0, 2, 0, 3]),
  'C6': FrettedShape([0, 0, 0, 0]),

  'D': FrettedShape([2, 2, 2, 0], fingers: [1, 2, 3, 0]),
  'Dm': FrettedShape([2, 2, 1, 0], fingers: [2, 3, 1, 0]),
  'D7': FrettedShape([2, 2, 2, 3], fingers: [1, 2, 3, 4]),
  'Dmaj7': FrettedShape([2, 2, 2, 5], fingers: [1, 2, 3, 4]),
  'Dm7': FrettedShape([2, 2, 1, 3], fingers: [2, 3, 1, 4]),
  'Dsus4': FrettedShape([2, 2, 3, 0], fingers: [1, 2, 3, 0]),
  'Dsus2': FrettedShape([2, 2, 0, 0], fingers: [1, 2, 0, 0]),

  'E': FrettedShape([4, 4, 4, 2], fingers: [3, 3, 3, 1], barre: 4),
  'Em': FrettedShape([0, 4, 3, 2], fingers: [0, 3, 2, 1]),
  'E7': FrettedShape([1, 2, 0, 2], fingers: [1, 2, 0, 3]),
  'Em7': FrettedShape([0, 2, 0, 2], fingers: [0, 2, 0, 3]),
  'Esus4': FrettedShape([4, 4, 5, 2], fingers: [2, 3, 4, 1]),

  'F': FrettedShape([2, 0, 1, 0], fingers: [2, 0, 1, 0]),
  'Fm': FrettedShape([1, 0, 1, 3], fingers: [1, 0, 2, 4]),
  'F7': FrettedShape([2, 3, 1, 3], fingers: [2, 3, 1, 4]),
  'Fmaj7': FrettedShape([2, 4, 1, 3], fingers: [2, 4, 1, 3]),
  'Fm7': FrettedShape([1, 3, 1, 3], fingers: [1, 3, 1, 3]),

  'G': FrettedShape([0, 2, 3, 2], fingers: [0, 1, 3, 2]),
  'Gm': FrettedShape([0, 2, 3, 1], fingers: [0, 2, 3, 1]),
  'G7': FrettedShape([0, 2, 1, 2], fingers: [0, 3, 1, 2]),
  'Gmaj7': FrettedShape([0, 2, 2, 2], fingers: [0, 1, 1, 1], barre: 2),
  'Gm7': FrettedShape([0, 2, 1, 1], fingers: [0, 3, 1, 1]),
  'Gsus4': FrettedShape([0, 2, 3, 3], fingers: [0, 1, 2, 3]),
  'Gsus2': FrettedShape([0, 2, 3, 0], fingers: [0, 1, 3, 0]),

  'A': FrettedShape([2, 1, 0, 0], fingers: [2, 1, 0, 0]),
  'Am': FrettedShape([2, 0, 0, 0], fingers: [2, 0, 0, 0]),
  'A7': FrettedShape([0, 1, 0, 0], fingers: [0, 1, 0, 0]),
  'Amaj7': FrettedShape([1, 1, 0, 0], fingers: [1, 1, 0, 0]),
  'Am7': FrettedShape([0, 0, 0, 0]),
  'Asus4': FrettedShape([2, 2, 0, 0], fingers: [1, 2, 0, 0]),
  'Asus2': FrettedShape([4, 4, 0, 0], fingers: [2, 3, 0, 0]),

  'Bb': FrettedShape([3, 2, 1, 1], fingers: [3, 2, 1, 1]),
  'Bbm': FrettedShape([3, 1, 1, 1], fingers: [3, 1, 1, 1]),
  'Bb7': FrettedShape([1, 2, 1, 1], fingers: [1, 2, 1, 1]),

  'B': FrettedShape([4, 3, 2, 2], fingers: [4, 3, 2, 2]),
  'Bm': FrettedShape([4, 2, 2, 2], fingers: [4, 1, 1, 1], barre: 2),
  'B7': FrettedShape([2, 3, 2, 2], fingers: [1, 3, 2, 2]),
};

/// Four movable forms (C, A, G, E — the ukulele's CAGED equivalent) per
/// supported quality. `barreFret` is the barre position in the base shape, so
/// it follows the shape as it is transposed.
const Map<String, List<MovableShape>> _movableShapes = {
  'major': [
    MovableShape(rootSemitone: 0, frets: [0, 0, 0, 3], fingers: [1, 1, 1, 3], barreFret: 0, openFingers: [0, 0, 0, 3]),
    MovableShape(rootSemitone: 9, frets: [2, 1, 0, 0], fingers: [3, 2, 1, 1], barreFret: 0, openFingers: [2, 1, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 3, 2], fingers: [0, 1, 3, 2]),
    MovableShape(rootSemitone: 4, frets: [4, 4, 4, 2], fingers: [3, 3, 3, 1], barreFret: 4),
  ],
  'minor': [
    MovableShape(rootSemitone: 0, frets: [0, 3, 3, 3], fingers: [0, 1, 1, 1], barreFret: 3),
    MovableShape(rootSemitone: 9, frets: [2, 0, 0, 0], fingers: [2, 0, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 3, 1], fingers: [0, 2, 3, 1]),
    MovableShape(rootSemitone: 2, frets: [2, 2, 1, 0], fingers: [2, 3, 1, 0]),
    MovableShape(rootSemitone: 4, frets: [0, 4, 3, 2], fingers: [0, 3, 2, 1]),
    MovableShape(rootSemitone: 11, frets: [4, 2, 2, 2], fingers: [4, 1, 1, 1], barreFret: 2),
  ],
  'dom7': [
    MovableShape(rootSemitone: 0, frets: [0, 0, 0, 1], fingers: [1, 1, 1, 2], barreFret: 0, openFingers: [0, 0, 0, 1]),
    MovableShape(rootSemitone: 9, frets: [0, 1, 0, 0], fingers: [0, 1, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 1, 2], fingers: [0, 3, 1, 2]),
    MovableShape(rootSemitone: 4, frets: [1, 2, 0, 2], fingers: [1, 2, 0, 3]),
    MovableShape(rootSemitone: 2, frets: [2, 2, 2, 3], fingers: [1, 2, 3, 4]),
  ],
  'maj7': [
    MovableShape(rootSemitone: 0, frets: [0, 0, 0, 2], fingers: [1, 1, 1, 3], barreFret: 0, openFingers: [0, 0, 0, 2]),
    MovableShape(rootSemitone: 9, frets: [1, 1, 0, 0], fingers: [1, 1, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 2, 2], fingers: [0, 1, 1, 1], barreFret: 2),
    MovableShape(rootSemitone: 5, frets: [2, 4, 1, 3], fingers: [2, 4, 1, 3]),
  ],
  'm7': [
    MovableShape(rootSemitone: 9, frets: [0, 0, 0, 0], fingers: [1, 1, 1, 1], barreFret: 0, openFingers: [0, 0, 0, 0]),
    MovableShape(rootSemitone: 2, frets: [2, 2, 1, 3], fingers: [2, 3, 1, 4]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 1, 1], fingers: [0, 3, 1, 1]),
    MovableShape(rootSemitone: 0, frets: [3, 3, 3, 3], fingers: [1, 1, 1, 1], barreFret: 3),
    MovableShape(rootSemitone: 4, frets: [0, 2, 0, 2], fingers: [0, 2, 0, 3]),
    MovableShape(rootSemitone: 5, frets: [1, 3, 1, 3], fingers: [1, 3, 1, 3]),
  ],
  'sus4': [
    MovableShape(rootSemitone: 0, frets: [0, 0, 1, 3], fingers: [0, 0, 1, 3]),
    MovableShape(rootSemitone: 9, frets: [2, 2, 0, 0], fingers: [1, 2, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 3, 3], fingers: [0, 1, 2, 3]),
    MovableShape(rootSemitone: 4, frets: [4, 4, 5, 2], fingers: [2, 3, 4, 1]),
  ],
  'sus2': [
    MovableShape(rootSemitone: 0, frets: [0, 2, 3, 3], fingers: [0, 1, 2, 3]),
    MovableShape(rootSemitone: 2, frets: [2, 2, 0, 0], fingers: [1, 2, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 3, 0], fingers: [0, 1, 3, 0]),
    MovableShape(rootSemitone: 9, frets: [4, 4, 0, 0], fingers: [2, 3, 0, 0]),
  ],
};
