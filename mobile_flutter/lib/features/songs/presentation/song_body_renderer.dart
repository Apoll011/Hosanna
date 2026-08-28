import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// The single seam for rendering a song's ChordPro content.
///
/// v1 renders the raw ChordPro text in a monospace block. When the real
/// ChordPro parser/renderer lands, swap the implementation *here* — the rest of
/// the song feature only ever talks to this widget.
class SongBodyRenderer extends StatelessWidget {
  const SongBodyRenderer({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (content.trim().isEmpty) {
      return Center(child: Text(l10n.songsNoContent));
    }

    return SelectableText(
      content,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        height: 1.5,
        fontSize: 14,
      ),
    );
  }
}
