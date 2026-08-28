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
  });

  final AppThemeMode themeMode;
  final bool highContrast;

  /// `null` follows the system locale; otherwise a BCP-47 code (`pt`, `en`,
  /// `es`).
  final String? localeCode;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? highContrast,
    String? localeCode,
    bool clearLocale = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
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

  final SharedPreferences _prefs;

  void _restore() {
    state = AppSettings(
      themeMode: _themeModeFromName(_prefs.getString(_themeKey)),
      highContrast: _prefs.getBool(_contrastKey) ?? false,
      localeCode: _prefs.getString(_localeKey),
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
    state = code == null ? state.copyWith(clearLocale: true) : state.copyWith(localeCode: code);
    if (code == null) {
      _prefs.remove(_localeKey);
    } else {
      _prefs.setString(_localeKey, code);
    }
  }

  static AppThemeMode _themeModeFromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppThemeMode.system,
    );
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(sharedPreferencesProvider));
});
