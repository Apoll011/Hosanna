import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_kit/pitch_kit.dart';
import 'package:hosanna/features/songs/domain/chordpro/instruments/instrument_preferences.dart';
import 'package:hosanna/features/tuner/domain/tuning_profile.dart';

void main() {
  group('TuningProfileResolver', () {
    test('uses pitch_kit standard instrument profiles', () {
      final guitar = TuningProfileResolver.resolve(
        instrumentId: 'guitar',
        preference: InstrumentPreference.defaults,
      );
      final bass = TuningProfileResolver.resolve(
        instrumentId: 'bass',
        preference: InstrumentPreference.defaults,
      );
      final ukulele = TuningProfileResolver.resolve(
        instrumentId: 'ukulele',
        preference: InstrumentPreference.defaults,
      );

      expect(guitar!.strings.map((string) => string.name), [
        'E2',
        'A2',
        'D3',
        'G3',
        'B3',
        'E4',
      ]);
      expect(bass!.strings, hasLength(4));
      expect(ukulele!.strings, hasLength(4));
    });

    test('custom strings override library defaults and preserve order', () {
      final resolved = TuningProfileResolver.resolve(
        instrumentId: 'guitar',
        preference: InstrumentPreference(
          customTuning: const [
            CustomTuningString(note: 'D2', name: 'Low D', frequency: 73.42),
            CustomTuningString(note: 'A2', frequency: 110),
          ],
        ),
      );

      expect(resolved!.strings.map((string) => string.name), ['Low D', 'A2']);
      expect(resolved.strings.map((string) => string.frequency), [73.42, 110]);
    });

    test('existing preference JSON remains backwards compatible', () {
      final preference = InstrumentPreference.fromJson({
        'showFingerNumbers': false,
        'tuningId': 'drop_d',
      });

      expect(preference.showFingerNumbers, isFalse);
      expect(preference.tuningId, 'drop_d');
      expect(preference.customTuning, isNull);
    });

    test('custom tuning survives preference JSON round trip', () {
      const original = InstrumentPreference(
        customTuning: [
          CustomTuningString(note: 'D2', name: 'Low D', frequency: 73.42),
        ],
      );
      final restored = InstrumentPreference.fromJson(original.toJson());

      expect(restored.customTuning!.single.note, 'D2');
      expect(restored.customTuning!.single.name, 'Low D');
      expect(restored.customTuning!.single.frequency, 73.42);
    });

    test('unknown instruments and invalid custom tunings are unavailable', () {
      expect(
        TuningProfileResolver.resolve(
          instrumentId: 'keyboard',
          preference: InstrumentPreference.defaults,
        ),
        isNull,
      );
      expect(
        TuningProfileResolver.resolve(
          instrumentId: 'guitar',
          preference: const InstrumentPreference(customTuning: []),
        ),
        isNull,
      );
    });
  });

  group('tuner pitch matching and stability', () {
    test('matches the nearest configured target and computes deviation', () {
      const strings = [OpenString('E2', 82.41), OpenString('A2', 110)];
      final match = matchString(111, strings);

      expect(match.string.name, 'A2');
      expect(match.cents, closeTo(15.6, 0.2));
    });

    test('waits for consecutive stable readings and resets on noise', () {
      final filter = PitchStabilityFilter(
        requiredReadings: 3,
        maxSpreadCents: 5,
      );

      expect(filter.add(110), isNull);
      expect(filter.add(110.1), isNull);
      expect(filter.add(120), isNull);
      expect(filter.add(110.02), isNull);
      expect(filter.add(110.03), isNull);
      expect(filter.add(110.01), closeTo(110.02, 0.02));
      expect(filter.add(double.nan), isNull);
      expect(filter.add(110), isNull);
    });
  });
}
