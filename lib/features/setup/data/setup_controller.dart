import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../app/settings_controller.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../domain/setup_draft.dart';

/// Tracks whether the post-login setup wizard has been finished.
class SetupController extends StateNotifier<bool> {
  SetupController(this._prefs) : super(false) {
    state = _readCompleted();
  }

  static const completedKey = 'setup.completed';
  static const roleKey = 'setup.role';
  static const inviteRoleKey = 'setup.inviteRole';

  final SharedPreferences _prefs;

  bool get isComplete => state;

  bool _readCompleted() {
    if (_prefs.containsKey(completedKey)) {
      return _prefs.getBool(completedKey) ?? false;
    }
    // Existing installs already have prefs — don't force them through setup.
    final returningUser = _prefs.containsKey('settings.musicianMode') ||
        _prefs.containsKey('songDisplay.instrument') ||
        _prefs.containsKey('songDisplay.showChords');
    if (returningUser) {
      _prefs.setBool(completedKey, true);
      return true;
    }
    return false;
  }

  /// Maps an org-invite role to the setup musician/leader choice.
  static SetupRole? roleFromInvite(String? inviteRole) {
    if (inviteRole == null || inviteRole.isEmpty) return null;
    return switch (inviteRole.toLowerCase()) {
      'owner' || 'admin' || 'editor' => SetupRole.leader,
      'musician' || 'guest' || 'member' => SetupRole.musician,
      _ => null,
    };
  }

  static SetupPrimaryFocus focusFromInstrument(String instrumentId) {
    return switch (instrumentId) {
      'ukulele' => SetupPrimaryFocus.ukulele,
      'piano' => SetupPrimaryFocus.piano,
      _ => SetupPrimaryFocus.guitar,
    };
  }

  /// Prefills the wizard from saved setup, current prefs, or the last invite.
  SetupDraft initialDraft({
    required AppSettings settings,
    required SongDisplaySettings display,
  }) {
    final savedRoleName = _prefs.getString(roleKey);
    SetupRole? role;
    if (savedRoleName == SetupRole.leader.name ||
        savedRoleName == SetupRole.musician.name) {
      role = SetupRole.values.byName(savedRoleName!);
    } else {
      role = roleFromInvite(_prefs.getString(inviteRoleKey));
    }

    // Musician mode already persisted (redo) wins over invite mapping.
    if (_prefs.containsKey('settings.musicianMode')) {
      role = settings.musicianMode ? SetupRole.musician : SetupRole.leader;
    }

    final focus = role == SetupRole.leader
        ? null
        : focusFromInstrument(display.instrument);

    return SetupDraft(
      role: role,
      focus: focus,
      showDiagrams: role == SetupRole.leader ? false : display.showDiagrams,
      keepScreenAwake: settings.keepScreenAwake,
      localeCode: settings.localeCode,
    );
  }

  Future<void> rememberInviteRole(String role) async {
    await _prefs.setString(inviteRoleKey, role);
  }

  Future<void> apply(
    SetupDraft draft, {
    required SettingsController settings,
    required SongDisplaySettingsController display,
  }) async {
    final isMusician = draft.role == SetupRole.musician;
    settings.setMusicianMode(isMusician);
    settings.setKeepScreenAwake(draft.keepScreenAwake);
    settings.setLocale(draft.localeCode);

    display.setInstrument(draft.instrumentId);
    display.setShowChords(true);
    display.setShowDiagrams(draft.prefersDiagrams);

    final roleName = draft.role?.name;
    if (roleName != null) {
      await _prefs.setString(roleKey, roleName);
    }
    await _prefs.remove(inviteRoleKey);
    await _prefs.setBool(completedKey, true);
    state = true;
  }

  /// Allows re-running setup from Settings later.
  Future<void> reset() async {
    await _prefs.setBool(completedKey, false);
    state = false;
  }
}

final setupControllerProvider =
    StateNotifierProvider<SetupController, bool>((ref) {
  return SetupController(ref.watch(sharedPreferencesProvider));
});
