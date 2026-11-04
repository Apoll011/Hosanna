import 'package:flutter/material.dart';

/// Hosanna 2.0 brand colors — soft lavender / purple accent.
///
/// Prefer [Theme.of] / [HosannaTokens.of] at call sites; these constants seed
/// the theme and ThemeExtension rather than being sprinkled in widgets.
abstract final class HosannaColors {
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryDark = Color(0xFF5438E0);
  static const Color primaryContainer = Color(0xFFEDE8FF);
  static const Color onPrimaryContainer = Color(0xFF2A1866);

  static const Color secondary = Color(0xFF7C6FA8);
  static const Color tertiary = Color(0xFF9B6BFF);

  static const Color canvasLight = Color(0xFFF7F5FC);
  static const Color canvasDark = Color(0xFF14121C);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1B28);

  static const Color success = Color(0xFF2E9E6A);
  static const Color successContainer = Color(0xFFD9F5E8);
}

/// Spacing scale (logical pixels).
abstract final class HosannaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Corner radii.
abstract final class HosannaRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius field = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius navPill = BorderRadius.all(Radius.circular(pill));
}

/// Elevation / shadow helpers matching the soft lavender look.
abstract final class HosannaElevation {
  static List<BoxShadow> card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> softPrimary(Brightness brightness) {
    return [
      BoxShadow(
        color: HosannaColors.primary.withValues(
          alpha: brightness == Brightness.dark ? 0.35 : 0.22,
        ),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

/// Custom theme tokens beyond [ColorScheme].
@immutable
class HosannaTokens extends ThemeExtension<HosannaTokens> {
  const HosannaTokens({
    required this.canvas,
    required this.cardBorder,
    required this.selectedNav,
    required this.selectedNavForeground,
    required this.subtleFill,
    required this.aiGlow,
  });

  final Color canvas;
  final Color cardBorder;
  final Color selectedNav;
  final Color selectedNavForeground;
  final Color subtleFill;
  final Color aiGlow;

  static HosannaTokens light() => HosannaTokens(
        canvas: HosannaColors.canvasLight,
        cardBorder: const Color(0xFFE6E0F5),
        selectedNav: HosannaColors.primaryContainer,
        selectedNavForeground: HosannaColors.onPrimaryContainer,
        subtleFill: const Color(0xFFF0ECFA),
        aiGlow: HosannaColors.primary.withValues(alpha: 0.12),
      );

  static HosannaTokens dark() => HosannaTokens(
        canvas: HosannaColors.canvasDark,
        cardBorder: const Color(0xFF3A3450),
        selectedNav: const Color(0xFF3A2A6E),
        selectedNavForeground: const Color(0xFFEDE8FF),
        subtleFill: const Color(0xFF2A2638),
        aiGlow: HosannaColors.primary.withValues(alpha: 0.22),
      );

  static HosannaTokens of(BuildContext context) {
    return Theme.of(context).extension<HosannaTokens>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? HosannaTokens.dark()
            : HosannaTokens.light());
  }

  @override
  HosannaTokens copyWith({
    Color? canvas,
    Color? cardBorder,
    Color? selectedNav,
    Color? selectedNavForeground,
    Color? subtleFill,
    Color? aiGlow,
  }) {
    return HosannaTokens(
      canvas: canvas ?? this.canvas,
      cardBorder: cardBorder ?? this.cardBorder,
      selectedNav: selectedNav ?? this.selectedNav,
      selectedNavForeground:
          selectedNavForeground ?? this.selectedNavForeground,
      subtleFill: subtleFill ?? this.subtleFill,
      aiGlow: aiGlow ?? this.aiGlow,
    );
  }

  @override
  HosannaTokens lerp(ThemeExtension<HosannaTokens>? other, double t) {
    if (other is! HosannaTokens) return this;
    return HosannaTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      selectedNav: Color.lerp(selectedNav, other.selectedNav, t)!,
      selectedNavForeground:
          Color.lerp(selectedNavForeground, other.selectedNavForeground, t)!,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
      aiGlow: Color.lerp(aiGlow, other.aiGlow, t)!,
    );
  }
}
