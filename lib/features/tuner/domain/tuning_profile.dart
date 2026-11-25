import 'dart:math' as math;

import 'package:pitch_kit/pitch_kit.dart';

import '../../songs/domain/chordpro/instruments/instruments.dart';

class TuningProfile {
  const TuningProfile({required this.id, required this.profile});

  final String id;
  final InstrumentProfile profile;

  List<OpenString> get strings => profile.openStrings;
  bool get isValid =>
      strings.isNotEmpty &&
      strings.every(
        (string) =>
            string.frequency.isFinite &&
            string.frequency > 0 &&
            string.name.isNotEmpty,
      );
}

class TuningProfileResolver {
  static InstrumentProfile? libraryProfile(String id) => switch (id) {
    'guitar' => InstrumentProfile.guitar,
    'bass' => InstrumentProfile.bass,
    'ukulele' => InstrumentProfile.ukulele,
    _ => null,
  };

  static TuningProfile? resolve({
    required String instrumentId,
    required InstrumentPreference preference,
  }) {
    final base = libraryProfile(instrumentId);
    if (base == null) return null;

    List<OpenString> strings = base.openStrings;
    if (preference.customTuning != null) {
      strings = [
        for (final string in preference.customTuning!)
          OpenString(string.name ?? string.note, string.frequency),
      ];
    } else if (preference.tuningId != null &&
        preference.tuningId != 'standard') {
      final instrument = instrumentRegistry.resolve(instrumentId);
      if (instrument is FrettedInstrument) {
        final tuning = instrument.tuningFor(preference.tuningId);
        strings = _retune(base.openStrings, tuning);
      }
    }

    if (strings.isEmpty ||
        strings.any(
          (string) =>
              !string.frequency.isFinite ||
              string.frequency <= 0 ||
              string.name.isEmpty,
        )) {
      return null;
    }

    final profile = InstrumentProfile(
      name: base.name,
      minFreq: math.min(
        base.minFreq,
        strings.map((e) => e.frequency).reduce(math.min) * 0.8,
      ),
      maxFreq: base.maxFreq,
      bassCeiling: base.bassCeiling,
      harmonicPivot: base.harmonicPivot,
      openStrings: strings,
      rmsGate: base.rmsGate,
      useFlats: base.useFlats,
    );
    final resolved = TuningProfile(id: instrumentId, profile: profile);
    return resolved.isValid ? resolved : null;
  }

  static List<OpenString> _retune(
    List<OpenString> defaults,
    FrettedTuning tuning,
  ) {
    final extraLowStrings = math.max(0, tuning.stringCount - defaults.length);
    return [
      for (var index = 0; index < tuning.stringCount; index++)
        _retunedString(defaults, tuning, index, extraLowStrings),
    ];
  }

  static OpenString _retunedString(
    List<OpenString> defaults,
    FrettedTuning tuning,
    int index,
    int extraLowStrings,
  ) {
    final baseIndex = index - extraLowStrings;
    final reference = baseIndex < 0
        ? defaults.first.frequency / math.pow(2, -baseIndex)
        : defaults[math.min(baseIndex, defaults.length - 1)].frequency;
    final referenceMidi = (69 + 12 * (math.log(reference / 440) / math.ln2))
        .round();
    final pitchClass = tuning.openPitches[index];
    final referenceClass = referenceMidi % 12;
    final interval = ((pitchClass - referenceClass + 6) % 12) - 6;
    final frequency = reference * math.pow(2, interval / 12);
    final name = tuning.stringNames[index];
    final octave =
        (69 + 12 * (math.log(frequency / 440) / math.ln2)).round() ~/ 12 - 1;
    return OpenString('$name$octave', frequency);
  }
}

class MatchedString {
  const MatchedString({required this.string, required this.cents});

  final OpenString string;
  final double cents;
}

MatchedString matchString(double frequency, List<OpenString> strings) {
  OpenString? closest;
  var cents = double.infinity;
  for (final string in strings) {
    final deviation =
        1200 * (math.log(frequency / string.frequency) / math.ln2);
    if (deviation.abs() < cents.abs()) {
      closest = string;
      cents = deviation;
    }
  }
  return MatchedString(string: closest!, cents: cents);
}

class PitchStabilityFilter {
  PitchStabilityFilter({this.requiredReadings = 4, this.maxSpreadCents = 8});

  final int requiredReadings;
  final double maxSpreadCents;
  final List<double> _readings = [];

  double? add(double frequency) {
    if (!frequency.isFinite || frequency <= 0) {
      reset();
      return null;
    }
    _readings.add(frequency);
    if (_readings.length > requiredReadings) _readings.removeAt(0);
    if (_readings.length < requiredReadings) return null;
    final reference = _readings[_readings.length ~/ 2];
    final deviations = _readings
        .map((value) => (1200 * (math.log(value / reference) / math.ln2)).abs())
        .toList();
    if (deviations.any((value) => value > maxSpreadCents)) return null;
    return _readings.reduce((a, b) => a + b) / _readings.length;
  }

  void reset() => _readings.clear();
}
