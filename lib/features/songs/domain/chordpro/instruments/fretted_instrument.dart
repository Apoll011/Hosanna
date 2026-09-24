import '../chord_theory.dart';
import 'instrument.dart';

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
/// Subclasses only supply data — tuning plus curated/movable shapes — and
/// inherit the whole resolution pipeline, which makes adding an instrument
/// (ukulele, bass, cavaquinho, …) a matter of describing its shapes.
abstract class FrettedInstrument extends Instrument {
  const FrettedInstrument();

  @override
  bool get supportsCapo => true;

  /// Open-string pitches in semitones (0 = C), leftmost diagram string first.
  List<int> get tuning;

  /// Curated shapes matched against the chord symbol (e.g. `C`, `Am7`).
  Map<String, FrettedShape> get openShapes;

  /// Slash-chord shapes matched exactly (e.g. `C/E`).
  Map<String, FrettedShape> get slashShapes;

  /// Movable shapes per chord-quality id; several forms may be supplied and
  /// the most comfortable one (lowest max fret) is chosen.
  Map<String, List<MovableShape>> get movableShapes;

  /// Power-chord (`C5`) shape builder. Return null to opt out.
  FrettedShape? powerChordShape(int rootSemitone) => null;

  @override
  InstrumentFingering? fingering(ParsedChord chord) {
    final resolved = _resolve(chord);
    if (resolved == null) return null;
    return FrettedFingering(
      notes: _notesOf(resolved.shape.frets),
      frets: resolved.shape.frets,
      fingers: resolved.shape.fingers,
      barre: resolved.shape.barre,
      approximate: resolved.approximate,
    );
  }

  /// Resolution order: exact slash shape → exact open shape → canonical open
  /// shape → power chord → movable form → simplified movable form.
  ({FrettedShape shape, bool approximate})? _resolve(ParsedChord chord) {
    final raw = chord.raw;
    final slash = slashShapes[raw];
    if (slash != null) return (shape: slash, approximate: false);
    final open = openShapes[raw];
    if (open != null) return (shape: open, approximate: false);

    final suffix = chordQualityCanonicalSuffix[chord.quality.id];
    if (suffix != null) {
      final canonicalOpen = openShapes[chord.rootDisplay + suffix];
      if (canonicalOpen != null) {
        return (shape: canonicalOpen, approximate: false);
      }
    }

    if (chord.quality.id == 'five') {
      final power = powerChordShape(chord.rootSemitone);
      if (power != null) return (shape: power, approximate: false);
    }

    final direct = _movableFingering(chord.quality.id, chord.rootSemitone);
    if (direct != null) return (shape: direct, approximate: false);

    var fallbackId = chordQualitySimplification[chord.quality.id];
    var hops = 0;
    while (fallbackId != null && hops < 4) {
      final shape = _movableFingering(fallbackId, chord.rootSemitone);
      if (shape != null) return (shape: shape, approximate: true);

      final fallbackSuffix = chordQualityCanonicalSuffix[fallbackId];
      if (fallbackSuffix != null) {
        final canonicalOpen = openShapes[chord.rootDisplay + fallbackSuffix];
        if (canonicalOpen != null) {
          return (shape: canonicalOpen, approximate: true);
        }
      }
      fallbackId = chordQualitySimplification[fallbackId];
      hops += 1;
    }

    return null;
  }

  FrettedShape? _movableFingering(String qualityId, int targetSemitone) {
    final forms = movableShapes[qualityId];
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

  /// Distinct note names sounded by [frets], in string order.
  List<String> _notesOf(List<int> frets) {
    final notes = <String>[];
    for (var i = 0; i < frets.length && i < tuning.length; i++) {
      final fret = frets[i];
      if (fret < 0) continue;
      final name = pitchClassName(tuning[i] + fret);
      if (!notes.contains(name)) notes.add(name);
    }
    return notes;
  }
}
