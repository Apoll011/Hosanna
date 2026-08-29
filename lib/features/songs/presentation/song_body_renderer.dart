import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chordpro/chord_pro_renderer.dart';
import 'chordpro/song_display_settings.dart';

/// The single seam for rendering a song's ChordPro content.
///
/// v1 renders through [ChordProRenderer] (the ported `@hosanna/shared`
/// renderer) with the current [SongDisplaySettings]. Any future parser/renderer
/// swap happens here without touching the rest of the song feature.
class SongBodyRenderer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(songDisplaySettingsProvider);
    return ChordProRenderer(
      content: content,
      notes: notes,
      showChords: settings.showChords,
      transpose: settings.transpose,
      capo: settings.capo,
      twoColumn: settings.twoColumn,
      fontSize: settings.fontSize,
      instrument: settings.instrument,
      showDiagrams: settings.showDiagrams,
      sectionColorBackground: settings.sectionColorBackground,
      scrollController: scrollController,
    );
  }
}
