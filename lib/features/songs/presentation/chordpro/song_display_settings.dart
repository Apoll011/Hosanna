import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/providers.dart';

/// Renderer display settings, mirroring `@hosanna/shared`'s ChordProRenderer
/// props (transpose, capo, show chords, two-column, font size, instrument,
/// diagrams). Appearance settings are persisted; transpose/capo are transient.
class SongDisplaySettings {
  const SongDisplaySettings({
    this.transpose = 0,
    this.capo = 0,
    this.showChords = true,
    this.twoColumn = false,
    this.fontSize = 14,
    this.instrument = 'guitar',
    this.showDiagrams = false,
    this.sectionColorBackground = false,
    this.autoScrollSpeed = 5,
  });

  final int transpose;
  final int capo;
  final bool showChords;
  final bool twoColumn;
  final double fontSize;
  final String instrument; // 'guitar' | 'piano'
  final bool showDiagrams;
  final bool sectionColorBackground;

  /// Auto-scroll speed, 1..10 (transient).
  final double autoScrollSpeed;

  bool get isGuitar => instrument == 'guitar';

  SongDisplaySettings copyWith({
    int? transpose,
    int? capo,
    bool? showChords,
    bool? twoColumn,
    double? fontSize,
    String? instrument,
    bool? showDiagrams,
    bool? sectionColorBackground,
    double? autoScrollSpeed,
  }) {
    return SongDisplaySettings(
      transpose: transpose ?? this.transpose,
      capo: capo ?? this.capo,
      showChords: showChords ?? this.showChords,
      twoColumn: twoColumn ?? this.twoColumn,
      fontSize: fontSize ?? this.fontSize,
      instrument: instrument ?? this.instrument,
      showDiagrams: showDiagrams ?? this.showDiagrams,
      sectionColorBackground:
          sectionColorBackground ?? this.sectionColorBackground,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
    );
  }
}

class SongDisplaySettingsController extends StateNotifier<SongDisplaySettings> {
  SongDisplaySettingsController(this._prefs) : super(const SongDisplaySettings()) {
    _restore();
  }

  final SharedPreferences _prefs;

  static const _showChordsKey = 'songDisplay.showChords';
  static const _twoColumnKey = 'songDisplay.twoColumn';
  static const _fontSizeKey = 'songDisplay.fontSize';
  static const _instrumentKey = 'songDisplay.instrument';
  static const _diagramsKey = 'songDisplay.showDiagrams';
  static const _sectionColorBackgroundKey = 'songDisplay.sectionColorBackground';

  void _restore() {
    state = SongDisplaySettings(
      showChords: _prefs.getBool(_showChordsKey) ?? true,
      twoColumn: _prefs.getBool(_twoColumnKey) ?? false,
      fontSize: _prefs.getDouble(_fontSizeKey) ?? 14,
      instrument: _prefs.getString(_instrumentKey) ?? 'guitar',
      showDiagrams: _prefs.getBool(_diagramsKey) ?? false,
      sectionColorBackground:
          _prefs.getBool(_sectionColorBackgroundKey) ?? false,
    );
  }

  void setTranspose(int value) => state = state.copyWith(transpose: value);

  void setCapo(int value) => state = state.copyWith(capo: value);

  void resetTransposition() =>
      state = state.copyWith(transpose: 0, capo: 0);

  void toggleShowChords() {
    final v = !state.showChords;
    _prefs.setBool(_showChordsKey, v);
    state = state.copyWith(showChords: v);
  }

  void toggleTwoColumn() {
    final v = !state.twoColumn;
    _prefs.setBool(_twoColumnKey, v);
    state = state.copyWith(twoColumn: v);
  }

  void toggleSectionColorBackground() {
    final v = !state.sectionColorBackground;
    _prefs.setBool(_sectionColorBackgroundKey, v);
    state = state.copyWith(sectionColorBackground: v);
  }

  void setFontSize(double value) {
    final v = value.clamp(10.0, 24.0).toDouble();
    _prefs.setDouble(_fontSizeKey, v);
    state = state.copyWith(fontSize: v);
  }

  void setInstrument(String value) {
    _prefs.setString(_instrumentKey, value);
    state = state.copyWith(instrument: value);
  }

  void toggleDiagrams() {
    final v = !state.showDiagrams;
    _prefs.setBool(_diagramsKey, v);
    state = state.copyWith(showDiagrams: v);
  }

  void setAutoScrollSpeed(double value) {
    state = state.copyWith(autoScrollSpeed: value.clamp(1, 10).toDouble());
  }
}

final songDisplaySettingsProvider = StateNotifierProvider<
    SongDisplaySettingsController, SongDisplaySettings>((ref) {
  return SongDisplaySettingsController(
    ref.watch(sharedPreferencesProvider),
  );
});
