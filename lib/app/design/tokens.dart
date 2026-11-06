import 'package:flutter/material.dart';

/// Hosanna brand colors — aligned with Hosana-dashboard `src/index.css`.
///
/// Prefer [Theme.of] / [HosannaTokens.of] at call sites; these constants seed
/// the theme and ThemeExtension rather than being sprinkled in widgets.
abstract final class HosannaColors {
  // Primitive brand (dashboard --brand-*).
  static const Color primary = Color(0xFF0284C7); // brand-500
  static const Color primaryDark = Color(0xFF0369A1); // brand-600
  static const Color primaryBright = Color(0xFF38BDF8); // brand-400
  static const Color primaryContainer = Color(0xFFE0F2FE); // brand-100
  static const Color onPrimaryContainer = Color(0xFF0C4A6E);

  static const Color secondary = Color(0xFF5C6570); // m3-secondary (light)
  static const Color tertiary = Color(0xFF38BDF8);

  // Surfaces (dashboard --m3-*).
  static const Color canvasLight = Color(0xFFF4F6F8); // m3-bg
  static const Color sidebarLight = Color(0xFFEEF1F4); // m3-sidebar
  static const Color hoverLight = Color(0xFFE8ECF0); // m3-hover
  static const Color borderLight = Color(0xFFD0D7E0); // m3-border
  static const Color textLight = Color(0xFF1A1D24); // m3-text

  static const Color canvasDark = Color(0xFF0B0D12); // m3-bg dark
  static const Color sidebarDark = Color(0xFF12151C); // m3-sidebar dark
  static const Color hoverDark = Color(0xFF1F2330); // m3-hover dark
  static const Color borderDark = Color(0xFF2D3244); // m3-border dark
  static const Color textDark = Color(0xFFECEEF2); // m3-text dark
  static const Color secondaryDark = Color(0xFF9AA0B0);

  static const Color surfaceLight = Color(0xFFFFFFFF); // m3-card
  static const Color surfaceDark = Color(0xFF181B23); // m3-card dark

  // Dark primary accents.
  static const Color primaryOnDark = Color(0xFF5BABDB);
  static const Color primaryContainerDark = Color(0xFF0F2D40);
  static const Color primaryDarkOnDark = Color(0xFF3D8AB8);

  // Status (dashboard --success / --warning / --danger).
  static const Color success = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color successOnDark = Color(0xFF34D399);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningOnDark = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFE11D48);
  static const Color dangerContainer = Color(0xFFFFE4E6);
  static const Color dangerOnDark = Color(0xFFFB7185);
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

/// Corner radii — mobile-friendly mapping of dashboard `--radius-*`.
abstract final class HosannaRadii {
  static const double xs = 6; // radius-sm
  static const double sm = 10; // radius-md
  static const double md = 14; // radius-lg
  static const double lg = 20; // radius-xl
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  /// Matches auth/setup CTAs (16px).
  static const BorderRadius button = BorderRadius.all(Radius.circular(16));
  /// Matches auth/setup text fields (16px).
  static const BorderRadius field = BorderRadius.all(Radius.circular(16));
  static const BorderRadius navPill = BorderRadius.all(Radius.circular(pill));
}

/// Elevation / shadow helpers matching dashboard `--shadow-*`.
abstract final class HosannaElevation {
  static List<BoxShadow> card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : const Color(0xFF0F172A).withValues(alpha: 0.07),
        blurRadius: isDark ? 12 : 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0xFF0F172A).withValues(alpha: 0.1),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> softPrimary(Brightness brightness) {
    return [
      BoxShadow(
        color: HosannaColors.primary.withValues(
          alpha: brightness == Brightness.dark ? 0.35 : 0.18,
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
        cardBorder: HosannaColors.borderLight,
        selectedNav: HosannaColors.primaryContainer,
        selectedNavForeground: HosannaColors.onPrimaryContainer,
        subtleFill: HosannaColors.sidebarLight,
        aiGlow: HosannaColors.primary.withValues(alpha: 0.12),
      );

  static HosannaTokens dark() => HosannaTokens(
        canvas: HosannaColors.canvasDark,
        cardBorder: HosannaColors.borderDark,
        selectedNav: HosannaColors.primaryContainerDark,
        selectedNavForeground: HosannaColors.primaryOnDark,
        subtleFill: HosannaColors.sidebarDark,
        aiGlow: HosannaColors.primaryOnDark.withValues(alpha: 0.22),
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
