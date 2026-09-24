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
  });

  /// The cleaned chord symbol (e.g. `Am7`).
  final String chord;

  /// Resolved chord-quality id (e.g. `m7`).
  final String qualityId;

  /// Human-readable quality label (e.g. `Minor 7th`).
  final String qualityLabel;

  /// Voicings by instrument id; instruments without a voicing are absent.
  final Map<String, InstrumentFingering> fingerings;

  /// The voicing for [id], or null when the instrument has none for this chord.
  InstrumentFingering? forInstrument(String id) => fingerings[id];
}

/// Parses chord symbols and resolves instrument voicings for them.
class ChordDictionary {
  const ChordDictionary({this.instruments = defaultInstruments});

  final List<Instrument> instruments;

  ChordFingering? getFingering(String chord) {
    final parsed = parseChordSymbol(chord);
    if (parsed == null) return null;

    final fingerings = <String, InstrumentFingering>{};
    for (final instrument in instruments) {
      final fingering = instrument.fingering(parsed);
      if (fingering != null) fingerings[instrument.id] = fingering;
    }

    return ChordFingering(
      chord: parsed.raw,
      qualityId: parsed.quality.id,
      qualityLabel: parsed.quality.label,
      fingerings: fingerings,
    );
  }
}

const ChordDictionary chordDictionary = ChordDictionary();
