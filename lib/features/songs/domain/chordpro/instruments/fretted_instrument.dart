import '../chord_theory.dart';
import 'fretted_tuning.dart';
import 'instrument.dart';

export 'fretted_tuning.dart';

/// A fixed shape played at a known position (open chords, slash chords).
class FrettedShape {
  const FrettedShape(this.frets, {this.fingers, this.barre});

  /// Per-string frets, leftmost string first. `-1` muted, `0` open.
  final List<int> frets;
  final List<int>? fingers;

  /// Fret number of the barre, when any.
  final int? barre;
}

/// A movable (barre) shape anchored at [rootSemitone].
///
/// Realizing it for a target root shifts every fret by the interval and moves
/// the barre with it, so a handful of forms cover every key.
class MovableShape {
  const MovableShape({
    required this.rootSemitone,
    required this.frets,
    required this.fingers,
    this.barreFret,
    this.openFingers,
  });

  /// Semitone of the chord root produced by the shape at its base position.
  final int rootSemitone;

  /// Base-position frets (leftmost string first).
  final List<int> frets;

  /// Fingering numbers for the shifted (barred) realization.
  final List<int> fingers;

  /// Fret of the barre in the base shape; null when the shape has none.
  final int? barreFret;

  /// Fingering numbers used when the shape is played at its base position.
  /// When null, the barred fingering is used even at the base position.
  final List<int>? openFingers;
}

/// Result of looking up a shape in an instrument's library.
typedef FrettedShapeHit = ({
  FrettedShape shape,
  bool approximate,
  FrettedTuning reference,
});

/// Base class for instruments whose strings are stopped against a fretboard.
///
/// Subclasses supply tuning variants plus curated/movable shapes authored for
/// [defaultTuning]. [fingering] retargets those shapes to the active tuning by
/// preserving each string's sounding pitch class (Drop D Em → `[2,2,2,0,0,0]`).
abstract class FrettedInstrument extends Instrument {
  const FrettedInstrument();

  @override
  InstrumentFamily get family => InstrumentFamily.fretted;

  @override
  bool get supportsCapo => true;

  /// Available open-string configurations, display order.
  List<FrettedTuning> get tunings;

  /// Default tuning when the user has not picked one — also the pitch space
  /// curated [openShapes] / [movableShapes] are authored against.
  FrettedTuning get defaultTuning => tunings.first;

  /// Resolves [tuningId] against [tunings], falling back to [defaultTuning].
  FrettedTuning tuningFor(String? tuningId) {
    if (tuningId == null || tuningId.isEmpty) return defaultTuning;
    for (final tuning in tunings) {
      if (tuning.id == tuningId) return tuning;
    }
    return defaultTuning;
  }

  /// Open-string pitches for the default tuning (leftmost diagram string first).
  ///
  /// Prefer [tuningFor] when a preference id is available.
  List<int> get tuning => defaultTuning.openPitches;

  /// Number of strings the curated shapes were authored for.
  int get shapeStringCount => defaultTuning.stringCount;

  /// Curated shapes matched against the chord symbol (e.g. `C`, `Am7`).
  Map<String, FrettedShape> get openShapes;

  /// Slash-chord shapes matched exactly (e.g. `C/E`).
  Map<String, FrettedShape> get slashShapes;

  /// Movable shapes per chord-quality id; several forms may be supplied and
  /// the most comfortable one (lowest max fret) is chosen.
  Map<String, List<MovableShape>> get movableShapes;

  /// Power-chord (`C5`) shape builder for the default string count.
  FrettedShape? powerChordShape(int rootSemitone) => null;

  @override
  InstrumentFingering? fingering(
    ParsedChord chord, {
    InstrumentFingeringOptions options = InstrumentFingeringOptions.defaults,
  }) {
    final activeTuning = tuningFor(options.tuningId);
    final resolved = resolveShape(chord, tuning: activeTuning);
    if (resolved == null) return null;

    final adapted = retargetShape(
      resolved.shape,
      from: resolved.reference,
      to: activeTuning,
      promoteTones: _openPromotionPitchClasses(chord),
    );
    final frets = List<int>.from(adapted.frets);
    final beforeRoot = List<int>.from(frets);
    ensureChordRoot(
      frets,
      activeTuning.openPitches,
      pitchClass(chord.rootSemitone),
    );
    final fingers = adjustFingers(adapted.fingers, beforeRoot, frets);
    final barre = adjustBarre(adapted.barre, beforeRoot, frets);

    return FrettedFingering(
      notes: notesOf(frets, activeTuning.openPitches),
      frets: frets,
      fingers: fingers,
      barre: barre,
      approximate: resolved.approximate,
      stringNames: activeTuning.stringNames,
      tuningId: activeTuning.id,
    );
  }

  /// Resolution order: exact slash shape → exact open shape → canonical open
  /// shape → power chord → movable form → simplified movable form.
  ///
  /// Returned [FrettedShapeHit.reference] is the open-string pitch space the
  /// frets were authored for (usually [defaultTuning]).
  FrettedShapeHit? resolveShape(
    ParsedChord chord, {
    FrettedTuning? tuning,
  }) {
    final open = openShapesFor(tuning ?? defaultTuning);
    final slash = slashShapesFor(tuning ?? defaultTuning);

    final raw = chord.raw;
    final slashHit = slash[raw];
    if (slashHit != null) {
      return (
        shape: slashHit,
        approximate: false,
        reference: defaultTuning,
      );
    }
    final openHit = open[raw];
    if (openHit != null) {
      return (shape: openHit, approximate: false, reference: defaultTuning);
    }

    final suffix = chordQualityCanonicalSuffix[chord.quality.id];
    if (suffix != null) {
      final canonicalOpen = open[chord.rootDisplay + suffix];
      if (canonicalOpen != null) {
        return (
          shape: canonicalOpen,
          approximate: false,
          reference: defaultTuning,
        );
      }
    }

    if (chord.quality.id == 'five') {
      final power = powerChordShape(chord.rootSemitone);
      if (power != null) {
        return (shape: power, approximate: false, reference: defaultTuning);
      }
    }

    final movable = movableShapesFor(tuning ?? defaultTuning);
    final direct =
        _movableFingering(chord.quality.id, chord.rootSemitone, movable);
    if (direct != null) {
      return (shape: direct, approximate: false, reference: defaultTuning);
    }

    var fallbackId = chordQualitySimplification[chord.quality.id];
    var hops = 0;
    while (fallbackId != null && hops < 4) {
      final shape =
          _movableFingering(fallbackId, chord.rootSemitone, movable);
      if (shape != null) {
        return (shape: shape, approximate: true, reference: defaultTuning);
      }

      final fallbackSuffix = chordQualityCanonicalSuffix[fallbackId];
      if (fallbackSuffix != null) {
        final canonicalOpen = open[chord.rootDisplay + fallbackSuffix];
        if (canonicalOpen != null) {
          return (
            shape: canonicalOpen,
            approximate: true,
            reference: defaultTuning,
          );
        }
      }
      fallbackId = chordQualitySimplification[fallbackId];
      hops += 1;
    }

    return null;
  }

  /// Shape table for [tuning]; override when a variant needs its own library.
  Map<String, FrettedShape> openShapesFor(FrettedTuning tuning) => openShapes;

  Map<String, FrettedShape> slashShapesFor(FrettedTuning tuning) => slashShapes;

  Map<String, List<MovableShape>> movableShapesFor(FrettedTuning tuning) =>
      movableShapes;

  /// Fits an authored fret row to [targetCount] strings.
  ///
  /// Extra bass strings are muted; surplus bass strings are dropped so the
  /// treble side of a 6-string shape can feed a 4-string baritone.
  static List<int> adaptFrets(List<int> frets, int targetCount) {
    if (frets.length == targetCount) return frets;
    if (frets.length < targetCount) {
      return [
        ...List<int>.filled(targetCount - frets.length, -1),
        ...frets,
      ];
    }
    return frets.sublist(frets.length - targetCount);
  }

  /// Same bass-pad / treble-trim policy as [adaptFrets] for finger numbers.
  static List<int>? adaptOptionalInts(List<int>? values, int targetCount) {
    if (values == null) return null;
    if (values.length == targetCount) return values;
    if (values.length < targetCount) {
      return [
        ...List<int>.filled(targetCount - values.length, 0),
        ...values,
      ];
    }
    return values.sublist(values.length - targetCount);
  }

  /// Aligns [pitches] to [targetCount] the same way as [adaptFrets].
  ///
  /// Padded bass slots copy from [padPitches] (usually the target tuning) so
  /// muted extras stay mute under retune.
  static List<int> adaptPitches(
    List<int> pitches,
    int targetCount, {
    List<int>? padPitches,
  }) {
    if (pitches.length == targetCount) return pitches;
    if (pitches.length < targetCount) {
      final pad = targetCount - pitches.length;
      final filler = padPitches != null && padPitches.length >= pad
          ? padPitches.sublist(0, pad)
          : List<int>.filled(pad, 0);
      return [...filler, ...pitches];
    }
    return pitches.sublist(pitches.length - targetCount);
  }

  /// Retargets a shape from [from] open pitches to [to], preserving pitch class
  /// per string, then optionally rings muted open strings that match
  /// [promoteTones] (root / fifth / slash bass). Extra bass strings added by
  /// [adaptFrets] stay muted.
  static FrettedShape retargetShape(
    FrettedShape shape, {
    required FrettedTuning from,
    required FrettedTuning to,
    Set<int> promoteTones = const {},
  }) {
    final count = to.stringCount;
    final padCount =
        count > shape.frets.length ? count - shape.frets.length : 0;
    final oldFrets = adaptFrets(shape.frets, count);
    final oldFingers = adaptOptionalInts(shape.fingers, count);
    final fromOpens = adaptPitches(
      from.openPitches,
      count,
      padPitches: to.openPitches,
    );

    final newFrets = retuneFrets(oldFrets, fromOpens, to.openPitches);
    if (promoteTones.isNotEmpty) {
      promoteOpenChordTones(
        newFrets,
        to.openPitches,
        promoteTones,
        skipLeading: padCount,
      );
    }

    final newFingers = adjustFingers(oldFingers, oldFrets, newFrets);
    final newBarre = adjustBarre(shape.barre, oldFrets, newFrets);

    return FrettedShape(newFrets, fingers: newFingers, barre: newBarre);
  }

  /// For each sounding string, pick the fret on [toOpens] that matches the
  /// pitch class produced by [frets] against [fromOpens].
  static List<int> retuneFrets(
    List<int> frets,
    List<int> fromOpens,
    List<int> toOpens,
  ) {
    assert(frets.length == toOpens.length);
    assert(fromOpens.length == toOpens.length);
    return [
      for (var i = 0; i < frets.length; i++)
        frets[i] < 0
            ? -1
            : fretForPitchClass(
                pitchClass(fromOpens[i] + frets[i]),
                toOpens[i],
              ),
    ];
  }

  /// Lowest fret (0–11) on an open string of [openPitch] that sounds [pc].
  static int fretForPitchClass(int pc, int openPitch) {
    return pitchClass(pc - openPitch);
  }

  /// Unmute strings whose open pitch is in [tones] (e.g. Drop D → open D on a
  /// D chord). [skipLeading] keeps padded bass strings (7-string / 5-string)
  /// muted.
  static void promoteOpenChordTones(
    List<int> frets,
    List<int> openPitches,
    Set<int> tones, {
    int skipLeading = 0,
  }) {
    for (var i = skipLeading; i < frets.length && i < openPitches.length; i++) {
      if (frets[i] >= 0) continue;
      if (tones.contains(pitchClass(openPitches[i]))) {
        frets[i] = 0;
      }
    }
  }

  /// If the voicing somehow lost its root (common after treble-trim), fret it
  /// on the string that needs the lowest fret for that pitch class.
  static void ensureChordRoot(
    List<int> frets,
    List<int> openPitches,
    int rootPc,
  ) {
    for (var i = 0; i < frets.length && i < openPitches.length; i++) {
      final fret = frets[i];
      if (fret >= 0 && pitchClass(openPitches[i] + fret) == rootPc) {
        return;
      }
    }

    var bestString = -1;
    var bestFret = 99;
    for (var s = 0; s < frets.length && s < openPitches.length; s++) {
      final fret = fretForPitchClass(rootPc, openPitches[s]);
      if (fret < bestFret) {
        bestFret = fret;
        bestString = s;
      }
    }
    if (bestString >= 0) {
      frets[bestString] = bestFret;
    }
  }

  /// Keeps finger labels when frets stay fretted; open↔fretted transitions
  /// clear or assign finger 1.
  static List<int>? adjustFingers(
    List<int>? oldFingers,
    List<int> oldFrets,
    List<int> newFrets,
  ) {
    if (oldFingers == null) {
      return [
        for (final fret in newFrets) fret > 0 ? 1 : 0,
      ];
    }
    return [
      for (var i = 0; i < newFrets.length; i++)
        if (newFrets[i] <= 0)
          0
        else if (oldFrets[i] <= 0)
          1
        else
          (i < oldFingers.length && oldFingers[i] > 0 ? oldFingers[i] : 1),
    ];
  }

  /// Shifts a barre with the string that carried it, or infers one when several
  /// strings share the same fretted fret.
  static int? adjustBarre(
    int? oldBarre,
    List<int> oldFrets,
    List<int> newFrets,
  ) {
    if (oldBarre != null) {
      for (var i = 0; i < oldFrets.length && i < newFrets.length; i++) {
        if (oldFrets[i] == oldBarre && newFrets[i] > 0) {
          return newFrets[i];
        }
      }
    }

    final fretted = <int>[
      for (final fret in newFrets)
        if (fret > 0) fret,
    ];
    if (fretted.length < 2) return null;
    fretted.sort();
    final candidate = fretted.first;
    final share = fretted.where((f) => f == candidate).length;
    return share >= 2 ? candidate : null;
  }

  /// Open pitches worth unmuting after a retune: root, fifth, slash bass.
  static Set<int> _openPromotionPitchClasses(ParsedChord chord) {
    final root = pitchClass(chord.rootSemitone);
    final tones = <int>{root, pitchClass(root + 7)};
    final bass = chord.bassSemitone;
    if (bass != null) tones.add(pitchClass(bass));
    return tones;
  }

  FrettedShape? _movableFingering(
    String qualityId,
    int targetSemitone,
    Map<String, List<MovableShape>> formsByQuality,
  ) {
    final forms = formsByQuality[qualityId];
    if (forms == null || forms.isEmpty) return null;

    FrettedShape? best;
    for (final form in forms) {
      final shape = _realize(form, targetSemitone);
      if (best == null || _maxFret(shape) < _maxFret(best)) best = shape;
    }
    return best;
  }

  FrettedShape _realize(MovableShape form, int targetSemitone) {
    final shift = ((targetSemitone - form.rootSemitone) % 12 + 12) % 12;
    final frets = [
      for (final fret in form.frets) fret < 0 ? fret : fret + shift,
    ];

    final openFingers = form.openFingers;
    if (shift == 0 && openFingers != null) {
      return FrettedShape(frets, fingers: openFingers);
    }

    final barreFret = form.barreFret;
    return FrettedShape(
      frets,
      fingers: form.fingers,
      barre: barreFret == null ? null : barreFret + shift,
    );
  }

  int _maxFret(FrettedShape shape) {
    var max = 0;
    for (final fret in shape.frets) {
      if (fret > max) max = fret;
    }
    return max;
  }

  /// Distinct note names sounded by [frets] against [openPitches].
  static List<String> notesOf(List<int> frets, List<int> openPitches) {
    final notes = <String>[];
    for (var i = 0; i < frets.length && i < openPitches.length; i++) {
      final fret = frets[i];
      if (fret < 0) continue;
      final name = pitchClassName(openPitches[i] + fret);
      if (!notes.contains(name)) notes.add(name);
    }
    return notes;
  }
}
