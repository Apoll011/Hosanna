import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';
import 'theme.dart';

/// User-configurable appearance/language settings, persisted in prefs.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.highContrast = false,
    this.localeCode,
    this.keepScreenAwake = false,
    this.musicianMode = true,
    this.syncAnnotations = false,
  });

  final AppThemeMode themeMode;
  final bool highContrast;

  /// `null` follows the system locale; otherwise a BCP-47 code (`pt`, `en`,
  /// `es`).
  final String? localeCode;

  /// Whether the screen stays awake while viewing a song/service.
  final bool keepScreenAwake;

  /// Whether services open directly in musician view (first song + order nav).
  final bool musicianMode;

  ///Wheather the user will sync with the other userver service song anotations
  final bool syncAnnotations;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? highContrast,
    String? localeCode,
    bool clearLocale = false,
    bool? keepScreenAwake,
    bool? musicianMode,
    bool? syncAnnotations,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      musicianMode: musicianMode ?? this.musicianMode,
      syncAnnotations: syncAnnotations ?? this.syncAnnotations,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs) : super(const AppSettings()) {
    _restore();
  }

  static const _themeKey = 'settings.themeMode';
  static const _contrastKey = 'settings.highContrast';
  static const _localeKey = 'settings.locale';
  static const _keepAwakeKey = 'settings.keepScreenAwake';
  static const _musicianModeKey = 'settings.musicianMode';
  static const _syncAnnotation = 'settings.syncAnnotation';

  final SharedPreferences _prefs;

  void _restore() {
    state = AppSettings(
      themeMode: _themeModeFromName(_prefs.getString(_themeKey)),
      highContrast: _prefs.getBool(_contrastKey) ?? false,
      localeCode: _prefs.getString(_localeKey),
      keepScreenAwake: _prefs.getBool(_keepAwakeKey) ?? false,
      musicianMode: _prefs.getBool(_musicianModeKey) ?? true,
      syncAnnotations: _prefs.getBool(_syncAnnotation) ?? true,
    );
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_themeKey, mode.name);
  }

  void setHighContrast(bool value) {
    state = state.copyWith(highContrast: value);
    _prefs.setBool(_contrastKey, value);
  }

  void setLocale(String? code) {
    state = code == null
        ? state.copyWith(clearLocale: true)
        : state.copyWith(localeCode: code);
    if (code == null) {
      _prefs.remove(_localeKey);
    } else {
      _prefs.setString(_localeKey, code);
    }
  }

  void setKeepScreenAwake(bool value) {
    state = state.copyWith(keepScreenAwake: value);
    _prefs.setBool(_keepAwakeKey, value);
  }

  void setMusicianMode(bool value) {
    state = state.copyWith(musicianMode: value);
    _prefs.setBool(_musicianModeKey, value);
  }

  static AppThemeMode _themeModeFromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppThemeMode.system,
    );
  }

  void setSyncAnnotations(bool value) {
    state = state.copyWith(syncAnnotations: value);
    _prefs.setBool(_syncAnnotation, value);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      return SettingsController(ref.watch(sharedPreferencesProvider));
    });
