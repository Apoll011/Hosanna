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

  @override
  Map<String, FrettedShape> get slashShapes => _slashShapes;

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
  'C9': FrettedShape([0, 2, 0, 1], fingers: [0, 2, 0, 1]),
  'Cm6': FrettedShape([0, 3, 5, 3], fingers: [0, 1, 3, 1]),
  'Cdim': FrettedShape([5, 3, 2, 3], fingers: [4, 2, 1, 3]),
  'Caug': FrettedShape([1, 0, 0, 3], fingers: [1, 0, 0, 3]),
  'C7sus4': FrettedShape([0, 0, 1, 1], fingers: [0, 0, 1, 1]),

  'C#': FrettedShape([1, 1, 1, 4], fingers: [1, 1, 1, 4], barre: 1),
  'C#m': FrettedShape([1, 4, 4, 4], fingers: [1, 2, 2, 2], barre: 4),
  'C#7': FrettedShape([1, 1, 1, 2], fingers: [1, 1, 1, 2], barre: 1),
  'C#maj7': FrettedShape([1, 1, 1, 3], fingers: [1, 1, 1, 3], barre: 1),
  'C#m7': FrettedShape([4, 4, 4, 4], fingers: [1, 1, 1, 1], barre: 4),
  'C#sus4': FrettedShape([1, 1, 2, 4], fingers: [1, 1, 2, 4], barre: 1),
  'C#dim': FrettedShape([0, 1, 0, 4], fingers: [0, 1, 0, 4]),

  'D': FrettedShape([2, 2, 2, 0], fingers: [1, 2, 3, 0]),
  'Dm': FrettedShape([2, 2, 1, 0], fingers: [2, 3, 1, 0]),
  'D7': FrettedShape([2, 2, 2, 3], fingers: [1, 2, 3, 4]),
  'Dmaj7': FrettedShape([2, 2, 2, 4], fingers: [1, 1, 1, 3], barre: 2),
  'Dm7': FrettedShape([2, 2, 1, 3], fingers: [2, 3, 1, 4]),
  'Dsus4': FrettedShape([2, 2, 3, 0], fingers: [1, 2, 3, 0]),
  'Dsus2': FrettedShape([2, 2, 0, 0], fingers: [1, 2, 0, 0]),
  'Dadd9': FrettedShape([2, 4, 2, 0], fingers: [1, 3, 2, 0]),
  'D6': FrettedShape([2, 2, 2, 2], fingers: [1, 1, 1, 1], barre: 2),
  'Dm6': FrettedShape([2, 2, 1, 2], fingers: [2, 3, 1, 4]),
  'D9': FrettedShape([2, 4, 2, 3], fingers: [1, 3, 1, 2]),
  'Ddim': FrettedShape([1, 2, 1, 2], fingers: [1, 3, 2, 4]),
  'Daug': FrettedShape([3, 2, 2, 1], fingers: [4, 2, 3, 1]),
  'D7sus4': FrettedShape([2, 2, 3, 3], fingers: [1, 1, 2, 3], barre: 2),

  'Eb': FrettedShape([0, 3, 3, 1], fingers: [0, 2, 3, 1]),
  'Ebm': FrettedShape([3, 3, 2, 1], fingers: [3, 4, 2, 1]),
  'Eb7': FrettedShape([3, 3, 3, 4], fingers: [1, 1, 1, 2], barre: 3),
  'Ebmaj7': FrettedShape([3, 3, 3, 5], fingers: [1, 1, 1, 3], barre: 3),
  'Ebm7': FrettedShape([3, 3, 2, 4], fingers: [2, 3, 1, 4]),
  'Ebsus4': FrettedShape([1, 3, 4, 1], fingers: [1, 2, 4, 1]),
  'Eb6': FrettedShape([0, 3, 3, 3], fingers: [0, 1, 1, 1], barre: 3),
  'Ebdim': FrettedShape([2, 3, 2, 3], fingers: [1, 3, 2, 4]),

  'E': FrettedShape([4, 4, 4, 2], fingers: [3, 3, 3, 1], barre: 4),
  'Em': FrettedShape([0, 4, 3, 2], fingers: [0, 3, 2, 1]),
  'E7': FrettedShape([1, 2, 0, 2], fingers: [1, 2, 0, 3]),
  'Emaj7': FrettedShape([1, 3, 0, 2], fingers: [1, 3, 0, 2]),
  'Em7': FrettedShape([0, 2, 0, 2], fingers: [0, 2, 0, 3]),
  'Esus4': FrettedShape([4, 4, 5, 2], fingers: [2, 3, 4, 1]),
  'Esus2': FrettedShape([4, 4, 2, 2], fingers: [3, 4, 1, 1], barre: 2),
  'Eadd9': FrettedShape([1, 4, 0, 2], fingers: [1, 4, 0, 2]),
  'E6': FrettedShape([4, 4, 4, 4], fingers: [1, 1, 1, 1], barre: 4),
  'Em6': FrettedShape([0, 4, 0, 2], fingers: [0, 3, 0, 1]),
  'E9': FrettedShape([1, 2, 2, 2], fingers: [1, 2, 2, 2]),
  'Edim': FrettedShape([0, 4, 3, 1], fingers: [0, 3, 2, 1]),
  'Eaug': FrettedShape([0, 1, 0, 3], fingers: [0, 1, 0, 3]),
  'E7sus4': FrettedShape([2, 2, 0, 2], fingers: [1, 2, 0, 3]),

  'F': FrettedShape([2, 0, 1, 0], fingers: [2, 0, 1, 0]),
  'Fm': FrettedShape([1, 0, 1, 3], fingers: [1, 0, 2, 4]),
  'F7': FrettedShape([2, 3, 1, 3], fingers: [2, 3, 1, 4]),
  'Fmaj7': FrettedShape([2, 4, 1, 3], fingers: [2, 4, 1, 3]),
  'Fm7': FrettedShape([1, 3, 1, 3], fingers: [1, 3, 1, 3]),
  'Fsus4': FrettedShape([3, 0, 1, 0], fingers: [3, 0, 1, 0]),
  'Fsus2': FrettedShape([0, 5, 3, 3], fingers: [0, 3, 1, 1]),
  'Fadd9': FrettedShape([0, 0, 1, 0], fingers: [0, 0, 1, 0]),
  'F6': FrettedShape([2, 2, 1, 3], fingers: [2, 3, 1, 4]),
  'Fm6': FrettedShape([1, 2, 1, 3], fingers: [1, 2, 1, 3]),
  'F9': FrettedShape([0, 3, 1, 0], fingers: [0, 3, 1, 0]),
  'Fdim': FrettedShape([1, 2, 1, 2], fingers: [1, 3, 2, 4]),
  'Faug': FrettedShape([2, 1, 1, 0], fingers: [3, 1, 2, 0]),

  'F#': FrettedShape([3, 1, 2, 1], fingers: [3, 1, 2, 1]),
  'F#m': FrettedShape([2, 1, 2, 0], fingers: [2, 1, 3, 0]),
  'F#7': FrettedShape([3, 4, 2, 4], fingers: [2, 3, 1, 4]),
  'F#maj7': FrettedShape([3, 5, 2, 4], fingers: [2, 4, 1, 3]),
  'F#m7': FrettedShape([2, 4, 2, 4], fingers: [1, 3, 1, 4]),
  'F#sus4': FrettedShape([4, 1, 2, 1], fingers: [4, 1, 2, 1]),
  'F#6': FrettedShape([3, 3, 2, 4], fingers: [2, 3, 1, 4]),
  'F#dim': FrettedShape([2, 3, 2, 3], fingers: [1, 3, 2, 4]),

  'G': FrettedShape([0, 2, 3, 2], fingers: [0, 1, 3, 2]),
  'Gm': FrettedShape([0, 2, 3, 1], fingers: [0, 2, 3, 1]),
  'G7': FrettedShape([0, 2, 1, 2], fingers: [0, 3, 1, 2]),
  'Gmaj7': FrettedShape([0, 2, 2, 2], fingers: [0, 1, 1, 1], barre: 2),
  'Gm7': FrettedShape([0, 2, 1, 1], fingers: [0, 3, 1, 1]),
  'Gsus4': FrettedShape([0, 2, 3, 3], fingers: [0, 1, 2, 3]),
  'Gsus2': FrettedShape([0, 2, 3, 0], fingers: [0, 1, 3, 0]),
  'Gadd9': FrettedShape([0, 2, 5, 2], fingers: [0, 1, 4, 2]),
  'G6': FrettedShape([0, 2, 0, 2], fingers: [0, 1, 0, 2]),
  'Gm6': FrettedShape([0, 2, 0, 1], fingers: [0, 2, 0, 1]),
  'G9': FrettedShape([0, 2, 1, 0], fingers: [0, 2, 1, 0]),
  'Gm9': FrettedShape([0, 2, 1, 1], fingers: [0, 3, 1, 1]),
  'Gdim': FrettedShape([0, 1, 3, 1], fingers: [0, 1, 3, 1]),
  'Gaug': FrettedShape([0, 3, 3, 2], fingers: [0, 2, 3, 1]),
  'G7sus4': FrettedShape([0, 2, 1, 3], fingers: [0, 2, 1, 3]),

  'Ab': FrettedShape([5, 3, 4, 3], fingers: [4, 1, 3, 2]),
  'Abm': FrettedShape([1, 3, 4, 2], fingers: [1, 3, 4, 2]),
  'Ab7': FrettedShape([1, 3, 2, 3], fingers: [1, 3, 2, 4]),
  'Abmaj7': FrettedShape([0, 3, 3, 3], fingers: [0, 1, 1, 1], barre: 3),
  'Abm7': FrettedShape([1, 3, 2, 2], fingers: [1, 4, 2, 3]),
  'Absus4': FrettedShape([1, 3, 4, 4], fingers: [1, 2, 3, 4]),
  'Ab6': FrettedShape([1, 3, 1, 3], fingers: [1, 3, 1, 4]),
  'G#m': FrettedShape([1, 3, 4, 2], fingers: [1, 3, 4, 2]),
  'G#m7': FrettedShape([1, 3, 2, 2], fingers: [1, 4, 2, 3]),

  'A': FrettedShape([2, 1, 0, 0], fingers: [2, 1, 0, 0]),
  'Am': FrettedShape([2, 0, 0, 0], fingers: [2, 0, 0, 0]),
  'A7': FrettedShape([0, 1, 0, 0], fingers: [0, 1, 0, 0]),
  'Amaj7': FrettedShape([1, 1, 0, 0], fingers: [1, 1, 0, 0]),
  'Am7': FrettedShape([0, 0, 0, 0]),
  'Asus4': FrettedShape([2, 2, 0, 0], fingers: [1, 2, 0, 0]),
  'Asus2': FrettedShape([4, 4, 0, 0], fingers: [2, 3, 0, 0]),
  'Aadd9': FrettedShape([2, 1, 0, 2], fingers: [2, 1, 0, 3]),
  'A6': FrettedShape([2, 4, 0, 0], fingers: [1, 3, 0, 0]),
  'Am6': FrettedShape([2, 0, 0, 2], fingers: [1, 0, 0, 2]),
  'A9': FrettedShape([0, 1, 0, 2], fingers: [0, 1, 0, 2]),
  'Am9': FrettedShape([0, 0, 0, 2], fingers: [0, 0, 0, 2]),
  'Adim': FrettedShape([2, 3, 2, 3], fingers: [1, 3, 2, 4]),
  'Aaug': FrettedShape([2, 1, 1, 0], fingers: [3, 1, 2, 0]),
  'A7sus4': FrettedShape([0, 2, 0, 0], fingers: [0, 2, 0, 0]),

  'Bb': FrettedShape([3, 2, 1, 1], fingers: [3, 2, 1, 1]),
  'Bbm': FrettedShape([3, 1, 1, 1], fingers: [3, 1, 1, 1]),
  'Bb7': FrettedShape([1, 2, 1, 1], fingers: [1, 2, 1, 1]),
  'Bbmaj7': FrettedShape([3, 2, 1, 0], fingers: [3, 2, 1, 0]),
  'Bbm7': FrettedShape([1, 1, 1, 1], fingers: [1, 1, 1, 1], barre: 1),
  'Bbsus4': FrettedShape([3, 3, 1, 1], fingers: [3, 4, 1, 1], barre: 1),
  'Bbsus2': FrettedShape([3, 0, 1, 1], fingers: [3, 0, 1, 1]),
  'Bb6': FrettedShape([0, 2, 1, 1], fingers: [0, 3, 1, 2]),
  'Bb9': FrettedShape([3, 2, 1, 3], fingers: [3, 2, 1, 4]),
  'Bbdim': FrettedShape([3, 1, 0, 1], fingers: [3, 1, 0, 2]),

  'B': FrettedShape([4, 3, 2, 2], fingers: [4, 3, 2, 2]),
  'Bm': FrettedShape([4, 2, 2, 2], fingers: [4, 1, 1, 1], barre: 2),
  'B7': FrettedShape([2, 3, 2, 2], fingers: [1, 3, 2, 2]),
  'Bmaj7': FrettedShape([4, 3, 2, 1], fingers: [4, 3, 2, 1]),
  'Bm7': FrettedShape([2, 2, 2, 2], fingers: [1, 1, 1, 1], barre: 2),
  'Bsus4': FrettedShape([4, 4, 2, 2], fingers: [3, 4, 1, 1], barre: 2),
  'Bsus2': FrettedShape([4, 1, 2, 2], fingers: [4, 1, 2, 3]),
  'B6': FrettedShape([1, 3, 2, 2], fingers: [1, 4, 2, 3]),
  'Bm6': FrettedShape([1, 2, 2, 2], fingers: [1, 2, 2, 2]),
  'B9': FrettedShape([4, 3, 2, 4], fingers: [3, 2, 1, 4]),
  'Bdim': FrettedShape([4, 2, 1, 2], fingers: [4, 2, 1, 3]),
  'Baug': FrettedShape([0, 3, 2, 2], fingers: [0, 3, 1, 2]),
  'B7sus4': FrettedShape([2, 4, 2, 2], fingers: [1, 3, 1, 1], barre: 2),
};

const Map<String, FrettedShape> _slashShapes = {
  'C/E': FrettedShape([4, 0, 0, 3], fingers: [2, 0, 0, 1]),
  'C/G': FrettedShape([0, 0, 0, 3], fingers: [0, 0, 0, 3]),
  'C/Bb': FrettedShape([0, 0, 0, 1], fingers: [0, 0, 0, 1]),
  'D/F#': FrettedShape([2, 2, 2, 0], fingers: [1, 2, 3, 0]),
  'D/A': FrettedShape([2, 2, 2, 0], fingers: [1, 2, 3, 0]),
  'E/G#': FrettedShape([1, 4, 0, 2], fingers: [1, 4, 0, 2]),
  'E/B': FrettedShape([4, 4, 4, 2], fingers: [3, 3, 3, 1], barre: 4),
  'F/A': FrettedShape([2, 0, 1, 0], fingers: [2, 0, 1, 0]),
  'F/C': FrettedShape([0, 0, 1, 0], fingers: [0, 0, 1, 0]),
  'G/B': FrettedShape([0, 2, 3, 2], fingers: [0, 1, 3, 2]),
  'G/D': FrettedShape([2, 2, 3, 2], fingers: [1, 1, 3, 2]),
  'G/F': FrettedShape([0, 2, 1, 2], fingers: [0, 3, 1, 2]),
  'A/C#': FrettedShape([2, 1, 0, 0], fingers: [2, 1, 0, 0]),
  'A/E': FrettedShape([2, 1, 0, 0], fingers: [2, 1, 0, 0]),
  'A/G': FrettedShape([0, 1, 0, 0], fingers: [0, 1, 0, 0]),
  'Am/G': FrettedShape([0, 0, 0, 0]),
  'Am/E': FrettedShape([2, 0, 0, 0], fingers: [2, 0, 0, 0]),
  'Am/F': FrettedShape([2, 0, 1, 0], fingers: [2, 0, 1, 0]),
  'Bm/A': FrettedShape([2, 2, 2, 2], fingers: [1, 1, 1, 1], barre: 2),
  'Dm/A': FrettedShape([2, 2, 1, 0], fingers: [2, 3, 1, 0]),
  'Dm/F': FrettedShape([2, 2, 1, 0], fingers: [2, 3, 1, 0]),
  'Em/B': FrettedShape([0, 4, 3, 2], fingers: [0, 3, 2, 1]),
  'Em/D': FrettedShape([0, 2, 0, 2], fingers: [0, 2, 0, 3]),
  'Em/G': FrettedShape([0, 4, 3, 2], fingers: [0, 3, 2, 1]),
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
  'six': [
    MovableShape(rootSemitone: 0, frets: [0, 0, 0, 0], fingers: [0, 0, 0, 0]),
    MovableShape(rootSemitone: 7, frets: [0, 2, 0, 2], fingers: [0, 1, 0, 2]),
    MovableShape(rootSemitone: 9, frets: [2, 4, 0, 0], fingers: [1, 3, 0, 0]),
  ],
  'dim': [
    MovableShape(rootSemitone: 0, frets: [5, 3, 2, 3], fingers: [4, 2, 1, 3]),
    MovableShape(rootSemitone: 4, frets: [0, 4, 3, 1], fingers: [0, 3, 2, 1]),
    MovableShape(rootSemitone: 2, frets: [1, 2, 1, 2], fingers: [1, 3, 2, 4]),
  ],
  'aug': [
    MovableShape(rootSemitone: 0, frets: [1, 0, 0, 3], fingers: [1, 0, 0, 3]),
    MovableShape(rootSemitone: 9, frets: [2, 1, 1, 0], fingers: [3, 1, 2, 0]),
  ],
  'add9': [
    MovableShape(rootSemitone: 0, frets: [0, 2, 0, 3], fingers: [0, 2, 0, 3]),
    MovableShape(rootSemitone: 5, frets: [0, 0, 1, 0], fingers: [0, 0, 1, 0]),
  ],
};
