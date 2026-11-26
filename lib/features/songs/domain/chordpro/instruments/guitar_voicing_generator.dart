import '../chord_theory.dart';
import 'fretted_instrument.dart';
import 'instrument.dart';

/// Generates guitar voicings directly from the selected open-string pitches.
class GuitarVoicingGenerator {
  const GuitarVoicingGenerator();

  List<FrettedFingering> generate(
    ParsedChord chord, {
    required FrettedTuning tuning,
    int limit = 8,
  }) {
    final tones = chord.quality.intervals
        .map((interval) => pitchClass(chord.rootSemitone + interval))
        .toSet();
    final required = _requiredTones(chord, tones);
    final allowedTones = {...tones};
    if (chord.bassSemitone case final bass?) {
      allowedTones.add(pitchClass(bass));
    }
    final candidates = <String, GuitarVoicingCandidate>{};
    final openMidi = tuning.openMidiPitches;

    // Searching overlapping four-fret positions bounds the search while
    // still finding open, low, and movable-neck guitar voicings.
    for (var window = 0; window <= 8; window += 2) {
      final choices = <List<int>>[];
      for (var string = 0; string < tuning.stringCount; string++) {
        final frets = <int>[-1];
        for (var fret = 0; fret <= 12; fret++) {
          if (fret != 0 && (fret < window || fret > window + 4)) continue;
          if (allowedTones.contains(
            pitchClass(tuning.openPitches[string] + fret),
          )) {
            frets.add(fret);
          }
        }
        choices.add(frets);
      }
      _enumerate(
        0,
        choices,
        List<int>.filled(tuning.stringCount, -1),
        tuning,
        openMidi,
        chord,
        allowedTones,
        required,
        candidates,
      );
    }

    final ranked = GuitarVoicingRanker().rank(candidates.values.toList());
    return [
      for (final candidate in ranked.take(limit))
        FrettedFingering(
          notes: FrettedInstrument.notesOf(candidate.frets, tuning.openPitches),
          frets: candidate.frets,
          fingers: candidate.fingers,
          barre: candidate.barre,
          stringNames: tuning.stringNames,
          tuningId: tuning.id,
        ),
    ];
  }

  void _enumerate(
    int string,
    List<List<int>> choices,
    List<int> frets,
    FrettedTuning tuning,
    List<int> openMidi,
    ParsedChord chord,
    Set<int> tones,
    Set<int> required,
    Map<String, GuitarVoicingCandidate> found,
  ) {
    if (string == choices.length) {
      final sounded = <int>[];
      final pcs = <int>{};
      for (var i = 0; i < frets.length; i++) {
        final fret = frets[i];
        if (fret < 0) continue;
        final pc = pitchClass(tuning.openPitches[i] + fret);
        sounded.add(
          (openMidi.isEmpty ? tuning.openPitches[i] : openMidi[i]) + fret,
        );
        pcs.add(pc);
      }
      if (pcs.length < required.length || !pcs.containsAll(required)) return;
      if (pcs.any(
        (pc) =>
            !tones.contains(pc) &&
            !(chord.bassSemitone != null &&
                pc == pitchClass(chord.bassSemitone!)),
      )) {
        return;
      }
      if (sounded.length < 3) return;
      sounded.sort();
      if (chord.bassSemitone != null &&
          pitchClass(sounded.first) != pitchClass(chord.bassSemitone!)) {
        return;
      }
      final key = frets.join(',');
      final candidate = GuitarVoicingCandidate.create(
        frets,
        tones: tones,
        bassPc: pitchClass(chord.rootSemitone),
        openMidi: openMidi,
        tuning: tuning,
      );
      if (candidate != null) found.putIfAbsent(key, () => candidate);
      return;
    }
    for (final fret in choices[string]) {
      frets[string] = fret;
      _enumerate(
        string + 1,
        choices,
        frets,
        tuning,
        openMidi,
        chord,
        tones,
        required,
        found,
      );
    }
  }

  Set<int> _requiredTones(ParsedChord chord, Set<int> tones) {
    final root = pitchClass(chord.rootSemitone);
    final quality = chord.quality;
    final thirdOrSuspension = quality.intervals.firstWhere(
      (interval) =>
          interval == 2 || interval == 3 || interval == 4 || interval == 5,
      orElse: () => 0,
    );
    final required = <int>{root, pitchClass(root + thirdOrSuspension)};
    if (tones.contains(pitchClass(root + 7))) {
      required.add(pitchClass(root + 7));
    }
    if (chord.bassSemitone case final bass?) required.add(pitchClass(bass));
    for (final interval in quality.intervals) {
      if ([10, 11].contains(interval)) {
        required.add(pitchClass(root + interval));
      }
    }
    return required;
  }
}

/// Ranking policy is separate from pitch and candidate generation.
class GuitarVoicingRanker {
  List<GuitarVoicingCandidate> rank(List<GuitarVoicingCandidate> candidates) {
    candidates.sort((a, b) => a.score.compareTo(b.score));
    final unique = <String>{};
    return [
      for (final candidate in candidates)
        if (unique.add(candidate.identity)) candidate,
    ];
  }
}

class GuitarVoicingCandidate {
  const GuitarVoicingCandidate(
    this.frets,
    this.fingers,
    this.barre,
    this.score,
  );

  final List<int> frets;
  final List<int> fingers;
  final int? barre;
  final int score;

  String get identity => frets.join(',');

  static GuitarVoicingCandidate? create(
    List<int> source, {
    required Set<int> tones,
    required int bassPc,
    required List<int> openMidi,
    required FrettedTuning tuning,
  }) {
    final frets = List<int>.unmodifiable(source);
    final played = [
      for (final fret in frets)
        if (fret > 0) fret,
    ];
    final minFret = played.isEmpty ? 0 : played.reduce((a, b) => a < b ? a : b);
    final maxFret = played.isEmpty ? 0 : played.reduce((a, b) => a > b ? a : b);
    final groups = <int, int>{};
    var finger = 0;
    for (var i = 0; i < frets.length; i++) {
      final fret = frets[i];
      if (fret <= 0) continue;
      if (i == 0 || frets[i - 1] != fret) finger++;
      groups[i] = finger;
    }
    if (finger > 4) return null;
    final assigned = List<int>.filled(frets.length, 0);
    for (final entry in groups.entries) {
      assigned[entry.key] = entry.value;
    }
    final repeated = <int, List<int>>{};
    for (var i = 0; i < frets.length; i++) {
      if (frets[i] > 0) repeated.putIfAbsent(frets[i], () => []).add(i);
    }
    final barreFrets = repeated.entries.where((entry) {
      final strings = entry.value;
      return strings.length > 1 &&
          strings.last - strings.first + 1 == strings.length;
    });
    final barre = barreFrets.isEmpty ? null : barreFrets.first.key;
    final muted = frets.where((fret) => fret < 0).length;
    final open = frets.where((fret) => fret == 0).length;
    final soundedPitches = [
      for (var i = 0; i < frets.length; i++)
        if (frets[i] >= 0)
          (openMidi.isEmpty ? tuning.openPitches[i] : openMidi[i]) + frets[i],
    ]..sort();
    final soundedTones = {
      for (final pitch in soundedPitches) pitchClass(pitch),
    };
    final missingTones = tones.difference(soundedTones).length;
    final bassPenalty =
        soundedPitches.isNotEmpty && pitchClass(soundedPitches.first) != bassPc
        ? 4
        : 0;
    final score =
        maxFret * 2 +
        (maxFret - minFret) * 4 +
        finger * 5 +
        (barre == null ? 0 : 3) +
        muted * 2 -
        open * 2 +
        missingTones * 10 +
        bassPenalty;
    return GuitarVoicingCandidate(
      frets,
      List.unmodifiable(assigned),
      barre,
      score,
    );
  }
}
