import 'package:flutter/material.dart';

/// Hosanna brand seed color, inferred from the React app's
/// `--color-m3-primary: #0284c7` (sky blue). Placeholder for brand review.
const Color kHosannaSeedColor = Color(0xFF0284C7);

/// Theme selection mode.
enum AppThemeMode { system, light, dark }

/// Builds the four Hosanna [ThemeData] variants (light/dark × normal/high
/// contrast) using Material 3.
abstract final class HosannaTheme {
  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kHosannaSeedColor,
        brightness: brightness,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// High-contrast variants use Flutter's built-in M3 high-contrast schemes
  /// ([ColorScheme.highContrastLight] / [ColorScheme.highContrastDark]).
  static ThemeData _highContrastBase(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: brightness == Brightness.light
          ? const ColorScheme.highContrastLight()
          : const ColorScheme.highContrastDark(),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData highContrastLight() => _highContrastBase(Brightness.light);

  static ThemeData highContrastDark() => _highContrastBase(Brightness.dark);

  /// Resolves the active theme for a given [mode], platform brightness and
  /// high-contrast preference.
  static ThemeData resolve({
    required AppThemeMode mode,
    required Brightness platformBrightness,
    required bool highContrast,
  }) {
    final isDark = switch (mode) {
      AppThemeMode.system => platformBrightness == Brightness.dark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
    };
    return switch ((isDark, highContrast)) {
      (false, false) => light(),
      (true, false) => dark(),
      (false, true) => highContrastLight(),
      (true, true) => highContrastDark(),
    };
  }
}
