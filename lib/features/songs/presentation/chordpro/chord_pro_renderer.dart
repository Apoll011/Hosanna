import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/chordpro/chord_dictionary.dart';
import '../../domain/chordpro/parser.dart';
import '../../domain/chordpro/transpose.dart';
import 'chord_diagrams.dart';

/// Full ChordPro renderer, ported from `@hosanna/shared`'s ChordProRenderer.
///
/// Renders metadata, a chord-roll (when diagrams are enabled), and the parsed
/// sections (verses/choruses/bridges/tabs/grids/comments) with inline chords.
/// Tapping a chord opens a guitar/piano diagram dialog.
class ChordProRenderer extends StatefulWidget {
  const ChordProRenderer({
    super.key,
    required this.content,
    required this.showChords,
    this.transpose = 0,
    this.capo = 0,
    this.twoColumn = false,
    this.fontSize,
    this.instrument = 'guitar',
    this.showDiagrams = false,
    this.sectionColorBackground = false,
    this.scrollController,
    this.notes,
  });

  final String content;
  final bool showChords;
  final int transpose;
  final int capo;
  final bool twoColumn;
  final double? fontSize;
  final String instrument;
  final bool showDiagrams;
  final bool sectionColorBackground;

  /// Optional musician notes, shown in a card below the metadata header and
  /// before the chord roll (when present).
  final String? notes;

  /// Optional external controller for auto-scroll / programmatic scrolling.
  final ScrollController? scrollController;

  @override
  State<ChordProRenderer> createState() => _ChordProRendererState();
}

class _ChordProRendererState extends State<ChordProRenderer> {
  late SongAst _ast;
  String? _selectedChord;
  String _dialogInstrument = 'guitar';

  @override
  void initState() {
    super.initState();
    _ast = parseChordPro(widget.content);
  }

  @override
  void didUpdateWidget(covariant ChordProRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _ast = parseChordPro(widget.content);
    }
  }

  int get _effectiveCapo => widget.instrument == 'guitar' ? widget.capo : 0;

  int get _effectiveTranspose => widget.transpose - _effectiveCapo;

  List<String> get _uniqueChords {
    final chords = <String>{};
    for (final section in _ast.sections) {
      for (final line in section.lines) {
        for (final seg in line.segments ?? const <SegmentAst>[]) {
          if (seg.chord.isNotEmpty) chords.add(seg.chord);
        }
        for (final m in line.measures ?? const <MeasureAst>[]) {
          for (final c in m.chords) {
            if (c.chord.isNotEmpty) chords.add(c.chord);
          }
        }
      }
    }
    return chords.toList();
  }

  void _openChord(String chord) {
    setState(() {
      _selectedChord = chord;
      _dialogInstrument = widget.instrument;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _ast.metadata;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetadataHeader(
                metadata: metadata,
                soundingKey: transposeChord(
                  metadata['key'] ?? 'C',
                  widget.transpose,
                ),
                renderedKey: transposeChord(
                  metadata['key'] ?? 'C',
                  _effectiveTranspose,
                ),
                effectiveCapo: _effectiveCapo,
                transposeVal: widget.transpose,
              ),
              if (widget.notes != null && widget.notes!.trim().isNotEmpty)
                _NotesCard(notes: widget.notes!),
              if (widget.showDiagrams &&
                  widget.showChords &&
                  _uniqueChords.isNotEmpty)
                _ChordRoll(
                  uniqueChords: _uniqueChords,
                  effectiveTranspose: _effectiveTranspose,
                  capo: _effectiveCapo,
                  instrument: widget.instrument,
                  onChordTap: _openChord,
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: widget.fontSize,
                      height: 1.5,
                    ),
                    child: _buildSections(context, constraints),
                  );
                },
              ),
            ],
          ),
        ),
        if (_selectedChord != null)
          _ChordDialog(
            chord: _selectedChord!,
            instrument: _dialogInstrument,
            onInstrumentChange: (i) => setState(() => _dialogInstrument = i),
            onClose: () => setState(() => _selectedChord = null),
          ),
      ],
    );
  }

  Widget _buildSections(BuildContext context, BoxConstraints constraints) {
    final useTwoColumns = widget.twoColumn && constraints.maxWidth >= 500;

    if (!useTwoColumns || _ast.sections.length <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in _ast.sections) _renderSection(context, section),
        ],
      );
    }

    // Distribute sections evenly into 2 columns based on line count weights
    final col1 = <SectionAst>[];
    final col2 = <SectionAst>[];
    final sectionWeights = _ast.sections
        .map((s) => (s.lines.isEmpty ? 1 : s.lines.length) + 2)
        .toList();
    final totalWeight = sectionWeights.fold<int>(0, (a, b) => a + b);
    final halfWeight = totalWeight / 2;

    var currentWeight = 0;
    for (var i = 0; i < _ast.sections.length; i++) {
      final s = _ast.sections[i];
      final w = sectionWeights[i];
      if (col1.isEmpty ||
          (currentWeight + w <= halfWeight && i < _ast.sections.length - 1)) {
        col1.add(s);
        currentWeight += w;
      } else {
        col2.add(s);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in col1) _renderSection(context, section),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in col2) _renderSection(context, section),
            ],
          ),
        ),
      ],
    );
  }

  Widget _renderSection(BuildContext context, SectionAst section) {
    final theme = Theme.of(context);

    if (section.type == 'new_song') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.music_note,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
      );
    }

    if (section.type == 'grid') {
      final maxMeasures = section.lines.fold<int>(1, (m, l) {
        final len = l.measures?.length ?? 1;
        return len > m ? len : m;
      });
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  section.label?.isNotEmpty == true
                      ? section.label!
                      : 'Instrumental',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in section.lines)
              _LineRenderer(
                line: line,
                showChords: widget.showChords,
                transpose: _effectiveTranspose,
                onChordTap: _openChord,
                maxGridMeasures: maxMeasures,
              ),
          ],
        ),
      );
    }

    if (section.type == 'tab') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.label?.isNotEmpty == true ? section.label! : 'Tablatura',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              section.lines.map((l) => l.text ?? '').join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.6,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      );
    }

    if (section.type == 'comment') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          section.lines.map((l) => l.text ?? '').join(', '),
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final isChorus = section.type == 'chorus';
    final isBridge = section.type == 'bridge';
    final isLabeled = isChorus || isBridge;

    final accent = isChorus
        ? theme.colorScheme.primary
        : (isBridge
              ? const Color(0xFFD97706)
              : theme.colorScheme.outlineVariant);

    final showBackground = widget.sectionColorBackground;
    final backgroundColor = showBackground
        ? (isChorus
              ? theme.colorScheme.primary.withValues(alpha: 0.04)
              : (isBridge
                    ? const Color(0xFFD97706).withValues(alpha: 0.04)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.04)))
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: showBackground
          ? const EdgeInsets.fromLTRB(12, 4, 8, 4)
          : const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: showBackground ? BorderRadius.circular(4) : null,
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label?.isNotEmpty == true || isLabeled)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _sectionLabel(section),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          if (section.lines.isEmpty && isChorus)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '(Repete o refrão)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final line in section.lines)
            _LineRenderer(
              line: line,
              showChords: widget.showChords,
              transpose: _effectiveTranspose,
              onChordTap: _openChord,
            ),
        ],
      ),
    );
  }

  String _sectionLabel(SectionAst section) {
    final label = section.label;
    if (label != null && label.isNotEmpty) return label;
    return switch (section.type) {
      'chorus' => 'Refrão',
      'bridge' => 'Ponte',
      _ => '',
    };
  }
}

// ── Metadata header ────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.servicesNotes.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataHeader extends StatelessWidget {
  const _MetadataHeader({
    required this.metadata,
    required this.soundingKey,
    required this.renderedKey,
    required this.effectiveCapo,
    required this.transposeVal,
  });

  final Map<String, String> metadata;
  final String soundingKey;
  final String renderedKey;
  final int effectiveCapo;
  final int transposeVal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = metadata['title'];
    final subtitle = metadata['subtitle'];
    final artist = metadata['artist'];
    final composer = metadata['composer'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null && subtitle.isNotEmpty)
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if ((artist != null && artist.isNotEmpty) ||
              (composer != null && composer.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  artist,
                  composer,
                ].where((e) => e != null && e.isNotEmpty).join(' / '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (metadata.keys.any(
            (k) => [
              'key',
              'originalKey',
              'capo',
              'tempo',
              'time',
              'ccli',
              'songNumber',
            ].contains(k),
          ))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (metadata['songNumber'] != null &&
                      metadata['songNumber']!.isNotEmpty)
                    _pill(context, 'Nº ${metadata['songNumber']}'),
                  if ((metadata['key'] != null &&
                          metadata['key']!.isNotEmpty) ||
                      transposeVal != 0)
                    _pill(context, 'Tom: $soundingKey'),
                  if (effectiveCapo > 0)
                    _pill(context, 'Capo: $effectiveCapoª casa'),
                  if (effectiveCapo > 0)
                    _pill(context, 'Formato: $renderedKey'),
                  if (metadata['originalKey'] != null &&
                      metadata['originalKey']!.isNotEmpty)
                    _pill(context, 'Tom Orig: ${metadata['originalKey']}'),
                  if (metadata['tempo'] != null &&
                      metadata['tempo']!.isNotEmpty)
                    _pill(context, '${metadata['tempo']} BPM'),
                  if (metadata['time'] != null && metadata['time']!.isNotEmpty)
                    _pill(context, metadata['time']!),
                  if (metadata['ccli'] != null && metadata['ccli']!.isNotEmpty)
                    _pill(context, 'CCLI: ${metadata['ccli']}'),
                ],
              ),
            ),
          if (metadata['copyright'] != null &&
              metadata['copyright']!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '© ${metadata['copyright']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Line renderers ─────────────────────────────────────────────────────────

class _LineRenderer extends StatelessWidget {
  const _LineRenderer({
    required this.line,
    required this.showChords,
    required this.transpose,
    required this.onChordTap,
    this.maxGridMeasures,
  });

  final LineAst line;
  final bool showChords;
  final int transpose;
  final void Function(String) onChordTap;
  final int? maxGridMeasures;

  @override
  Widget build(BuildContext context) {
    switch (line.type) {
      case 'empty':
        return const SizedBox(height: 8);
      case 'comment':
        return Text(
          line.text ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      case 'comment_box':
        return _CommentBoxRenderer(line: line);
      case 'chord-section':
        return _ChordSectionRenderer(
          line: line,
          showChords: showChords,
          transpose: transpose,
          onChordTap: onChordTap,
          maxMeasures: maxGridMeasures,
        );
      default:
        return _LyricsRenderer(
          line: line,
          showChords: showChords,
          transpose: transpose,
          onChordTap: onChordTap,
        );
    }
  }
}

class _CommentBoxRenderer extends StatelessWidget {
  const _CommentBoxRenderer({required this.line});

  final LineAst line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(left: BorderSide(color: Color(0xFFF59E0B), width: 4)),
        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line.text ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsRenderer extends StatelessWidget {
  const _LyricsRenderer({
    required this.line,
    required this.showChords,
    required this.transpose,
    required this.onChordTap,
  });

  final LineAst line;
  final bool showChords;
  final int transpose;
  final void Function(String) onChordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = line.segments ?? const <SegmentAst>[];
    final chordFontSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.85;

    // Tokenize segments so chords align precisely above the target word/syllable
    // and lines wrap naturally word-by-word.
    final items = <({String chord, String text})>[];

    for (final seg in segments) {
      final text = seg.text;
      if (text.isEmpty) {
        items.add((chord: seg.chord, text: ''));
        continue;
      }

      final matches = RegExp(r'\S+\s*|\s+').allMatches(text).toList();
      if (matches.isEmpty) {
        items.add((chord: seg.chord, text: text));
      } else {
        var chordAssigned = false;
        for (var i = 0; i < matches.length; i++) {
          final chunk = matches[i].group(0)!;
          final isWord = chunk.trim().isNotEmpty;
          if (!chordAssigned && (isWord || i == matches.length - 1)) {
            items.add((chord: seg.chord, text: chunk));
            chordAssigned = true;
          } else {
            items.add((chord: '', text: chunk));
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (final item in items)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showChords)
                  if (item.chord.isNotEmpty)
                    GestureDetector(
                      onTap: () =>
                          onChordTap(transposeChord(item.chord, transpose)),
                      child: Text(
                        transposeChord(item.chord, transpose),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: chordFontSize,
                          height: 1.2,
                        ),
                      ),
                    )
                  else
                    SizedBox(height: chordFontSize * 1.2),
                Text(
                  item.text.isEmpty ? '\u00A0' : item.text,
                  style: const TextStyle(height: 1.3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChordSectionRenderer extends StatelessWidget {
  const _ChordSectionRenderer({
    required this.line,
    required this.showChords,
    required this.transpose,
    required this.onChordTap,
    this.maxMeasures,
  });

  final LineAst line;
  final bool showChords;
  final int transpose;
  final void Function(String) onChordTap;
  final int? maxMeasures;

  @override
  Widget build(BuildContext context) {
    if (!showChords) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final measures = line.measures ?? const <MeasureAst>[];

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
        children: [
          if (line.startBarline != null && line.startBarline!.isNotEmpty)
            _Barline(barline: line.startBarline!),
          for (final measure in measures) ...[
            for (final c in measure.chords)
              GestureDetector(
                onTap: () => onChordTap(transposeChord(c.chord, transpose)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    transposeChord(c.chord, transpose),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            if (measure.endBarline.isNotEmpty)
              _Barline(barline: measure.endBarline),
          ],
        ],
      ),
    );
  }
}

class _Barline extends StatelessWidget {
  const _Barline({required this.barline});

  final String barline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = switch (barline) {
      '|:' => '𝄆',
      ':|' => '𝄇',
      '||' => '‖',
      '|]' => '𝄂',
      '|' => '|',
      _ => barline,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        symbol,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ── Chord roll + dictionary dialog ─────────────────────────────────────────

class _ChordRoll extends StatelessWidget {
  const _ChordRoll({
    required this.uniqueChords,
    required this.effectiveTranspose,
    required this.capo,
    required this.instrument,
    required this.onChordTap,
  });

  final List<String> uniqueChords;
  final int effectiveTranspose;
  final int capo;
  final String instrument;
  final void Function(String) onChordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (instrument == 'guitar' && capo > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Capo na $capoª casa',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final chord in uniqueChords)
                  _ChordRollItem(
                    chord: chord,
                    transposed: transposeChord(chord, effectiveTranspose),
                    instrument: instrument,
                    onTap: onChordTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordRollItem extends StatelessWidget {
  const _ChordRollItem({
    required this.chord,
    required this.transposed,
    required this.instrument,
    required this.onTap,
  });

  final String chord;
  final String transposed;
  final String instrument;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fingering = chordDictionary.getFingering(transposed);

    return InkWell(
      onTap: () => onTap(transposed),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Text(
              transposed,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 116,
              child: _DiagramBody(fingering: fingering, instrument: instrument),
            ),
            if (fingering != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  fingering.piano.notes.join(' - '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagramBody extends StatelessWidget {
  const _DiagramBody({required this.fingering, required this.instrument});

  final ChordFingering? fingering;
  final String instrument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (fingering == null) {
      return const Center(
        child: Text('—', style: TextStyle(color: Colors.grey)),
      );
    }

    final colors = _DiagramColors.of(context);
    if (instrument == 'piano') {
      return PianoDiagram(
        highlightKeys: fingering!.piano.highlightKeys,
        highlightColor: colors.primary,
        whiteColor: colors.white,
        blackColor: colors.black,
        keyLineColor: colors.line,
        dotColor: colors.primary,
      );
    }

    final guitar = fingering!.guitar;
    if (guitar == null) {
      return const Center(
        child: Text('Sem visual', style: TextStyle(color: Colors.grey)),
      );
    }
    return GuitarDiagram(
      frets: guitar.frets,
      fingers: guitar.fingers,
      barre: guitar.barre,
      dotColor: colors.primary,
      lineColor: colors.line,
      textColor: colors.text,
      muteColor: theme.colorScheme.error,
      openColor: const Color(0xFF10B981),
    );
  }
}

class _DiagramColors {
  const _DiagramColors({
    required this.primary,
    required this.line,
    required this.text,
    required this.white,
    required this.black,
  });

  final Color primary;
  final Color line;
  final Color text;
  final Color white;
  final Color black;

  static _DiagramColors of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _DiagramColors(
      primary: theme.colorScheme.primary,
      line: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
      text: theme.colorScheme.onSurface,
      white: isDark ? const Color(0xFF27272A) : Colors.white,
      black: isDark ? const Color(0xFF09090B) : const Color(0xFF27272A),
    );
  }
}

class _ChordDialog extends StatelessWidget {
  const _ChordDialog({
    required this.chord,
    required this.instrument,
    required this.onInstrumentChange,
    required this.onClose,
  });

  final String chord;
  final String instrument;
  final void Function(String) onInstrumentChange;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fingering = chordDictionary.getFingering(chord);

    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dicionário: $chord',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'guitar', label: Text('Guitarra')),
                      ButtonSegment(value: 'piano', label: Text('Piano')),
                    ],
                    selected: {instrument},
                    onSelectionChanged: (s) => onInstrumentChange(s.first),
                  ),
                  const SizedBox(height: 16),
                  if (fingering != null)
                    _DiagramBody(fingering: fingering, instrument: instrument)
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Acorde "$chord" não registado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (fingering != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Notas: ${fingering.piano.notes.join(' - ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
