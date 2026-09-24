import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/chord_dictionary.dart';
import 'package:hosanna/features/songs/domain/chordpro/chord_theory.dart';
import 'package:hosanna/features/songs/domain/chordpro/instruments/instruments.dart';

/// Chords every fretted instrument must be able to voice.
const List<String> _chords = [
  'C', 'Cm', 'C7', 'Cmaj7', 'Cm7', 'C6', 'Cadd9', 'Csus2', 'Csus4', 'C5',
  'D', 'Dm', 'D7', 'Dmaj7', 'Dm7', 'Dsus2', 'Dsus4',
  'E', 'Em', 'E7', 'Emaj7', 'Em7', 'Esus4', 'E5',
  'F', 'Fm', 'F7', 'Fmaj7', 'Fm7',
  'F#', 'F#m', 'F#7', 'G', 'Gm', 'G7', 'Gmaj7', 'Gm7', 'Gsus2', 'Gsus4',
  'Ab', 'A', 'Am', 'A7', 'Amaj7', 'Am7', 'Asus2', 'Asus4', 'A5',
  'Bb', 'Bbm', 'Bb7', 'B', 'Bm', 'B7', 'Bmaj7', 'Bm7',
  'C#', 'C#m', 'C#7', 'C#maj7', 'C#m7', 'Eb', 'Ebm', 'Eb7', 'G#m',
];

/// Pitch classes actually sounded by a fretted voicing.
Set<int> _soundedPitchClasses(FrettedFingering fingering, List<int> tuning) {
  final sounded = <int>{};
  for (var i = 0; i < fingering.frets.length; i++) {
    final fret = fingering.frets[i];
    if (fret < 0) continue;
    sounded.add(pitchClass(tuning[i] + fret));
  }
  return sounded;
}

/// Pitch classes the chord symbol implies (root + quality intervals + bass).
Set<int> _expectedPitchClasses(ParsedChord chord) {
  final rootPc = pitchClass(chord.rootSemitone);
  final expected = <int>{for (final iv in chord.quality.intervals) pitchClass(rootPc + iv)};
  final bass = chord.bassSemitone;
  if (bass != null) expected.add(pitchClass(bass));
  return expected;
}

void main() {
  final frettedInstruments = instrumentRegistry.instruments
      .whereType<FrettedInstrument>()
      .toList();

  group('instrument registry', () {
    test('exposes guitar, ukulele and piano', () {
      expect(
        instrumentRegistry.instruments.map((i) => i.id),
        containsAll(<String>['guitar', 'ukulele', 'piano']),
      );
    });

    test('resolves unknown ids to the default instrument', () {
      expect(instrumentRegistry.resolve('theremin').id, 'guitar');
      expect(instrumentRegistry.defaultId, 'guitar');
    });

    test('only fretted instruments support a capo', () {
      expect(instrumentRegistry.resolve('guitar').supportsCapo, isTrue);
      expect(instrumentRegistry.resolve('ukulele').supportsCapo, isTrue);
      expect(instrumentRegistry.resolve('piano').supportsCapo, isFalse);
    });
  });

  group('fretted voicings', () {
    for (final instrument in frettedInstruments) {
      test('${instrument.id}: tuning matches its string count', () async {
        expect(instrument.tuning, isNotEmpty);
      });

      test('${instrument.id}: every chord resolves to a valid shape', () {
        for (final symbol in _chords) {
          final parsed = parseChordSymbol(symbol)!;
          final fingering = instrument.fingering(parsed);
          expect(
            fingering,
            isA<FrettedFingering>(),
            reason: '${instrument.id} has no voicing for $symbol',
          );

          final fretted = fingering! as FrettedFingering;
          expect(
            fretted.stringCount,
            instrument.tuning.length,
            reason: '$symbol on ${instrument.id} must fret every string',
          );
          expect(
            fretted.frets.every((f) => f <= 15),
            isTrue,
            reason: '$symbol on ${instrument.id} produces an unusable fret',
          );
        }
      });

      test('${instrument.id}: sounding notes belong to the chord', () {
        for (final symbol in _chords) {
          final parsed = parseChordSymbol(symbol)!;
          final fingering =
              instrument.fingering(parsed)! as FrettedFingering;
          final expected = _expectedPitchClasses(parsed);
          final sounded = _soundedPitchClasses(fingering, instrument.tuning);

          expect(
            sounded,
            isNotEmpty,
            reason: '$symbol on ${instrument.id} sounds nothing',
          );
          expect(
            sounded.difference(expected),
            isEmpty,
            reason:
                '$symbol on ${instrument.id} sounds foreign notes '
                '${sounded.difference(expected)}',
          );
          expect(
            sounded.contains(pitchClass(parsed.rootSemitone)),
            isTrue,
            reason: '$symbol on ${instrument.id} omits its root',
          );
        }
      });
    }
  });

  group('keyboard voicings', () {
    test('spells chord tones from the quality intervals', () {
      final fingering =
          chordDictionary.getFingering('Cmaj7')!.forInstrument('piano')
              as KeyboardFingering;
      expect(fingering.notes, ['C', 'E', 'G', 'B']);
      expect(fingering.highlightKeys, containsAll(<int>[0, 4, 7, 11]));
    });

    test('renders every chord within the drawn keyboard range', () {
      for (final symbol in _chords) {
        final fingering =
            chordDictionary.getFingering(symbol)!.forInstrument('piano')
                as KeyboardFingering;
        expect(fingering.notes, isNotEmpty, reason: '$symbol has no piano notes');
        expect(
          fingering.highlightKeys.every((k) => k >= 0 && k < 24),
          isTrue,
          reason: '$symbol has keys outside the keyboard: ${fingering.highlightKeys}',
        );
      }
    });
  });

  group('chord dictionary', () {
    test('returns a voicing per registered instrument', () {
      final fingering = chordDictionary.getFingering('Am7')!;
      expect(fingering.qualityId, 'm7');
      expect(fingering.fingerings.keys, containsAll(<String>['guitar', 'ukulele', 'piano']));
      expect(fingering.forInstrument('banjo'), isNull);
    });

    test('returns null for unparseable symbols', () {
      expect(chordDictionary.getFingering(''), isNull);
      expect(chordDictionary.getFingering('???'), isNull);
    });
  });
}
