/// In-memory answers collected during the post-login setup wizard.
enum SetupRole { musician, leader }

enum SetupPrimaryFocus {
  guitar,
  ukulele,
  piano,
  vocals,
}

class SetupDraft {
  const SetupDraft({
    this.role,
    this.focus,
    this.showDiagrams = true,
    this.keepScreenAwake = true,
    this.localeCode,
  });

  final SetupRole? role;
  final SetupPrimaryFocus? focus;
  final bool showDiagrams;
  final bool keepScreenAwake;

  /// `null` = follow system locale.
  final String? localeCode;

  bool get isMusician => role == SetupRole.musician;

  /// Instrument id persisted for chord diagrams / capo behaviour.
  String get instrumentId => switch (focus) {
        SetupPrimaryFocus.ukulele => 'ukulele',
        SetupPrimaryFocus.piano => 'piano',
        SetupPrimaryFocus.guitar || SetupPrimaryFocus.vocals || null => 'guitar',
      };

  /// Chord diagrams are most useful for fretted/keyboard players.
  bool get prefersDiagrams {
    if (focus == SetupPrimaryFocus.vocals) return false;
    return showDiagrams;
  }

  SetupDraft copyWith({
    SetupRole? role,
    SetupPrimaryFocus? focus,
    bool? showDiagrams,
    bool? keepScreenAwake,
    String? localeCode,
    bool clearLocale = false,
  }) {
    return SetupDraft(
      role: role ?? this.role,
      focus: focus ?? this.focus,
      showDiagrams: showDiagrams ?? this.showDiagrams,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    );
  }
}
