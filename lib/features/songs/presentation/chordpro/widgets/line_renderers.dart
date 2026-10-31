import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import 'render_model.dart';

/// Display options shared by every line in a song.
class LineRenderOptions {
  const LineRenderOptions({
    required this.showChords,
    required this.fontSize,
    required this.onChordTap,
  });

  final bool showChords;

  /// Effective lyric font size; chord and grid sizes scale from it.
  final double fontSize;

  final void Function(String chord) onChordTap;

  double get chordFontSize => fontSize * 0.85;
}

class LineRenderer extends StatelessWidget {
  const LineRenderer({super.key, required this.line, required this.options});

  final PreparedLine line;
  final LineRenderOptions options;

  @override
  Widget build(BuildContext context) {
    final text = line.line.text ?? '';
    return switch (line.type) {
      'empty' => SizedBox(height: options.fontSize * 0.6),
      'comment' => CommentLine(text: text),
      'comment_italic' => CommentItalicLine(text: text),
      'comment_box' => CommentBoxLine(text: text),
      'key_note' => KeyNoteLine(text: text),
      'chord-section' => ChordSectionLine(line: line, options: options),
      _ => LyricsLine(line: line, options: options),
    };
  }
}

/// Plain inline comment (`{c: ...}`): quiet, upright note text.
class CommentLine extends StatelessWidget {
  const CommentLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.notes,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emphasised italic comment (`{ci: ...}`): centred and set apart.
class CommentItalicLine extends StatelessWidget {
  const CommentItalicLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class CommentBoxLine extends StatelessWidget {
  const CommentBoxLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        border: Border(left: BorderSide(color: scheme.tertiary, width: 4)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.onTertiaryContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyNoteLine extends StatelessWidget {
  const KeyNoteLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable chord symbol with a ripple and a screen-reader label.
class ChordLabel extends StatelessWidget {
  const ChordLabel({
    super.key,
    required this.chord,
    required this.style,
    required this.onTap,
    this.trailingGap = 0,
  });

  final String chord;
  final TextStyle style;
  final void Function(String chord) onTap;

  /// Extra space after the symbol so adjacent chords like `[Em][C]` never
  /// render as `EmC`.
  final double trailingGap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.songChordSemantics(chord),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(chord),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.only(right: trailingGap),
          child: Text(chord, style: style),
        ),
      ),
    );
  }
}

class LyricsLine extends StatelessWidget {
  const LyricsLine({super.key, required this.line, required this.options});

  final PreparedLine line;
  final LineRenderOptions options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = line.tokens;
    final showChords = options.showChords;
    final chordFontSize = options.chordFontSize;
    final chordStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w800,
      fontSize: chordFontSize,
      height: 1.2,
    );
    const lyricStyle = TextStyle(height: 1.3);
    final chordGap = chordFontSize * 0.45;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (var i = 0; i < tokens.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showChords)
                  if (tokens[i].chord.isNotEmpty)
                    ChordLabel(
                      chord: tokens[i].chord,
                      style: chordStyle,
                      onTap: options.onChordTap,
                      trailingGap:
                          i + 1 < tokens.length &&
                              tokens[i + 1].chord.isNotEmpty
                          ? chordGap
                          : 0,
                    )
                  else
                    SizedBox(height: chordFontSize * 1.2),
                Text(
                  tokens[i].text.isEmpty ? '\u00A0' : tokens[i].text,
                  style: lyricStyle,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ChordSectionLine extends StatelessWidget {
  const ChordSectionLine({
    super.key,
    required this.line,
    required this.options,
  });

  final PreparedLine line;
  final LineRenderOptions options;

  @override
  Widget build(BuildContext context) {
    if (!options.showChords) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final chordStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w700,
      fontSize: options.fontSize * 1.05,
    );
    final startBarline = line.line.startBarline;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (startBarline != null && startBarline.isNotEmpty)
            Barline(barline: startBarline, fontSize: options.fontSize),
          for (final measure in line.measures) ...[
            for (final chord in measure.chords)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChordLabel(
                  chord: chord,
                  style: chordStyle,
                  onTap: options.onChordTap,
                ),
              ),
            if (measure.endBarline.isNotEmpty)
              Barline(barline: measure.endBarline, fontSize: options.fontSize),
          ],
        ],
      ),
    );
  }
}

class Barline extends StatelessWidget {
  const Barline({super.key, required this.barline, required this.fontSize});

  final String barline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = switch (barline) {
      '|:' => '𝄆',
      ':|' => '𝄇',
      '||' => '‖',
      '|]' => '𝄂',
      _ => barline,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        symbol,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
