import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/chordpro/instruments/instruments.dart';

/// Presentation-only metadata for the registered instruments: an icon and a
/// localized label. Kept out of the domain so instruments stay Flutter-free.
extension InstrumentVisuals on Instrument {
  IconData get icon => switch (id) {
        'guitar' => Icons.music_note_rounded,
        'bass' => Icons.queue_music_rounded,
        'ukulele' => Icons.nightlife_rounded,
        'piano' => Icons.piano,
        _ => Icons.music_note_outlined,
      };

  String localizedLabel(AppLocalizations l10n) => switch (id) {
        'guitar' => l10n.songGuitar,
        'bass' => l10n.songBass,
        'ukulele' => l10n.songUkulele,
        'piano' => l10n.songPiano,
        _ => label,
      };
}

extension FrettedTuningVisuals on FrettedTuning {
  String localizedLabel(AppLocalizations l10n) => switch (id) {
        'standard' => l10n.tuningGuitarStandard,
        'drop_d' => l10n.tuningGuitarDropD,
        'seven_string' => l10n.tuningGuitarSevenString,
        'five_string' => l10n.tuningBassFiveString,
        'high_g' => l10n.tuningUkuleleHighG,
        'low_g' => l10n.tuningUkuleleLowG,
        'baritone' => l10n.tuningUkuleleBaritone,
        _ => label,
      };
}

/// Scalable instrument picker backed by [instrumentRegistry].
///
/// Uses a wrapping chip grid instead of [SegmentedButton] so adding bass,
/// mandolin, etc. later does not overflow the toolbar or settings card.
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
    final theme = Theme.of(context);
    final instruments = instrumentRegistry.instruments;
    final selectedId = instrumentRegistry.resolve(selected).id;

    // Group by family so future instruments slot into clear sections.
    final fretted = instruments
        .where((i) => i.family == InstrumentFamily.fretted)
        .toList(growable: false);
    final keyed = instruments
        .where((i) => i.family == InstrumentFamily.keyboard)
        .toList(growable: false);
    final other = instruments
        .where((i) => i.family == InstrumentFamily.other)
        .toList(growable: false);

    Widget section(List<Instrument> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final instrument in items)
            _InstrumentChip(
              selected: instrument.id == selectedId,
              icon: instrument.icon,
              label: instrument.localizedLabel(l10n),
              onTap: () => onChanged(instrument.id),
              theme: theme,
            ),
        ],
      );
    }

    final showHeaders = fretted.isNotEmpty &&
        (keyed.isNotEmpty || other.isNotEmpty);

    if (!showHeaders) {
      return section(instruments);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fretted.isNotEmpty) ...[
          Text(
            l10n.instrumentFamilyFretted,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          section(fretted),
        ],
        if (keyed.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.instrumentFamilyKeyboard,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          section(keyed),
        ],
        if (other.isNotEmpty) ...[
          const SizedBox(height: 12),
          section(other),
        ],
      ],
    );
  }
}

/// Tuning / string-configuration picker for a fretted instrument.
class FrettedTuningSelector extends StatelessWidget {
  const FrettedTuningSelector({
    super.key,
    required this.tunings,
    required this.selectedId,
    required this.onChanged,
  });

  final List<FrettedTuning> tunings;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tunings.length <= 1) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeId = selectedId ?? tunings.first.id;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tuning in tunings)
          FilterChip(
            selected: tuning.id == activeId,
            showCheckmark: false,
            label: Text(tuning.localizedLabel(l10n)),
            avatar: Text(
              '${tuning.stringCount}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tuning.id == activeId
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onSelected: (_) => onChanged(tuning.id),
          ),
      ],
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final border = selected ? scheme.primary : scheme.outlineVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
