import 'package:flutter/material.dart';

import '../../domain/chordpro/chord_dictionary.dart';
import '../../domain/chordpro/instruments/instruments.dart';
import '../../domain/chordpro/parser.dart';
import '../../domain/chordpro/transpose.dart';
import 'widgets/chord_roll.dart';
import 'widgets/chord_sheet.dart';
import 'widgets/line_renderers.dart';
import 'widgets/metadata_header.dart';
import 'widgets/render_model.dart';
import 'widgets/section_view.dart';

/// Full ChordPro renderer, ported from `@hosanna/shared`'s ChordProRenderer.
///
/// Renders metadata, a chord-roll (when diagrams are enabled), and the parsed
/// sections (verses/choruses/bridges/tabs/grids/comments) with inline chords.
/// Tapping a chord opens the chord dictionary sheet.
///
/// Sections are laid out lazily, and the tokenized/transposed song is cached
/// until the document, variant or effective transposition changes.
class ChordProRenderer extends StatefulWidget {
  const ChordProRenderer({
    super.key,
    required this.document,
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
    this.variantId = 'default',
    this.instrumentPreferences = const InstrumentPreferences(),
    this.bottomInset = 0,
    this.onKeyTap,
    this.onYoutubeTap,
  });

  final ChordProDocument document;
  final bool showChords;
  final int transpose;
  final int capo;
  final bool twoColumn;
  final double? fontSize;
  final String instrument;
  final bool showDiagrams;
  final bool sectionColorBackground;

  /// Active variant id — delegates variant selection to the caller.
  /// Defaults to `'default'` (the main song body).
  final String variantId;

  /// Per-instrument voicing / diagram preferences.
  final InstrumentPreferences instrumentPreferences;

  /// Optional musician notes, shown in a card below the metadata header and
  /// before the chord roll (when present).
  final String? notes;

  /// Optional external controller for auto-scroll / programmatic scrolling.
  final ScrollController? scrollController;

  /// Extra bottom padding so floating overlays never hide the last lines.
  final double bottomInset;

  /// Called when the key pill is tapped (e.g. to open transpose controls).
  final VoidCallback? onKeyTap;

  /// Called when the YouTube pill is tapped; the pill is hidden when null.
  final VoidCallback? onYoutubeTap;

  @override
  State<ChordProRenderer> createState() => _ChordProRendererState();
}

class _ChordProRendererState extends State<ChordProRenderer> {
  late ChordProVersion _version;
  late PreparedSong _song;
  final Map<String, ChordFingering?> _fingerings = {};

  Instrument get _instrument => instrumentRegistry.resolve(widget.instrument);

  int get _effectiveCapo => _instrument.supportsCapo ? widget.capo : 0;

  int get _effectiveTranspose => widget.transpose - _effectiveCapo;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant ChordProRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCapo =
        instrumentRegistry.resolve(oldWidget.instrument).supportsCapo
        ? oldWidget.capo
        : 0;
    if (!identical(oldWidget.document, widget.document) ||
        oldWidget.variantId != widget.variantId ||
        oldWidget.transpose - oldCapo != _effectiveTranspose) {
      _prepare();
    }
    if (!identical(
      oldWidget.instrumentPreferences,
      widget.instrumentPreferences,
    )) {
      _fingerings.clear();
    }
  }

  void _prepare() {
    _version = selectVersion(widget.document, widget.variantId);
    _song = prepareSong(_version.body, _effectiveTranspose);
  }

  ChordFingering? _fingeringFor(String chord) => _fingerings.putIfAbsent(
    chord,
    () => chordDictionary.getFingering(
      chord,
      preferences: widget.instrumentPreferences,
    ),
  );

  void _openChord(String chord) {
    showChordSheet(
      context,
      chord: chord,
      chords: _song.uniqueChords,
      instrument: widget.instrument,
      capo: _effectiveCapo,
      preferences: widget.instrumentPreferences,
      fingeringFor: _fingeringFor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _version.metadata;
    final fontSize =
        widget.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? 14;
    final lyricStyle = theme.textTheme.bodyMedium!.copyWith(
      fontSize: fontSize,
      height: 1.5,
    );
    final options = LineRenderOptions(
      showChords: widget.showChords,
      fontSize: fontSize,
      onChordTap: _openChord,
    );

    final notes = widget.notes?.trim();
    final key = metadata['key'] ?? 'C';
    final showRoll =
        widget.showDiagrams &&
        widget.showChords &&
        _song.uniqueChords.isNotEmpty;

    final leading = <Widget>[
      MetadataHeader(
        metadata: metadata,
        soundingKey: transposeChord(key, widget.transpose),
        renderedKey: transposeChord(key, _effectiveTranspose),
        effectiveCapo: _effectiveCapo,
        transposeVal: widget.transpose,
        onKeyTap: widget.onKeyTap,
        onYoutubeTap: widget.onYoutubeTap,
      ),
      if (notes != null && notes.isNotEmpty) NotesCard(notes: widget.notes!),
      if (showRoll)
        ChordRoll(
          chords: _song.uniqueChords,
          capo: _effectiveCapo,
          instrument: widget.instrument,
          preferences: widget.instrumentPreferences,
          fingeringFor: _fingeringFor,
          onChordTap: _openChord,
        ),
    ];

    Widget sectionView(PreparedSection section) => SectionView(
      section: section,
      options: options,
      colorBackground: widget.sectionColorBackground,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final sections = _song.sections;
        final useTwoColumns =
            widget.twoColumn &&
            constraints.maxWidth - 32 >= 500 &&
            sections.length > 1;
        final bodyCount = useTwoColumns ? 1 : sections.length;

        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 48 + widget.bottomInset),
              sliver: SliverList.builder(
                itemCount: leading.length + bodyCount,
                itemBuilder: (context, i) {
                  if (i < leading.length) return leading[i];
                  final Widget body;
                  if (useTwoColumns) {
                    final (col1, col2) = _song.splitColumns();
                    body = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [for (final s in col1) sectionView(s)],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [for (final s in col2) sectionView(s)],
                          ),
                        ),
                      ],
                    );
                  } else {
                    body = sectionView(sections[i - leading.length]);
                  }
                  return DefaultTextStyle(style: lyricStyle, child: body);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
