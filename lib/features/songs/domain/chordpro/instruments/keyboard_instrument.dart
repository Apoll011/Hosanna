import '../chord_theory.dart';
import 'instrument.dart';

/// Keyboard (piano) voicing: chord tones are spelled directly from the
/// quality intervals rather than looked up in a shape table.
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
  InstrumentFingering? fingering(ParsedChord chord) {
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
    final base = bass == null ? 0 : keyRange ~/ 2;

    // Bass note first, in the lower octave, so inversions are distinguishable.
    if (bass != null) add(base + pitchClass(bass));
    for (final interval in chord.quality.intervals) {
      add(base + rootPc + interval);
    }

    return KeyboardFingering(notes: notes, highlightKeys: keys);
  }
}
