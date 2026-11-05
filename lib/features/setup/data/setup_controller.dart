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

  Future<void> apply(SetupDraft draft, {
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
