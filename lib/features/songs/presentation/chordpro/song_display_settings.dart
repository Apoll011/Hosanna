import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/providers.dart';
import '../../domain/chordpro/instruments/instruments.dart';
import '../../domain/chordpro/resolve_chords.dart';
import '../../domain/chordpro/chord_notation.dart';
import '../../../songs/domain/chordpro/parser.dart';

/// Renderer display settings, mirroring `@hosanna/shared`'s ChordProRenderer
/// props (transpose, capo, show chords, two-column, font size, instrument,
/// diagrams).
///
/// Appearance settings are persisted globally. Transpose/capo/variant are
/// transient for standalone song views, and persisted per `(serviceId, songId)`
/// while reading inside a service.
class SongDisplaySettings {
  /// Shared font-size range for the song reader toolbar and Settings.
  static const double minFontSize = 12;
  static const double maxFontSize = 28;
  static const double defaultFontSize = 14;

  const SongDisplaySettings({
    this.transpose = 0,
    this.capo = 0,
    this.showChords = true,
    this.twoColumn = false,
    this.fontSize = defaultFontSize,
    this.instrument = 'guitar',
    this.showDiagrams = false,
    this.sectionColorBackground = false,
    this.autoScrollSpeed = 5,
    this.variantId = 'default',
    this.chordNotationId = 'international',
    this.instrumentPreferences = const InstrumentPreferences(),
  });

  final int transpose;
  final int capo;
  final bool showChords;
  final bool twoColumn;
  final double fontSize;
  final String
  instrument; // any registered instrument id (see instrumentRegistry)
  final bool showDiagrams;
  final bool sectionColorBackground;

  /// Auto-scroll speed, 1..10 (transient).
  final double autoScrollSpeed;

  /// Active variant id. Persisted only while scoped to a service song.
  final String variantId;

  final String chordNotationId;

  /// Per-instrument voicing / diagram preferences.
  final InstrumentPreferences instrumentPreferences;

  /// The instrument selected for the current song.
  Instrument get instrumentInfo => instrumentRegistry.resolve(instrument);

  /// Preference bag for the currently selected instrument.
  InstrumentPreference get currentInstrumentPreference =>
      instrumentPreferences.forId(instrument);

  /// Whether a capo changes the sounding pitch for the selected instrument.
  bool get instrumentSupportsCapo => instrumentInfo.supportsCapo;

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
    String? variantId,
    String? chordNotationId,
    InstrumentPreferences? instrumentPreferences,
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
      variantId: variantId ?? this.variantId,
      chordNotationId: chordNotationId ?? this.chordNotationId,
      instrumentPreferences:
          instrumentPreferences ?? this.instrumentPreferences,
    );
  }
}

class SongDisplaySettingsController extends StateNotifier<SongDisplaySettings> {
  SongDisplaySettingsController(this._prefs)
    : super(const SongDisplaySettings()) {
    _restore();
  }

  final SharedPreferences _prefs;

  static const _showChordsKey = 'songDisplay.showChords';
  static const _twoColumnKey = 'songDisplay.twoColumn';
  static const _fontSizeKey = 'songDisplay.fontSize';
  static const _instrumentKey = 'songDisplay.instrument';
  static const _defaultInstrument = 'guitar';
  static const _diagramsKey = 'songDisplay.showDiagrams';
  static const _sectionColorBackgroundKey =
      'songDisplay.sectionColorBackground';
  static const _instrumentPreferencesKey = 'songDisplay.instrumentPreferences';
  static const _chordNotationKey = 'songDisplay.chordNotation';
  static const _serviceTranspositionsKey = 'songDisplay.serviceTranspositions';

  /// Active service-song scope (`serviceId|songId`), or `null` when reading a
  /// standalone song / nothing. Changes under a scope are written to prefs.
  String? _transpositionScopeKey;

  /// Directive defaults for the current song ({keyshift}, {capo}).
  ({int transpose, int capo}) _directiveDefaults = (transpose: 0, capo: 0);

  void _restore() {
    InstrumentPreferences instrumentPreferences = const InstrumentPreferences();
    final raw = _prefs.getString(_instrumentPreferencesKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          instrumentPreferences = InstrumentPreferences.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        // Corrupt prefs — fall back to defaults.
      }
    }

    state = SongDisplaySettings(
      showChords: _prefs.getBool(_showChordsKey) ?? true,
      twoColumn: _prefs.getBool(_twoColumnKey) ?? false,
      fontSize:
          _prefs.getDouble(_fontSizeKey) ?? SongDisplaySettings.defaultFontSize,
      instrument: instrumentRegistry
          .resolve(_prefs.getString(_instrumentKey) ?? _defaultInstrument)
          .id,
      showDiagrams: _prefs.getBool(_diagramsKey) ?? false,
      sectionColorBackground:
          _prefs.getBool(_sectionColorBackgroundKey) ?? false,
      instrumentPreferences: instrumentPreferences,
      chordNotationId: ChordNotationRegistry.resolve(
        _prefs.getString(_chordNotationKey),
      ).id,
    );
  }

  void setTranspose(int value) {
    if (state.transpose == value) return;
    state = state.copyWith(transpose: value);
    _persistScopedTransposition();
  }

  void setCapo(int value) {
    final clamped = value.clamp(0, 11);
    if (state.capo == clamped) return;
    state = state.copyWith(capo: clamped);
    _persistScopedTransposition();
  }

  void resetTransposition() {
    if (state.transpose == _directiveDefaults.transpose &&
        state.capo == _directiveDefaults.capo) {
      _persistScopedTransposition();
      return;
    }
    state = state.copyWith(
      transpose: _directiveDefaults.transpose,
      capo: _directiveDefaults.capo,
    );
    _persistScopedTransposition();
  }

  /// Seeds transposition defaults from document directives ({keyshift}, {capo}).
  void seedDirectiveDefaults({required int keyShift, required int capo}) {
    _directiveDefaults = (transpose: keyShift, capo: capo);
    if (_transpositionScopeKey != null) {
      final stored = _readScopedSongSettings(_transpositionScopeKey!);
      if (!stored.hasStored) {
        state = state.copyWith(transpose: keyShift, capo: capo);
      }
    } else {
      state = state.copyWith(transpose: keyShift, capo: capo);
    }
  }

  /// Enters a standalone song view.
  void enterSongStandalone({required String songId, SongAst? song}) {
    final key = 'standalone|$songId';
    if (_transpositionScopeKey == key) return;
    _transpositionScopeKey = key;
    if (song != null) {
      _directiveDefaults = (
        transpose: parseKeyShiftValue(song.metadata['keyShift']),
        capo: parseCapoValue(song.metadata['capo']),
      );
    }
    final stored = _readScopedSongSettings(key);
    state = state.copyWith(
      transpose: stored.hasStored
          ? stored.transpose
          : _directiveDefaults.transpose,
      capo: stored.hasStored ? stored.capo : _directiveDefaults.capo,
      variantId: stored.variantId,
    );
  }

  /// Loads the saved transpose/capo/variant for this service song (or defaults)
  /// and makes later changes persist under that pair.
  void enterServiceSong({
    required String serviceId,
    required String songId,
    SongAst? song,
  }) {
    final key = _scopeKey(serviceId, songId);
    if (_transpositionScopeKey == key) return;
    _transpositionScopeKey = key;
    if (song != null) {
      _directiveDefaults = (
        transpose: parseKeyShiftValue(song.metadata['keyShift']),
        capo: parseCapoValue(song.metadata['capo']),
      );
    }
    final stored = _readScopedSongSettings(key);
    state = state.copyWith(
      transpose: stored.hasStored
          ? stored.transpose
          : _directiveDefaults.transpose,
      capo: stored.hasStored ? stored.capo : _directiveDefaults.capo,
      variantId: stored.variantId,
    );
  }

  /// Clears the service-song scope and resets transpose/capo/variant.
  ///
  /// Call when leaving a [SongReader] (service or standalone) so the next song
  /// never inherits the previous one's transposition or variant.
  void leaveTranspositionScope() {
    _transpositionScopeKey = null;
    _directiveDefaults = (transpose: 0, capo: 0);
    if (state.transpose == 0 &&
        state.capo == 0 &&
        state.variantId == 'default') {
      return;
    }
    state = state.copyWith(transpose: 0, capo: 0, variantId: 'default');
  }

  static String _scopeKey(String serviceId, String songId) =>
      '$serviceId|$songId';

  ({bool hasStored, int transpose, int capo, String variantId})
  _readScopedSongSettings(String key) {
    final map = _loadTranspositionMap();
    final entry = map[key];
    if (entry is! Map) {
      return (
        hasStored: false,
        transpose: _directiveDefaults.transpose,
        capo: _directiveDefaults.capo,
        variantId: 'default',
      );
    }
    final transpose = (entry['t'] as num?)?.toInt() ?? 0;
    final capo = (entry['c'] as num?)?.toInt() ?? 0;
    final variantRaw = entry['v'];
    final variantId = variantRaw is String && variantRaw.isNotEmpty
        ? variantRaw
        : 'default';
    return (
      hasStored: true,
      transpose: transpose,
      capo: capo,
      variantId: variantId,
    );
  }

  void _persistScopedTransposition() {
    final key = _transpositionScopeKey;
    if (key == null) return;

    final map = _loadTranspositionMap();
    if (state.transpose == _directiveDefaults.transpose &&
        state.capo == _directiveDefaults.capo &&
        state.variantId == 'default') {
      map.remove(key);
    } else {
      map[key] = {
        't': state.transpose,
        'c': state.capo,
        if (state.variantId != 'default') 'v': state.variantId,
      };
    }
    _prefs.setString(_serviceTranspositionsKey, jsonEncode(map));
  }

  Map<String, dynamic> _loadTranspositionMap() {
    final raw = _prefs.getString(_serviceTranspositionsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Corrupt prefs — start fresh.
    }
    return {};
  }

  void setVariantId(String id, {int? transpose, int? capo}) {
    if (state.variantId == id) return;
    state = state.copyWith(
      variantId: id,
      transpose: transpose ?? _directiveDefaults.transpose,
      capo: capo ?? _directiveDefaults.capo,
    );
    _directiveDefaults = (
      transpose: transpose ?? _directiveDefaults.transpose,
      capo: capo ?? _directiveDefaults.capo,
    );
    _persistScopedTransposition();
  }

  void setChordNotation(String id) {
    final notation = ChordNotationRegistry.resolve(id);
    if (state.chordNotationId == notation.id) return;
    _prefs.setString(_chordNotationKey, notation.id);
    state = state.copyWith(chordNotationId: notation.id);
  }

  void toggleShowChords() {
    setShowChords(!state.showChords);
  }

  /// Sets chord visibility. When [persist] is false, only the in-memory
  /// session state changes (used to open non-musician song views lyrics-first).
  void setShowChords(bool value, {bool persist = true}) {
    if (persist) _prefs.setBool(_showChordsKey, value);
    state = state.copyWith(showChords: value);
  }

  /// Value stored in prefs, ignoring any temporary in-memory override.
  bool get persistedShowChords => _prefs.getBool(_showChordsKey) ?? true;

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
    final v = value
        .clamp(SongDisplaySettings.minFontSize, SongDisplaySettings.maxFontSize)
        .toDouble();
    _prefs.setDouble(_fontSizeKey, v);
    state = state.copyWith(fontSize: v);
  }

  void setInstrument(String value) {
    // Persist only ids the registry knows, so stale values can never leave the
    // UI showing an instrument that no longer exists.
    final id = instrumentRegistry.resolve(value).id;
    _prefs.setString(_instrumentKey, id);
    state = state.copyWith(instrument: id);
  }

  void toggleDiagrams() {
    setShowDiagrams(!state.showDiagrams);
  }

  void setShowDiagrams(bool value) {
    if (state.showDiagrams == value) return;
    _prefs.setBool(_diagramsKey, value);
    state = state.copyWith(showDiagrams: value);
  }

  void setAutoScrollSpeed(double value) {
    state = state.copyWith(autoScrollSpeed: value.clamp(1, 10).toDouble());
  }

  /// Updates preferences for a single instrument id and persists the map.
  void updateInstrumentPreference(
    String instrumentId,
    InstrumentPreference preference,
  ) {
    final id = instrumentRegistry.resolve(instrumentId).id;
    final next = state.instrumentPreferences.upsert(id, preference);
    _prefs.setString(_instrumentPreferencesKey, jsonEncode(next.toJson()));
    state = state.copyWith(instrumentPreferences: next);
  }
}

final songDisplaySettingsProvider =
    StateNotifierProvider<SongDisplaySettingsController, SongDisplaySettings>((
      ref,
    ) {
      return SongDisplaySettingsController(
        ref.watch(sharedPreferencesProvider),
      );
    });

/// Holds the [ChordProDocument] for the song that is currently on-screen.
///
/// Updated by [SongBodyRenderer] every time the content changes. The toolbar
/// reads this to build the variant switcher directly on the toolbar without prop-drilling.
final songCurrentDocumentProvider = StateProvider<ChordProDocument?>(
  (ref) => null,
);
