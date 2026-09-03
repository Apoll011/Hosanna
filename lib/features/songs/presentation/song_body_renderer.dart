import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chordpro/chord_pro_renderer.dart';
import 'chordpro/song_display_settings.dart';

import '../domain/chordpro/parser.dart';

/// The single seam for rendering a song's ChordPro content.
///
/// v1 renders through [ChordProRenderer] (the ported `@hosanna/shared`
/// renderer) with the current [SongDisplaySettings]. Any future parser/renderer
/// swap happens here without touching the rest of the song feature.
///
/// Also publishes the parsed [ChordProDocument] to [songCurrentDocumentProvider]
/// so the toolbar can display the variant switcher without prop-drilling.
class SongBodyRenderer extends ConsumerStatefulWidget {
  const SongBodyRenderer({
    super.key,
    required this.content,
    this.scrollController,
    this.notes,
  });

  final String content;

  /// Optional external controller for auto-scroll / programmatic scrolling.
  final ScrollController? scrollController;

  /// Optional musician notes shown in a card below the song metadata header.
  final String? notes;

  @override
  ConsumerState<SongBodyRenderer> createState() => _SongBodyRendererState();
}

class _SongBodyRendererState extends ConsumerState<SongBodyRenderer> {
  @override
  void initState() {
    super.initState();
    _publishDocument();
  }

  @override
  void didUpdateWidget(covariant SongBodyRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _publishDocument();
    }
  }

  void _publishDocument() {
    final doc = parseChordProDocument(widget.content);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(songCurrentDocumentProvider.notifier).state = doc;

      // If the currently-selected variant no longer exists in the new document,
      // fall back to the default.
      final currentId = ref.read(songDisplaySettingsProvider).variantId;
      final stillExists = doc.variants.any((v) => v.id == currentId);
      if (!stillExists) {
        ref.read(songDisplaySettingsProvider.notifier).setVariantId('default');
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
    final settings = ref.watch(songDisplaySettingsProvider);
    return ChordProRenderer(
      content: widget.content,
      notes: widget.notes,
      showChords: settings.showChords,
      transpose: settings.transpose,
      capo: settings.capo,
      twoColumn: settings.twoColumn,
      fontSize: settings.fontSize,
      instrument: settings.instrument,
      showDiagrams: settings.showDiagrams,
      sectionColorBackground: settings.sectionColorBackground,
      scrollController: widget.scrollController,
      variantId: settings.variantId,
    );
  }
}
