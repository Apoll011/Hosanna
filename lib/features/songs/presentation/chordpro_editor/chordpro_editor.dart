import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/chordpro/diagnostics.dart';
import 'chordpro_syntax_controller.dart';
import 'chordpro_syntax_theme.dart';

typedef ChordProComposeContent = String Function();

/// ChordPro source editor with syntax highlighting, line numbers, live
/// diagnostics, and quick-insert chips for common directives.
class ChordProEditor extends StatefulWidget {
  const ChordProEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.diagnostics,
    required this.onLintRequested,
    this.hintText,
  });

  final ChordProSyntaxController controller;
  final FocusNode focusNode;
  final List<ChordProDiagnostic> diagnostics;
  final VoidCallback onLintRequested;
  final String? hintText;

  @override
  State<ChordProEditor> createState() => _ChordProEditorState();
}

class _ChordProEditorState extends State<ChordProEditor> {
  final _scrollController = ScrollController();
  Timer? _lintDebounce;
  int? _selectedDiagnosticIndex;
  double _editorWidth = 0;

  static const _fontSize = 14.5;
  static const _lineHeight = 1.45;
  static const _padTop = 12.0;
  static const _padLeft = 4.0;
  static const _padRight = 14.0;
  static const _padBottom = 16.0;

  double get _lineExtent => _fontSize * _lineHeight;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLintRequested();
    });
  }

  @override
  void didUpdateWidget(covariant ChordProEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    _syncHighlighting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHighlighting();
  }

  void _syncHighlighting() {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      fontSize: _fontSize,
      height: _lineHeight,
    );
    widget.controller.updateHighlighting(
      theme: ChordProSyntaxTheme.fromScheme(theme.colorScheme),
      baseStyle: baseStyle,
      diagnostics: widget.diagnostics,
    );
  }

  @override
  void dispose() {
    _lintDebounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    _lintDebounce?.cancel();
    _lintDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) widget.onLintRequested();
    });
    // Keep gutter line count / wrap heights in sync while typing.
    if (mounted) setState(() {});
  }

  int get _lineCount {
    final text = widget.controller.text;
    if (text.isEmpty) return 1;
    return '\n'.allMatches(text).length + 1;
  }

  TextStyle _baseStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontFamily: 'monospace',
          fontSize: _fontSize,
          height: _lineHeight,
        );
  }

  /// Visual height of each logical line after soft-wrapping to [maxWidth].
  List<double> _wrappedLineHeights(TextStyle style, double maxWidth) {
    final text = widget.controller.text;
    final lines = text.isEmpty ? const [''] : text.split('\n');
    final width = math.max(1.0, maxWidth);
    final heights = <double>[];
    for (final line in lines) {
      final tp = TextPainter(
        text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
        textDirection: ui.TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      heights.add(math.max(tp.height, _lineExtent));
    }
    return heights;
  }

  double _offsetForLine(List<double> heights, int line) {
    var y = 0.0;
    final last = math.min(line - 1, heights.length);
    for (var i = 0; i < last; i++) {
      y += heights[i];
    }
    return y;
  }

  void _jumpToDiagnostic(ChordProDiagnostic d) {
    if (d.offset < 0 || d.line <= 0) return;
    final text = widget.controller.text;
    final offset = d.offset.clamp(0, text.length).toInt();
    final end = (d.offset + math.max(d.length, 0)).clamp(0, text.length).toInt();
    widget.controller.selection = TextSelection(
      baseOffset: offset,
      extentOffset: end,
    );
    widget.focusNode.requestFocus();

    final style = _baseStyle(context);
    final heights = _wrappedLineHeights(
      style,
      math.max(1.0, _editorWidth - _padLeft - _padRight),
    );
    final targetY = _padTop + _offsetForLine(heights, d.line);
    final view = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 0.0;
    final jump = math.max(0.0, targetY - view * 0.3);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        jump.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _insertSnippet(String snippet, {int cursorOffset = 0}) {
    final value = widget.controller.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : start;
    final text = value.text;
    final next = text.replaceRange(start, end, snippet);
    final caret = start + (cursorOffset <= 0 ? snippet.length : cursorOffset);
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret.clamp(0, next.length)),
    );
    widget.focusNode.requestFocus();
    widget.onLintRequested();
  }

  void _wrapSelection(String left, String right) {
    final value = widget.controller.value;
    final sel = value.selection;
    if (!sel.isValid) {
      _insertSnippet('$left$right', cursorOffset: left.length);
      return;
    }
    final selected = sel.textInside(value.text);
    final replacement = '$left$selected$right';
    final next = value.text.replaceRange(sel.start, sel.end, replacement);
    final caret = sel.start + left.length + selected.length;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    widget.focusNode.requestFocus();
    widget.onLintRequested();
  }

  void _insertSection(String type) {
    final open = '{start_of_$type}\n';
    final close = '\n{end_of_$type}\n';
    _insertSnippet('$open$close', cursorOffset: open.length);
  }

  String _localizeDiagnostic(AppLocalizations l10n, ChordProDiagnostic d) {
    switch (d.code) {
      case ChordProDiagnosticCode.parserError:
        return d.args['detail'] ?? d.message;
      case ChordProDiagnosticCode.unclosedBrace:
        return l10n.songsLintUnclosedBrace;
      case ChordProDiagnosticCode.unclosedBracket:
        return l10n.songsLintUnclosedBracket;
      case ChordProDiagnosticCode.emptyChord:
        return l10n.songsLintEmptyChord;
      case ChordProDiagnosticCode.unknownChord:
        return l10n.songsLintUnknownChord(d.args['chord'] ?? '');
      case ChordProDiagnosticCode.malformedDirective:
        final name = d.args['name'];
        if (name != null && name.isNotEmpty) {
          return l10n.songsLintUnknownDirective(name);
        }
        return l10n.songsLintMalformedDirective;
      case ChordProDiagnosticCode.unclosedSection:
        return l10n.songsLintUnclosedSection(d.args['section'] ?? '');
      case ChordProDiagnosticCode.unexpectedEndSection:
        return l10n.songsLintUnexpectedEndSection(d.args['section'] ?? '');
      case ChordProDiagnosticCode.invalidYoutube:
        return l10n.songsLintInvalidYoutube;
      case ChordProDiagnosticCode.invalidKey:
        return l10n.songsLintInvalidKey(d.args['value'] ?? '');
      case ChordProDiagnosticCode.invalidTempo:
        return l10n.songsLintInvalidTempo;
      case ChordProDiagnosticCode.invalidCapo:
        return l10n.songsLintInvalidCapo;
      case ChordProDiagnosticCode.invalidTimeSignature:
        return l10n.songsLintInvalidTime;
      case ChordProDiagnosticCode.invalidDuration:
        return l10n.songsLintInvalidDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final syntaxTheme = ChordProSyntaxTheme.fromScheme(scheme);
    final baseStyle = _baseStyle(context);

    final errors = countDiagnosticsBySeverity(
      widget.diagnostics,
      ChordProSeverity.error,
    );
    final warnings = countDiagnosticsBySeverity(
      widget.diagnostics,
      ChordProSeverity.warning,
    );
    final infos = countDiagnosticsBySeverity(
      widget.diagnostics,
      ChordProSeverity.info,
    );

    final gutterWidth = 12.0 +
        (math.max(2, _lineCount.toString().length) * (_fontSize * 0.62));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InsertToolbar(
          onVerse: () => _insertSection('verse'),
          onChorus: () => _insertSection('chorus'),
          onBridge: () => _insertSection('bridge'),
          onComment: () => _insertSnippet('{c: }', cursorOffset: 4),
          onChord: () => _wrapSelection('[', ']'),
          onVersion: () => _insertSnippet(
            '{start_of_version: }\n\n{end_of_version}\n',
            cursorOffset: 19,
          ),
          onTab: () => _insertSection('tab'),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textWidth = math.max(
                    1.0,
                    constraints.maxWidth - gutterWidth - 1 - _padLeft - _padRight,
                  );
                  if ((textWidth - _editorWidth).abs() > 0.5) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _editorWidth = textWidth);
                    });
                  }
                  final lineHeights = _wrappedLineHeights(baseStyle, textWidth);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: gutterWidth,
                        child: ColoredBox(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _scrollController,
                              widget.controller,
                            ]),
                            builder: (context, _) {
                              final scroll = _scrollController.hasClients
                                  ? _scrollController.offset
                                  : 0.0;
                              final diagLines = {
                                for (final d in widget.diagnostics)
                                  if (d.line > 0) d.line: d.severity,
                              };
                              return CustomPaint(
                                painter: _GutterPainter(
                                  lineHeights: lineHeights,
                                  scrollOffset: scroll,
                                  padTop: _padTop,
                                  textStyle: baseStyle.copyWith(
                                    fontSize: _fontSize * 0.85,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                    height: 1,
                                  ),
                                  errorColor: scheme.error,
                                  warningColor: syntaxTheme.warningUnderline,
                                  diagLines: diagLines,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          scrollController: _scrollController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          style: baseStyle,
                          cursorColor: scheme.primary,
                          scrollPadding: EdgeInsets.zero,
                          decoration: InputDecoration(
                            isCollapsed: false,
                            filled: false,
                            hintText: widget.hintText ?? l10n.songsChordProHint,
                            hintStyle: baseStyle.copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.45),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              _padLeft + 8,
                              _padTop,
                              _padRight,
                              _padBottom,
                            ),
                          ),
                          inputFormatters: const [_ChordProTabFormatter()],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _DiagnosticsBar(
          l10n: l10n,
          diagnostics: widget.diagnostics,
          errors: errors,
          warnings: warnings,
          infos: infos,
          selectedIndex: _selectedDiagnosticIndex,
          localize: (d) => _localizeDiagnostic(l10n, d),
          onSelect: (index, d) {
            setState(() => _selectedDiagnosticIndex = index);
            _jumpToDiagnostic(d);
          },
        ),
      ],
    );
  }
}

class _InsertToolbar extends StatelessWidget {
  const _InsertToolbar({
    required this.onVerse,
    required this.onChorus,
    required this.onBridge,
    required this.onComment,
    required this.onChord,
    required this.onVersion,
    required this.onTab,
  });

  final VoidCallback onVerse;
  final VoidCallback onChorus;
  final VoidCallback onBridge;
  final VoidCallback onComment;
  final VoidCallback onChord;
  final VoidCallback onVersion;
  final VoidCallback onTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              icon: Icons.music_note_outlined,
              label: l10n.songsEditorInsertVerse,
              onPressed: onVerse,
            ),
            _Chip(
              icon: Icons.repeat_rounded,
              label: l10n.songsEditorInsertChorus,
              onPressed: onChorus,
            ),
            _Chip(
              icon: Icons.alt_route_rounded,
              label: l10n.songsEditorInsertBridge,
              onPressed: onBridge,
            ),
            _Chip(
              icon: Icons.grid_on_outlined,
              label: 'Tab',
              onPressed: onTab,
            ),
            _Chip(
              icon: Icons.tag_outlined,
              label: '[ ]',
              onPressed: onChord,
            ),
            _Chip(
              icon: Icons.comment_outlined,
              label: l10n.songsEditorInsertComment,
              onPressed: onComment,
            ),
            _Chip(
              icon: Icons.library_music_outlined,
              label: l10n.songsEditorInsertVersion,
              onPressed: onVersion,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelMedium,
        onPressed: onPressed,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        backgroundColor: scheme.surface,
      ),
    );
  }
}

class _DiagnosticsBar extends StatelessWidget {
  const _DiagnosticsBar({
    required this.l10n,
    required this.diagnostics,
    required this.errors,
    required this.warnings,
    required this.infos,
    required this.selectedIndex,
    required this.localize,
    required this.onSelect,
  });

  final AppLocalizations l10n;
  final List<ChordProDiagnostic> diagnostics;
  final int errors;
  final int warnings;
  final int infos;
  final int? selectedIndex;
  final String Function(ChordProDiagnostic) localize;
  final void Function(int index, ChordProDiagnostic d) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (diagnostics.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.songsLintAllClear,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 132),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errors > 0
              ? scheme.error.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(
                  errors > 0
                      ? Icons.error_outline
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: errors > 0 ? scheme.error : scheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.songsLintSummary(errors, warnings, infos),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: diagnostics.length,
              itemBuilder: (context, index) {
                final d = diagnostics[index];
                final selected = selectedIndex == index;
                final color = switch (d.severity) {
                  ChordProSeverity.error => scheme.error,
                  ChordProSeverity.warning => const Color(0xFFD97706),
                  ChordProSeverity.info => scheme.onSurfaceVariant,
                };
                final lineLabel = d.line > 0
                    ? l10n.songsLintLine(d.line)
                    : l10n.songsLintDetails;
                return InkWell(
                  onTap: () => onSelect(index, d),
                  child: ColoredBox(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            switch (d.severity) {
                              ChordProSeverity.error => Icons.error_rounded,
                              ChordProSeverity.warning =>
                                Icons.warning_rounded,
                              ChordProSeverity.info => Icons.info_outline,
                            },
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 52,
                            child: Text(
                              lineLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              localize(d),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.lineHeights,
    required this.scrollOffset,
    required this.padTop,
    required this.textStyle,
    required this.errorColor,
    required this.warningColor,
    required this.diagLines,
  });

  final List<double> lineHeights;
  final double scrollOffset;
  final double padTop;
  final TextStyle textStyle;
  final Color errorColor;
  final Color warningColor;
  final Map<int, ChordProSeverity> diagLines;

  @override
  void paint(Canvas canvas, Size size) {
    var y = padTop - scrollOffset;
    for (var i = 0; i < lineHeights.length; i++) {
      final extent = lineHeights[i];
      final line = i + 1;
      if (y + extent < 0) {
        y += extent;
        continue;
      }
      if (y > size.height) break;

      final severity = diagLines[line];
      if (severity == ChordProSeverity.error ||
          severity == ChordProSeverity.warning) {
        final paint = Paint()
          ..color = (severity == ChordProSeverity.error
                  ? errorColor
                  : warningColor)
              .withValues(alpha: 0.18);
        canvas.drawRect(
          Rect.fromLTWH(0, y - 1, size.width, extent),
          paint,
        );
      }

      final tp = TextPainter(
        text: TextSpan(text: '$line', style: textStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(minWidth: size.width - 8, maxWidth: size.width - 8);
      tp.paint(
        canvas,
        Offset(4, y + (math.min(extent, textStyle.fontSize! * 1.45) - tp.height) / 2),
      );
      y += extent;
    }
  }

  @override
  bool shouldRepaint(covariant _GutterPainter old) {
    if (old.scrollOffset != scrollOffset ||
        old.diagLines.length != diagLines.length ||
        old.lineHeights.length != lineHeights.length) {
      return true;
    }
    for (var i = 0; i < lineHeights.length; i++) {
      if (old.lineHeights[i] != lineHeights[i]) return true;
    }
    return false;
  }
}

/// Converts Tab key presses into two spaces (ChordPro indentation).
class _ChordProTabFormatter extends TextInputFormatter {
  const _ChordProTabFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains('\t')) return newValue;
    final replaced = newValue.text.replaceAll('\t', '  ');
    final delta = replaced.length - newValue.text.length;
    final sel = newValue.selection;
    return TextEditingValue(
      text: replaced,
      selection: sel.isValid
          ? TextSelection.collapsed(
              offset: (sel.baseOffset + delta).clamp(0, replaced.length),
            )
          : sel,
    );
  }
}
