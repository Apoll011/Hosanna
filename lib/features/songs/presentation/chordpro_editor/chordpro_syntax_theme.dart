import 'package:flutter/material.dart';

import '../../domain/chordpro/highlight.dart';

/// Colors for ChordPro token types, derived from the ambient [ColorScheme].
@immutable
class ChordProSyntaxTheme {
  const ChordProSyntaxTheme({
    required this.base,
    required this.comment,
    required this.directiveBrace,
    required this.directiveName,
    required this.directiveValue,
    required this.sectionDirective,
    required this.chordBrace,
    required this.chord,
    required this.barline,
    required this.errorUnderline,
    required this.warningUnderline,
  });

  factory ChordProSyntaxTheme.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ChordProSyntaxTheme(
      base: scheme.onSurface,
      comment: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      directiveBrace: scheme.tertiary,
      directiveName: isDark
          ? const Color(0xFF7DD3FC)
          : const Color(0xFF0369A1),
      directiveValue: scheme.onSurface.withValues(alpha: 0.85),
      sectionDirective: isDark
          ? const Color(0xFF5EEAD4)
          : const Color(0xFF0F766E),
      chordBrace: isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFB45309),
      chord: isDark
          ? const Color(0xFFFCD34D)
          : const Color(0xFFC2410C),
      barline: scheme.outline.withValues(alpha: 0.85),
      errorUnderline: scheme.error,
      warningUnderline: isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFD97706),
    );
  }

  final Color base;
  final Color comment;
  final Color directiveBrace;
  final Color directiveName;
  final Color directiveValue;
  final Color sectionDirective;
  final Color chordBrace;
  final Color chord;
  final Color barline;
  final Color errorUnderline;
  final Color warningUnderline;

  TextStyle styleFor(ChordProTokenType type, TextStyle baseStyle) {
    Color color;
    FontWeight? weight;
    FontStyle? fontStyle;
    switch (type) {
      case ChordProTokenType.text:
        color = base;
      case ChordProTokenType.comment:
        color = comment;
        fontStyle = FontStyle.italic;
      case ChordProTokenType.directiveBrace:
        color = directiveBrace;
      case ChordProTokenType.directiveName:
        color = directiveName;
        weight = FontWeight.w600;
      case ChordProTokenType.directiveColon:
        color = directiveBrace;
      case ChordProTokenType.directiveValue:
        color = directiveValue;
      case ChordProTokenType.sectionDirective:
        color = sectionDirective;
        weight = FontWeight.w700;
      case ChordProTokenType.chordBrace:
        color = chordBrace;
        weight = FontWeight.w600;
      case ChordProTokenType.chord:
        color = chord;
        weight = FontWeight.w700;
      case ChordProTokenType.barline:
        color = barline;
        weight = FontWeight.w600;
    }
    return baseStyle.copyWith(
      color: color,
      fontWeight: weight,
      fontStyle: fontStyle,
    );
  }
}
