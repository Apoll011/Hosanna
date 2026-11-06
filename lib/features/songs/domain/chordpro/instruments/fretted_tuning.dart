/// A named open-string configuration for a fretted instrument.
///
/// Tunings share the instrument's shape library when their [stringCount]
/// matches the authored shapes; longer tunings (e.g. 7-string) mute the
/// extra bass string(s), shorter ones (e.g. baritone from 6-string source)
/// keep the treble side.
class FrettedTuning {
  const FrettedTuning({
    required this.id,
    required this.label,
    required this.openPitches,
    required this.stringNames,
  });

  /// Stable id persisted in [InstrumentPreference.tuningId] (e.g. `standard`).
  final String id;

  /// Non-localized display name; presentation may override via l10n.
  final String label;

  /// Open-string pitch classes (0 = C), leftmost diagram string first.
  final List<int> openPitches;

  /// Short labels drawn under each string (e.g. `E`, `A`, `D`, `G`, `B`, `e`).
  final List<String> stringNames;

  int get stringCount => openPitches.length;
}

/// Guitar / ukulele / etc. built-in tunings.
abstract final class FrettedTunings {
  // ── Guitar ──────────────────────────────────────────────────────────────

  /// Standard E₂ A₂ D₃ G₃ B₃ E₄ (diagram left → right: low E → high e).
  static const guitarStandard = FrettedTuning(
    id: 'standard',
    label: 'Standard',
    openPitches: [4, 9, 2, 7, 11, 4],
    stringNames: ['E', 'A', 'D', 'G', 'B', 'e'],
  );

  /// Drop D — low string down a whole step.
  static const guitarDropD = FrettedTuning(
    id: 'drop_d',
    label: 'Drop D',
    openPitches: [2, 9, 2, 7, 11, 4],
    stringNames: ['D', 'A', 'D', 'G', 'B', 'e'],
  );

  /// Standard 7-string (B₁ + EADGBE). Shapes are 6-string with a muted low B.
  static const guitarSevenString = FrettedTuning(
    id: 'seven_string',
    label: '7-string',
    openPitches: [11, 4, 9, 2, 7, 11, 4],
    stringNames: ['B', 'E', 'A', 'D', 'G', 'B', 'e'],
  );

  static const List<FrettedTuning> guitar = [
    guitarStandard,
    guitarDropD,
    guitarSevenString,
  ];

  // ── Ukulele ─────────────────────────────────────────────────────────────

  /// Re-entrant high-G soprano/concert/tenor (G₄ C₄ E₄ A₄).
  static const ukuleleHighG = FrettedTuning(
    id: 'high_g',
    label: 'High G',
    openPitches: [7, 0, 4, 9],
    stringNames: ['G', 'C', 'E', 'A'],
  );

  /// Linear low-G (same pitch classes; G sounds an octave lower).
  static const ukuleleLowG = FrettedTuning(
    id: 'low_g',
    label: 'Low G',
    openPitches: [7, 0, 4, 9],
    stringNames: ['G', 'C', 'E', 'A'],
  );

  /// Baritone ukulele in DGBE (guitar's top four strings).
  static const ukuleleBaritone = FrettedTuning(
    id: 'baritone',
    label: 'Baritone',
    openPitches: [2, 7, 11, 4],
    stringNames: ['D', 'G', 'B', 'E'],
  );

  static const List<FrettedTuning> ukulele = [
    ukuleleHighG,
    ukuleleLowG,
    ukuleleBaritone,
  ];
}
