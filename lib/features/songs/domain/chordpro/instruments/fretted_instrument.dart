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

  /// Fret number the barre sits on, when any.
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

/// Base class for instruments whose strings are stopped against a fretboard.
///
/// Subclasses supply tuning variants plus curated/movable shapes. The shared
/// resolution pipeline adapts authored shapes to the active string count so
/// adding a 7-string guitar or baritone ukulele is mostly data.
abstract class FrettedInstrument extends Instrument {
  const FrettedInstrument();

  @override
  InstrumentFamily get family => InstrumentFamily.fretted;

  @override
  bool get supportsCapo => true;

  /// Available open-string configurations, display order.
  List<FrettedTuning> get tunings;

  /// Default tuning when the user has not picked one.
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

    final frets = adaptFrets(resolved.shape.frets, activeTuning.stringCount);
    final fingers = adaptOptionalInts(
      resolved.shape.fingers,
      activeTuning.stringCount,
    );

    return FrettedFingering(
      notes: notesOf(frets, activeTuning.openPitches),
      frets: frets,
      fingers: fingers,
      barre: resolved.shape.barre,
      approximate: resolved.approximate,
      stringNames: activeTuning.stringNames,
      tuningId: activeTuning.id,
    );
  }

  /// Resolution order: exact slash shape → exact open shape → canonical open
  /// shape → power chord → movable form → simplified movable form.
  ///
  /// [tuning] lets subclasses (e.g. baritone ukulele) swap shape sources.
  ({FrettedShape shape, bool approximate})? resolveShape(
    ParsedChord chord, {
    FrettedTuning? tuning,
  }) {
    final open = openShapesFor(tuning ?? defaultTuning);
    final slash = slashShapesFor(tuning ?? defaultTuning);

    final raw = chord.raw;
    final slashHit = slash[raw];
    if (slashHit != null) return (shape: slashHit, approximate: false);
    final openHit = open[raw];
    if (openHit != null) return (shape: openHit, approximate: false);

    final suffix = chordQualityCanonicalSuffix[chord.quality.id];
    if (suffix != null) {
      final canonicalOpen = open[chord.rootDisplay + suffix];
      if (canonicalOpen != null) {
        return (shape: canonicalOpen, approximate: false);
      }
    }

    if (chord.quality.id == 'five') {
      final power = powerChordShape(chord.rootSemitone);
      if (power != null) return (shape: power, approximate: false);
    }

    final movable = movableShapesFor(tuning ?? defaultTuning);
    final direct = _movableFingering(chord.quality.id, chord.rootSemitone, movable);
    if (direct != null) return (shape: direct, approximate: false);

    var fallbackId = chordQualitySimplification[chord.quality.id];
    var hops = 0;
    while (fallbackId != null && hops < 4) {
      final shape = _movableFingering(fallbackId, chord.rootSemitone, movable);
      if (shape != null) return (shape: shape, approximate: true);

      final fallbackSuffix = chordQualityCanonicalSuffix[fallbackId];
      if (fallbackSuffix != null) {
        final canonicalOpen = open[chord.rootDisplay + fallbackSuffix];
        if (canonicalOpen != null) {
          return (shape: canonicalOpen, approximate: true);
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
