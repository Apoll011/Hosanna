import '../chord_theory.dart';

/// A chord voicing produced for one instrument.
///
/// New instrument families extend this hierarchy with a new subtype and a
/// matching diagram widget — see
/// `presentation/chordpro/diagrams/instrument_diagram.dart`.
sealed class InstrumentFingering {
  const InstrumentFingering({required this.notes});

  /// Distinct, ordered note names sounding in the voicing (root first when
  /// known). Shared by every instrument so UIs can display them generically.
  final List<String> notes;

  /// Whether this is an approximation (a simpler chord was substituted).
  bool get approximate => false;
}

/// A voicing on any fretted instrument (guitar, ukulele, bass, …).
class FrettedFingering extends InstrumentFingering {
  const FrettedFingering({
    required super.notes,
    required this.frets,
    this.fingers,
    this.barre,
    this.approximate = false,
  });

  /// Per-string frets in diagram order (leftmost string first).
  /// `-1` = muted, `0` = open.
  final List<int> frets;

  /// Per-string finger numbers (1..4); `0` (or absent) = unfingered.
  final List<int>? fingers;

  /// Fret number of the barre, when the shape uses one.
  final int? barre;

  @override
  final bool approximate;

  int get stringCount => frets.length;
}

/// A voicing on a keyboard (piano): the highlighted keys of a 2-octave span.
class KeyboardFingering extends InstrumentFingering {
  const KeyboardFingering({required super.notes, required this.highlightKeys});

  /// Semitone offsets from the leftmost drawn key (0 = C of the first octave).
  /// Keys outside the drawn range are simply ignored by the diagram.
  final List<int> highlightKeys;
}

/// Contract for an instrument that can suggest a fingering for a chord.
///
/// Implementations are stateless and cheap, so they are held in a `const`
/// registry and looked up by [id].
abstract class Instrument {
  const Instrument();

  /// Stable identifier persisted in preferences (e.g. `guitar`).
  String get id;

  /// Non-localized display name; localized labels live in the presentation
  /// layer (see `presentation/chordpro/instrument_selector.dart`).
  String get label;

  /// Whether a capo lowers the sounding pitch, so the reader should render
  /// chord shapes at `transpose - capo`.
  bool get supportsCapo;

  /// Suggests a voicing for [chord], or null when this instrument has none.
  InstrumentFingering? fingering(ParsedChord chord);
}

/// Ordered collection of available instruments, with id lookup.
class InstrumentRegistry {
  const InstrumentRegistry(this.instruments);

  final List<Instrument> instruments;

  /// The id used when nothing else is specified.
  String get defaultId => instruments.first.id;

  Instrument? byId(String id) {
    for (final instrument in instruments) {
      if (instrument.id == id) return instrument;
    }
    return null;
  }

  /// Returns the instrument for [id], falling back to the default when the id
  /// is unknown (e.g. a stale persisted value).
  Instrument resolve(String id) => byId(id) ?? instruments.first;
}
