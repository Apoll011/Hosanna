import 'package:flutter/material.dart';

import '../../domain/chordpro/diagnostics.dart';
import '../../domain/chordpro/highlight.dart';
import 'chordpro_syntax_theme.dart';

/// Monospace [TextEditingController] that paints ChordPro syntax colors and
/// diagnostic underlines.
class ChordProSyntaxController extends TextEditingController {
  ChordProSyntaxController({super.text});

  ChordProSyntaxTheme? _theme;
  List<ChordProDiagnostic> _diagnostics = const [];
  TextStyle? _baseStyle;

  void updateHighlighting({
    required ChordProSyntaxTheme theme,
    required TextStyle baseStyle,
    List<ChordProDiagnostic> diagnostics = const [],
  }) {
    final sameTheme = identical(_theme, theme) ||
        (_theme != null &&
            _theme!.base == theme.base &&
            _theme!.chord == theme.chord);
    final sameStyle = _baseStyle == baseStyle;
    final sameDiags = _sameDiagnostics(_diagnostics, diagnostics);
    if (sameTheme && sameStyle && sameDiags) return;
    _theme = theme;
    _baseStyle = baseStyle;
    _diagnostics = List.unmodifiable(diagnostics);
    notifyListeners();
  }

  static bool _sameDiagnostics(
    List<ChordProDiagnostic> a,
    List<ChordProDiagnostic> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].offset != b[i].offset ||
          a[i].length != b[i].length ||
          a[i].severity != b[i].severity) {
        return false;
      }
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = _theme ?? ChordProSyntaxTheme.fromScheme(
      Theme.of(context).colorScheme,
    );
    final base = (_baseStyle ?? style ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      height: 1.45,
    );

    final source = text;
    if (source.isEmpty) {
      return TextSpan(style: base, text: '');
    }

    final tokens = tokenizeChordPro(source);
    final underlines = _underlineColors(source.length);

    final children = <InlineSpan>[];
    for (final token in tokens) {
      if (token.length <= 0) continue;
      final tokenStyle = theme.styleFor(token.type, base);

      var cursor = token.start;
      while (cursor < token.end) {
        final underline = underlines[cursor];
        var runEnd = cursor + 1;
        while (runEnd < token.end && underlines[runEnd] == underline) {
          runEnd++;
        }
        final runStyle = underline == null
            ? tokenStyle
            : tokenStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: underline,
                decorationStyle: TextDecorationStyle.wavy,
                decorationThickness: 1.4,
              );
        children.add(
          TextSpan(
            text: source.substring(cursor, runEnd),
            style: runStyle,
          ),
        );
        cursor = runEnd;
      }
    }

    if (withComposing && value.isComposingRangeValid) {
      // Rebuild with composing underline — rare IME path; fall back to plain.
      return TextSpan(style: base, text: source);
    }

    return TextSpan(style: base, children: children);
  }

  List<Color?> _underlineColors(int length) {
    final map = List<Color?>.filled(length, null);
    final theme = _theme;
    if (theme == null || length == 0) return map;

    for (final d in _diagnostics) {
      if (d.offset < 0 || d.length <= 0 || d.line <= 0) continue;
      final color = switch (d.severity) {
        ChordProSeverity.error => theme.errorUnderline,
        ChordProSeverity.warning => theme.warningUnderline,
        ChordProSeverity.info => null,
      };
      if (color == null) continue;
      final start = d.offset.clamp(0, length);
      final end = (d.offset + d.length).clamp(0, length);
      for (var i = start; i < end; i++) {
        if (map[i] != theme.errorUnderline) map[i] = color;
      }
    }
    return map;
  }
}
