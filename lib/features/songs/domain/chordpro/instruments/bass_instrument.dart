import '../chord_theory.dart';
import 'fretted_instrument.dart';
import 'guitar_instrument.dart';
import 'instrument.dart';

/// Bass guitar chord library (standard / Drop D / 5-string).
///
/// Chord shapes reuse the low four strings of the guitar library (EADG).
/// 5-string pads a muted low B. Capo is not supported.
///
/// [BassVoicingStyle.roots] draws a single fretted note (chord root, or the
/// slash bass when present) instead of a full shape.
class BassInstrument extends FrettedInstrument {
  const BassInstrument();

  static const _guitar = GuitarInstrument();

  @override
  String get id => 'bass';

  @override
  String get label => 'Bass Guitar';

  @override
  bool get supportsCapo => false;

  @override
  List<FrettedTuning> get tunings => FrettedTunings.bass;

  @override
  Map<String, FrettedShape> get openShapes => const {};

  @override
  Map<String, FrettedShape> get slashShapes => const {};

  @override
  Map<String, List<MovableShape>> get movableShapes => const {};

  @override
  FrettedShape? powerChordShape(int rootSemitone) {
    final guitar = _guitar.powerChordShape(rootSemitone);
    if (guitar == null) return null;
    return _trimToBass(guitar);
  }

  @override
  InstrumentFingering? fingering(
    ParsedChord chord, {
    InstrumentFingeringOptions options = InstrumentFingeringOptions.defaults,
  }) {
    final activeTuning = tuningFor(options.tuningId);
    if (options.bassVoicingStyle == BassVoicingStyle.roots) {
      return _rootFingering(chord, activeTuning);
    }
    return super.fingering(chord, options: options);
  }

  @override
  ({FrettedShape shape, bool approximate})? resolveShape(
    ParsedChord chord, {
    FrettedTuning? tuning,
  }) {
    final guitar = _guitar.resolveShape(chord);
    if (guitar == null) return null;
    return (
      shape: _trimToBass(guitar.shape),
      approximate: guitar.approximate,
    );
  }

  /// Keep guitar's low four strings (E A D G); drop the treble B/e.
  static FrettedShape _trimToBass(FrettedShape shape) {
    final frets = shape.frets.length >= 4
        ? shape.frets.sublist(0, 4)
        : [
            ...shape.frets,
            ...List<int>.filled(4 - shape.frets.length, -1),
          ];
    final fingers = shape.fingers == null
        ? null
        : (shape.fingers!.length >= 4
            ? shape.fingers!.sublist(0, 4)
            : [
                ...shape.fingers!,
                ...List<int>.filled(4 - shape.fingers!.length, 0),
              ]);
    return FrettedShape(frets, fingers: fingers, barre: shape.barre);
  }

  /// Single fretted note: slash bass if present, otherwise the chord root.
  FrettedFingering? _rootFingering(ParsedChord chord, FrettedTuning tuning) {
    final target = pitchClass(chord.bassSemitone ?? chord.rootSemitone);
    final pick = _bestRootPosition(target, tuning);
    if (pick == null) return null;

    final frets = List<int>.filled(tuning.stringCount, -1);
    final fingers = List<int>.filled(tuning.stringCount, 0);
    frets[pick.string] = pick.fret;
    if (pick.fret > 0) fingers[pick.string] = 1;

    return FrettedFingering(
      notes: FrettedInstrument.notesOf(frets, tuning.openPitches),
      frets: frets,
      fingers: fingers,
      stringNames: tuning.stringNames,
      tuningId: tuning.id,
    );
  }

  /// Prefer a low string with a fretted note in the first five frets; otherwise
  /// the overall lowest fret that yields [targetPc].
  static ({int string, int fret})? _bestRootPosition(
    int targetPc,
    FrettedTuning tuning,
  ) {
    ({int string, int fret})? bestLow;
    ({int string, int fret})? bestAny;
    var bestAnyFret = 99;

    for (var s = 0; s < tuning.stringCount; s++) {
      final open = tuning.openPitches[s];
      for (var fret = 0; fret <= 12; fret++) {
        if (pitchClass(open + fret) != targetPc) continue;
        bestAny ??= (string: s, fret: fret);
        if (fret < bestAnyFret) {
          bestAnyFret = fret;
          bestAny = (string: s, fret: fret);
        }
        if (fret <= 5) {
          bestLow ??= (string: s, fret: fret);
        }
        break;
      }
    }
    return bestLow ?? bestAny;
  }
}
