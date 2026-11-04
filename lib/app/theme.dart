import 'package:flutter/material.dart';

import 'design/tokens.dart';

/// Hosanna brand seed — sky accent from Hosana-dashboard (`--brand-500`).
const Color kHosannaSeedColor = HosannaColors.primary;

/// Theme selection mode.
enum AppThemeMode { system, light, dark }

/// Builds the four Hosanna [ThemeData] variants (light/dark × normal/high
/// contrast) using Material 3 + [HosannaTokens].
abstract final class HosannaTheme {
  static ColorScheme _scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: kHosannaSeedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: HosannaColors.primary,
        onPrimary: Colors.white,
        primaryContainer: HosannaColors.primaryContainer,
        onPrimaryContainer: HosannaColors.onPrimaryContainer,
        secondary: HosannaColors.secondary,
        onSecondary: Colors.white,
        tertiary: HosannaColors.tertiary,
        error: HosannaColors.danger,
        errorContainer: HosannaColors.dangerContainer,
        onSurface: HosannaColors.textLight,
        onSurfaceVariant: HosannaColors.secondary,
        surface: HosannaColors.surfaceLight,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: HosannaColors.sidebarLight,
        surfaceContainer: HosannaColors.sidebarLight,
        surfaceContainerHigh: HosannaColors.hoverLight,
        surfaceContainerHighest: HosannaColors.hoverLight,
        outline: HosannaColors.borderLight,
        outlineVariant: HosannaColors.borderLight.withValues(alpha: 0.7),
      );
    }
    return base.copyWith(
      primary: HosannaColors.primaryOnDark,
      onPrimary: HosannaColors.canvasDark,
      primaryContainer: HosannaColors.primaryContainerDark,
      onPrimaryContainer: HosannaColors.primaryOnDark,
      secondary: HosannaColors.secondaryDark,
      tertiary: HosannaColors.primaryBright,
      error: HosannaColors.dangerOnDark,
      onSurface: HosannaColors.textDark,
      onSurfaceVariant: HosannaColors.secondaryDark,
      surface: HosannaColors.surfaceDark,
      surfaceContainerLowest: HosannaColors.canvasDark,
      surfaceContainerLow: HosannaColors.sidebarDark,
      surfaceContainer: HosannaColors.sidebarDark,
      surfaceContainerHigh: HosannaColors.hoverDark,
      surfaceContainerHighest: HosannaColors.hoverDark,
      outline: HosannaColors.borderDark,
      outlineVariant: HosannaColors.borderDark.withValues(alpha: 0.7),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required HosannaTokens tokens,
  }) {
    final baseTypography = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: scheme,
    );
    final textTheme = (brightness == Brightness.dark
            ? baseTypography.white
            : baseTypography.black)
        .apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final shapeMd = RoundedRectangleBorder(borderRadius: HosannaRadii.card);
    final shapeSm = RoundedRectangleBorder(borderRadius: HosannaRadii.button);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.canvas,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [tokens],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: tokens.canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: shapeMd,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HosannaSpacing.md,
          vertical: HosannaSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: HosannaRadii.field,
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: HosannaRadii.field,
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HosannaRadii.field,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HosannaRadii.field,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: HosannaSpacing.lg,
            vertical: HosannaSpacing.sm + 2,
          ),
          shape: shapeSm,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: HosannaSpacing.lg,
            vertical: HosannaSpacing.sm + 2,
          ),
          shape: shapeSm,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: HosannaSpacing.lg,
            vertical: HosannaSpacing.sm + 2,
          ),
          shape: shapeSm,
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: shapeSm,
          foregroundColor: scheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HosannaRadii.pill),
        ),
        side: BorderSide(color: tokens.cardBorder),
        selectedColor: scheme.primaryContainer,
        backgroundColor: tokens.subtleFill,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(borderRadius: HosannaRadii.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(HosannaRadii.lg),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: shapeMd,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HosannaSpacing.md,
          vertical: HosannaSpacing.xxs,
        ),
        iconColor: scheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shapeSm,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: shapeMd,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
    );
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: _scheme(Brightness.light),
        tokens: HosannaTokens.light(),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: _scheme(Brightness.dark),
        tokens: HosannaTokens.dark(),
      );

  static ThemeData highContrastLight() {
    final base = light();
    return base.copyWith(
      colorScheme: ColorScheme.highContrastLight(
        primary: HosannaColors.primaryDark,
      ),
    );
  }

  static ThemeData highContrastDark() {
    final base = dark();
    return base.copyWith(
      colorScheme: ColorScheme.highContrastDark(
        primary: HosannaColors.primaryBright,
      ),
    );
  }

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
