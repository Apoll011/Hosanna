import '../chord_theory.dart';
import 'instrument.dart';

/// Keyboard (piano) voicing: chord tones are spelled from the quality
/// intervals, optionally compacted / split across hands per user preference.
class KeyboardInstrument extends Instrument {
  const KeyboardInstrument();

  /// Semitone span of the keyboard drawn by the diagram (two octaves). Keys
  /// outside this range are folded back into it so every voicing renders.
  static const int keyRange = 24;

  @override
  String get id => 'piano';

  @override
  String get label => 'Piano';

  @override
  bool get supportsCapo => false;

  @override
  InstrumentFingering? fingering(
    ParsedChord chord, {
    InstrumentFingeringOptions options = InstrumentFingeringOptions.defaults,
  }) {
    final notes = <String>[];
    final keys = <int>[];

    void add(int semitone) {
      final name = pitchClassName(semitone);
      if (!notes.contains(name)) notes.add(name);
      final key = ((semitone % keyRange) + keyRange) % keyRange;
      if (!keys.contains(key)) keys.add(key);
    }

    final rootPc = pitchClass(chord.rootSemitone);
    final bass = chord.bassSemitone;
    final intervals = _voicingIntervals(chord, options);

    if (bass != null && options.pianoSlashSplitHands) {
      // Left hand: bass alone in the lower octave.
      // Right hand: chord tones in the upper octave (skipping the bass pitch
      // class so it isn't doubled awkwardly on top of itself).
      add(pitchClass(bass));
      for (final interval in intervals) {
        final pc = pitchClass(rootPc + interval);
        if (pc == pitchClass(bass)) continue;
        add(keyRange ~/ 2 + pc);
      }
      // Ensure the RH still has something when every tone matched the bass.
      if (keys.length <= 1) {
        for (final interval in intervals) {
          add(keyRange ~/ 2 + rootPc + interval);
        }
      }
    } else if (bass != null) {
      // Legacy inline layout, but keep bass below the chord cluster.
      add(pitchClass(bass));
      for (final interval in intervals) {
        add(keyRange ~/ 2 + rootPc + interval);
      }
    } else {
      for (final interval in intervals) {
        add(rootPc + interval);
      }
    }

    keys.sort();
    return KeyboardFingering(notes: notes, highlightKeys: keys);
  }

  /// Intervals for the right-hand (or single-hand) cluster.
  List<int> _voicingIntervals(
    ParsedChord chord,
    InstrumentFingeringOptions options,
  ) {
    final intervals = List<int>.from(chord.quality.intervals);
    if (options.pianoVoicingStyle != PianoVoicingStyle.compact) {
      return intervals;
    }

    // Compact: drop the root for 7th+ chords (C7 → Bb-E-G), and for tall
    // extensions also drop the 5th so the hand stays comfortable.
    if (isRootlessFriendlyQuality(chord.quality)) {
      intervals.removeWhere((i) => i % 12 == 0);
      if (intervals.length >= 4) {
        intervals.removeWhere((i) => i % 12 == 7);
      }
      // Guard: never return an empty voicing.
      if (intervals.isEmpty) {
        return List<int>.from(chord.quality.intervals);
      }
    }
    return intervals;
  }
}
