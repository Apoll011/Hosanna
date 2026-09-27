import '../chord_theory.dart';
import 'instrument.dart';

/// How a keyboard voices chords.
enum PianoVoicingStyle {
  /// Every chord tone (root included) in one cluster — the classic textbook
  /// spelling.
  full,

  /// More compact "shell" voicings: for 7th+ chords the root is omitted from
  /// the right hand (e.g. C7 → Bb-E-G), and extended chords drop the 5th when
  /// it crowds the span. Preferred by many accompanists.
  compact,
}

/// Per-instrument preferences that affect voicing and diagram rendering.
///
/// Each instrument id has its own bag of settings so guitar, ukulele and piano
/// can be tuned independently. Unknown ids fall back to [InstrumentPreference.defaults].
class InstrumentPreference {
  const InstrumentPreference({
    this.showFingerNumbers = true,
    this.showCapoMarker = true,
    this.pianoVoicingStyle = PianoVoicingStyle.full,
    this.pianoSlashSplitHands = true,
  });

  /// Fretted: paint 1–4 inside the fretting dots.
  final bool showFingerNumbers;

  /// Fretted: draw the capo clamp on the nut when a capo is active.
  final bool showCapoMarker;

  /// Piano: full vs compact (rootless) voicings.
  final PianoVoicingStyle pianoVoicingStyle;

  /// Piano: put slash-bass in the left hand (lower octave) and the chord in
  /// the right hand (upper octave). Fixes crowded A/C#-style diagrams.
  final bool pianoSlashSplitHands;

  static const defaults = InstrumentPreference();

  InstrumentPreference copyWith({
    bool? showFingerNumbers,
    bool? showCapoMarker,
    PianoVoicingStyle? pianoVoicingStyle,
    bool? pianoSlashSplitHands,
  }) {
    return InstrumentPreference(
      showFingerNumbers: showFingerNumbers ?? this.showFingerNumbers,
      showCapoMarker: showCapoMarker ?? this.showCapoMarker,
      pianoVoicingStyle: pianoVoicingStyle ?? this.pianoVoicingStyle,
      pianoSlashSplitHands: pianoSlashSplitHands ?? this.pianoSlashSplitHands,
    );
  }

  Map<String, Object?> toJson() => {
        'showFingerNumbers': showFingerNumbers,
        'showCapoMarker': showCapoMarker,
        'pianoVoicingStyle': pianoVoicingStyle.name,
        'pianoSlashSplitHands': pianoSlashSplitHands,
      };

  factory InstrumentPreference.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    final styleName = json['pianoVoicingStyle'] as String?;
    final style = PianoVoicingStyle.values.firstWhere(
      (s) => s.name == styleName,
      orElse: () => PianoVoicingStyle.full,
    );
    return InstrumentPreference(
      showFingerNumbers: json['showFingerNumbers'] as bool? ?? true,
      showCapoMarker: json['showCapoMarker'] as bool? ?? true,
      pianoVoicingStyle: style,
      pianoSlashSplitHands: json['pianoSlashSplitHands'] as bool? ?? true,
    );
  }
}

/// Lookup of [InstrumentPreference] by instrument id.
class InstrumentPreferences {
  const InstrumentPreferences([this._byId = const {}]);

  final Map<String, InstrumentPreference> _byId;

  InstrumentPreference forId(String id) =>
      _byId[id] ?? InstrumentPreference.defaults;

  InstrumentPreferences upsert(String id, InstrumentPreference preference) {
    return InstrumentPreferences({..._byId, id: preference});
  }

  Map<String, Object?> toJson() => {
        for (final e in _byId.entries) e.key: e.value.toJson(),
      };

  factory InstrumentPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const InstrumentPreferences();
    final map = <String, InstrumentPreference>{};
    for (final e in json.entries) {
      final value = e.value;
      if (value is Map) {
        map[e.key] = InstrumentPreference.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    }
    return InstrumentPreferences(map);
  }
}

/// Options forwarded into [Instrument.fingering] so voicings can honour user
/// preferences without instruments holding mutable state.
class InstrumentFingeringOptions {
  const InstrumentFingeringOptions({
    this.pianoVoicingStyle = PianoVoicingStyle.full,
    this.pianoSlashSplitHands = true,
  });

  final PianoVoicingStyle pianoVoicingStyle;
  final bool pianoSlashSplitHands;

  factory InstrumentFingeringOptions.fromPreference(InstrumentPreference p) {
    return InstrumentFingeringOptions(
      pianoVoicingStyle: p.pianoVoicingStyle,
      pianoSlashSplitHands: p.pianoSlashSplitHands,
    );
  }

  static const defaults = InstrumentFingeringOptions();
}

/// Qualities whose compact voicing drops the root (shell / rootless 7ths).
bool isRootlessFriendlyQuality(ChordQuality quality) {
  return switch (quality.id) {
    'dom7' ||
    'maj7' ||
    'm7' ||
    'mMaj7' ||
    'm7b5' ||
    'dim7' ||
    'aug7' ||
    'dom7b5' ||
    'dom7sus4' ||
    'dom7sus2' ||
    'nine' ||
    'maj9' ||
    'm9' ||
    'eleven' ||
    'm11' ||
    'thirteen' ||
    'm13' ||
    'dom7sharp9' ||
    'dom7flat9' ||
    'maj7sharp5' ||
    'maj7flat5' ||
    'six' ||
    'm6' ||
    'six9' =>
      true,
    _ => false,
  };
}
