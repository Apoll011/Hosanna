import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chordpro/chord_pro_renderer.dart';
import 'chordpro/song_display_settings.dart';
import 'song_toolbar.dart';

import '../domain/chordpro/parser.dart';

/// The single seam for rendering a song's ChordPro content.
///
/// v1 renders through [ChordProRenderer] (the ported `@hosanna/shared`
/// renderer) with the current [SongDisplaySettings]. Any future parser/renderer
/// swap happens here without touching the rest of the song feature.
///
/// Parses the content once and also publishes the [ChordProDocument] to
/// [songCurrentDocumentProvider] so the toolbar can display the variant
/// switcher without prop-drilling.
class SongBodyRenderer extends ConsumerStatefulWidget {
  const SongBodyRenderer({
    super.key,
    required this.content,
    this.scrollController,
    this.notes,
    this.bottomInset = 0,
    this.onYoutubeTap,
  });

  final String content;

  /// Optional external controller for auto-scroll / programmatic scrolling.
  final ScrollController? scrollController;

  /// Optional musician notes shown in a card below the song metadata header.
  final String? notes;

  /// Extra bottom padding so floating overlays never hide the last lines.
  final double bottomInset;

  /// Opens the YouTube player from the header pill.
  final VoidCallback? onYoutubeTap;

  @override
  ConsumerState<SongBodyRenderer> createState() => _SongBodyRendererState();
}

class _SongBodyRendererState extends ConsumerState<SongBodyRenderer> {
  late ChordProDocument _document;

  @override
  void initState() {
    super.initState();
    _parseAndPublish();
  }

  @override
  void didUpdateWidget(covariant SongBodyRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseAndPublish();
    }
  }

  void _parseAndPublish() {
    final doc = parseChordProDocument(widget.content);
    _document = doc;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(songCurrentDocumentProvider.notifier).state = doc;

      // If the currently-selected variant no longer exists in the new document,
      // fall back to the default. Defer the settings write so we don't notify
      // [songDisplaySettingsProvider] listeners mid-frame (e.g. SongToolbar).
      final currentId = ref.read(songDisplaySettingsProvider).variantId;
      final stillExists = doc.variants.any((v) => v.id == currentId);
      if (!stillExists && currentId != 'default') {
        Future<void>(() {
          if (!mounted) return;
          ref
              .read(songDisplaySettingsProvider.notifier)
              .setVariantId('default');
        });
      }
    });
  }

  @override
  void dispose() {
    ref.read(songCurrentDocumentProvider.notifier).state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Everything but the transient auto-scroll speed affects rendering.
    final s = ref.watch(
      songDisplaySettingsProvider.select(
        (s) => (
          showChords: s.showChords,
          transpose: s.transpose,
          capo: s.capo,
          twoColumn: s.twoColumn,
          fontSize: s.fontSize,
          instrument: s.instrument,
          showDiagrams: s.showDiagrams,
          sectionColorBackground: s.sectionColorBackground,
          variantId: s.variantId,
          instrumentPreferences: s.instrumentPreferences,
        ),
      ),
    );
    return ChordProRenderer(
      document: _document,
      notes: widget.notes,
      showChords: s.showChords,
      transpose: s.transpose,
      capo: s.capo,
      twoColumn: s.twoColumn,
      fontSize: s.fontSize,
      instrument: s.instrument,
      showDiagrams: s.showDiagrams,
      sectionColorBackground: s.sectionColorBackground,
      scrollController: widget.scrollController,
      variantId: s.variantId,
      instrumentPreferences: s.instrumentPreferences,
      bottomInset: widget.bottomInset,
      onKeyTap: () => showSongControlsSheet(context),
      onYoutubeTap: widget.onYoutubeTap,
    );
  }
}
