/// Chord dictionary, ported from
/// `@hosanna/shared/src/chordpro/chordDictionary.ts`.
///
/// The dictionary parses a chord symbol (see [parseChordSymbol]) and asks each
/// registered [Instrument] for a voicing, returning a [ChordFingering] keyed by
/// instrument id. Adding an instrument never requires changing this file — see
/// `instruments/instruments.dart`.
library;

import 'chord_theory.dart';
import 'instruments/instruments.dart';

/// All fingerings available for one chord symbol, keyed by instrument id.
class ChordFingering {
  const ChordFingering({
    required this.chord,
    required this.qualityId,
    required this.qualityLabel,
    required this.fingerings,
    this.alternatives = const {},
  });

  /// The cleaned chord symbol (e.g. `Am7`).
  final String chord;

  /// Resolved chord-quality id (e.g. `m7`).
  final String qualityId;

  /// Human-readable quality label (e.g. `Minor 7th`).
  final String qualityLabel;

  /// Voicings by instrument id; instruments without a voicing are absent.
  final Map<String, InstrumentFingering> fingerings;

  /// Ordered alternative diagrams keyed by instrument id.
  final Map<String, List<InstrumentFingering>> alternatives;

  /// The voicing for [id], or null when the instrument has none for this chord.
  InstrumentFingering? forInstrument(String id) => fingerings[id];

  List<InstrumentFingering> alternativesFor(String id) {
    final choices = alternatives[id];
    if (choices != null) return choices;
    final value = fingerings[id];
    return value == null ? const [] : [value];
  }
}

/// Parses chord symbols and resolves instrument voicings for them.
class ChordDictionary {
  const ChordDictionary({this.instruments = defaultInstruments});

  final List<Instrument> instruments;

  ChordFingering? getFingering(
    String chord, {
    InstrumentPreferences preferences = const InstrumentPreferences(),
  }) {
    final parsed = parseChordSymbol(chord);
    if (parsed == null) return null;

    final fingerings = <String, InstrumentFingering>{};
    final alternatives = <String, List<InstrumentFingering>>{};
    for (final instrument in instruments) {
      final pref = preferences.forId(instrument.id);
      final choices = instrument.fingerings(
        parsed,
        options: InstrumentFingeringOptions.fromPreference(pref),
      );
      if (choices.isNotEmpty) {
        fingerings[instrument.id] = choices.first;
        alternatives[instrument.id] = choices;
      }
    }

    return ChordFingering(
      chord: parsed.raw,
      qualityId: parsed.quality.id,
      qualityLabel: parsed.quality.label,
      fingerings: fingerings,
      alternatives: alternatives,
    );
  }
}

const ChordDictionary chordDictionary = ChordDictionary();
