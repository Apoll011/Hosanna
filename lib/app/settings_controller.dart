import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/input/pedal_bindings.dart';
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
    this.serviceOrderSidePanel = false,
    this.pedalEnabled = true,
    this.pedalActionMode = PedalActionMode.navigateSongs,
    this.pedalPreset = PedalPreset.universal,
    this.pedalCustomNextKeyId,
    this.pedalCustomPrevKeyId,
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

  /// Whether the user will sync live service song annotations.
  final bool syncAnnotations;

  /// Non-musician tablet layout: keep the service order visible in a side rail.
  final bool serviceOrderSidePanel;

  /// Whether Bluetooth HID page-turner pedals drive prev/next.
  final bool pedalEnabled;

  /// Navigate songs vs scroll one page within the song.
  final PedalActionMode pedalActionMode;

  /// Named pedal key layout, or [PedalPreset.custom].
  final PedalPreset pedalPreset;

  /// LogicalKeyboardKey.keyId for custom Next (when preset is custom).
  final int? pedalCustomNextKeyId;

  /// LogicalKeyboardKey.keyId for custom Prev (when preset is custom).
  final int? pedalCustomPrevKeyId;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? highContrast,
    String? localeCode,
    bool clearLocale = false,
    bool? keepScreenAwake,
    bool? musicianMode,
    bool? syncAnnotations,
    bool? serviceOrderSidePanel,
    bool? pedalEnabled,
    PedalActionMode? pedalActionMode,
    PedalPreset? pedalPreset,
    int? pedalCustomNextKeyId,
    int? pedalCustomPrevKeyId,
    bool clearPedalCustomNext = false,
    bool clearPedalCustomPrev = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      musicianMode: musicianMode ?? this.musicianMode,
      syncAnnotations: syncAnnotations ?? this.syncAnnotations,
      serviceOrderSidePanel:
          serviceOrderSidePanel ?? this.serviceOrderSidePanel,
      pedalEnabled: pedalEnabled ?? this.pedalEnabled,
      pedalActionMode: pedalActionMode ?? this.pedalActionMode,
      pedalPreset: pedalPreset ?? this.pedalPreset,
      pedalCustomNextKeyId: clearPedalCustomNext
          ? null
          : (pedalCustomNextKeyId ?? this.pedalCustomNextKeyId),
      pedalCustomPrevKeyId: clearPedalCustomPrev
          ? null
          : (pedalCustomPrevKeyId ?? this.pedalCustomPrevKeyId),
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
  static const _serviceOrderSidePanelKey = 'settings.serviceOrderSidePanel';
  static const _pedalEnabledKey = 'settings.pedalEnabled';
  static const _pedalActionModeKey = 'settings.pedalActionMode';
  static const _pedalPresetKey = 'settings.pedalPreset';
  static const _pedalCustomNextKey = 'settings.pedalCustomNextKeyId';
  static const _pedalCustomPrevKey = 'settings.pedalCustomPrevKeyId';

  final SharedPreferences _prefs;

  void _restore() {
    state = AppSettings(
      themeMode: _themeModeFromName(_prefs.getString(_themeKey)),
      highContrast: _prefs.getBool(_contrastKey) ?? false,
      localeCode: _prefs.getString(_localeKey),
      keepScreenAwake: _prefs.getBool(_keepAwakeKey) ?? false,
      musicianMode: _prefs.getBool(_musicianModeKey) ?? true,
      syncAnnotations: _prefs.getBool(_syncAnnotation) ?? true,
      serviceOrderSidePanel: _prefs.getBool(_serviceOrderSidePanelKey) ?? false,
      pedalEnabled: _prefs.getBool(_pedalEnabledKey) ?? true,
      pedalActionMode: pedalActionModeFromName(
        _prefs.getString(_pedalActionModeKey),
      ),
      pedalPreset: pedalPresetFromName(_prefs.getString(_pedalPresetKey)),
      pedalCustomNextKeyId: _prefs.getInt(_pedalCustomNextKey),
      pedalCustomPrevKeyId: _prefs.getInt(_pedalCustomPrevKey),
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

  void setServiceOrderSidePanel(bool value) {
    state = state.copyWith(serviceOrderSidePanel: value);
    _prefs.setBool(_serviceOrderSidePanelKey, value);
  }

  void setPedalEnabled(bool value) {
    state = state.copyWith(pedalEnabled: value);
    _prefs.setBool(_pedalEnabledKey, value);
  }

  void setPedalActionMode(PedalActionMode mode) {
    state = state.copyWith(pedalActionMode: mode);
    _prefs.setString(_pedalActionModeKey, mode.name);
  }

  void setPedalPreset(PedalPreset preset) {
    state = state.copyWith(pedalPreset: preset);
    _prefs.setString(_pedalPresetKey, preset.name);
  }

  void setPedalCustomNextKeyId(int? keyId) {
    if (keyId == null) {
      state = state.copyWith(clearPedalCustomNext: true);
      _prefs.remove(_pedalCustomNextKey);
    } else {
      state = state.copyWith(pedalCustomNextKeyId: keyId);
      _prefs.setInt(_pedalCustomNextKey, keyId);
    }
  }

  void setPedalCustomPrevKeyId(int? keyId) {
    if (keyId == null) {
      state = state.copyWith(clearPedalCustomPrev: true);
      _prefs.remove(_pedalCustomPrevKey);
    } else {
      state = state.copyWith(pedalCustomPrevKeyId: keyId);
      _prefs.setInt(_pedalCustomPrevKey, keyId);
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      return SettingsController(ref.watch(sharedPreferencesProvider));
    });
