import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/chordpro/instruments/instruments.dart';

/// Presentation-only metadata for the registered instruments: an icon and a
/// localized label. Kept out of the domain so instruments stay Flutter-free.
extension InstrumentVisuals on Instrument {
  IconData get icon => switch (id) {
    'guitar' => Icons.graphic_eq,
    'ukulele' => Icons.music_note,
    'piano' => Icons.piano,
    _ => Icons.music_note,
  };

  String localizedLabel(AppLocalizations l10n) => switch (id) {
    'guitar' => l10n.songGuitar,
    'ukulele' => l10n.songUkulele,
    'piano' => l10n.songPiano,
    _ => label,
  };
}

/// Segmented picker listing every registered instrument.
///
/// Backed by [instrumentRegistry], so adding an instrument makes it appear in
/// the toolbar, the reader dialog and settings at once.
class InstrumentSelector extends StatelessWidget {
  const InstrumentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final instruments = instrumentRegistry.instruments;
    final selectedId = instrumentRegistry.resolve(selected).id;

    return SegmentedButton<String>(
      segments: [
        for (final instrument in instruments)
          ButtonSegment(
            value: instrument.id,
            label: Text(instrument.localizedLabel(l10n)),
            icon: Icon(instrument.icon),
          ),
      ],
      selected: {selectedId},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
