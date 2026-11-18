import 'package:flutter/material.dart';

/// Theme-derived colors shared by every chord diagram.
class DiagramColors {
  const DiagramColors({
    required this.primary,
    required this.line,
    required this.text,
    required this.white,
    required this.black,
    required this.open,
    required this.mute,
    required this.capo,
  });

  final Color primary;
  final Color line;
  final Color text;
  final Color white;
  final Color black;
  final Color open;
  final Color mute;
  final Color capo;

  static DiagramColors of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DiagramColors(
      primary: theme.colorScheme.primary,
      line: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
      text: theme.colorScheme.onSurface,
      white: isDark ? const Color(0xFF27272A) : Colors.white,
      black: isDark ? const Color(0xFF09090B) : const Color(0xFF27272A),
      open: const Color(0xFF10B981),
      mute: theme.colorScheme.error,
      capo: const Color(0xFFB45309),
    );
  }
}
