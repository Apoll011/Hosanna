# Theme — Hosanna (Flutter Material 3)

## Compact token summary

| Token | Value |
|-------|--------|
| Framework | Flutter Material 3 (`useMaterial3: true`) |
| Brand seed | `#0284C7` (`kHosannaSeedColor`) — sky blue; comment notes React `--color-m3-primary` |
| Color scheme | `ColorScheme.fromSeed(seedColor: #0284C7, brightness: light\|dark)` |
| High contrast | `ColorScheme.highContrastLight()` / `highContrastDark()` |
| Typography | Default M3 TextTheme (no custom fontFamily) |
| Density | `VisualDensity.adaptivePlatformDensity` |
| Theme modes | system (default), light, dark + optional highContrast |
| Tablet breakpoint | `750` logical px (`kTabletBreakpoint`) |
| Floating nav | height 64, radius 42, `surfaceContainer`, shadow blur 20 / offset (0,6) / black 18% |
| Sidebar widths | collapsed 76 / expanded 288, `surfaceContainerLow` |
| Nav anim | 250ms `easeOutCubic` |
| Shell bottom clearance | 64 + 12 + 16 = 92 + safe inset |

### Derived M3 roles (from seed — approximate light)

Primary / onPrimary / primaryContainer come from seed `#0284C7`. Surfaces use M3 surface / surfaceContainer* / onSurface / onSurfaceVariant. Error uses M3 error roles.

### Feature-local accents (not global theme)

- Annotation: `#E53935` `#FB8C00` `#FDD835` `#43A047` `#1E88E5` `#8E24AA` white/black
- Service done: `#16A34A` `#4ADE80`
- Chord accents: `#10B981` `#B45309` + slate/amber blocks

## Raw source — `lib/app/theme.dart`

```dart
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

```
