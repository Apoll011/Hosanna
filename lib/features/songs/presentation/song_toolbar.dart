import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'chordpro/song_display_settings.dart';

/// Sliders icon button that opens the reading-settings popup, mirroring the
/// React `SongView` "Ajustes de Leitura" popover.
class SongToolbarButton extends StatelessWidget {
  const SongToolbarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.tune),
      tooltip: l10n.songControlsTitle,
      onPressed: () => showSongControlsSheet(context),
    );
  }
}

/// Opens the reading-settings popup as a rounded bottom sheet.
Future<void> showSongControlsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const SongControlsSheet(),
  );
}

/// Transpose / capo / font size / toggles, laid out like the React popover.
class SongControlsSheet extends ConsumerWidget {
  const SongControlsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(songDisplaySettingsProvider);
    final controller = ref.read(songDisplaySettingsProvider.notifier);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header.
            Row(
              children: [
                Text(
                  l10n.songControlsTitle.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonClose),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Transpose.
            _SectionTitle(
              label: l10n.songTranspose,
              value: settings.transpose > 0
                  ? '+${settings.transpose} ${l10n.songSemitones}'
                  : '${settings.transpose} ${l10n.songSemitones}',
            ),
            _StepperRow(
              onDec: () => controller.setTranspose(settings.transpose - 1),
              onInc: () => controller.setTranspose(settings.transpose + 1),
              onReset: () => controller.setTranspose(0),
              resetLabel: l10n.songOriginal,
            ),
            const SizedBox(height: 16),

            // Capo (guitar only).
            if (settings.isGuitar) ...[
              _SectionTitle(
                label: l10n.songCapo,
                value: settings.capo == 0
                    ? l10n.songCapoNone
                    : l10n.songCapoFret(settings.capo),
              ),
              _CapoSelector(
                value: settings.capo,
                onChanged: controller.setCapo,
              ),
              const SizedBox(height: 16),
            ],

            // Font size.
            _SectionTitle(
              label: l10n.songFontSize,
              value: '${settings.fontSize.toInt()}px',
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () =>
                      controller.setFontSize(settings.fontSize - 2),
                ),
                Expanded(
                  child: Slider(
                    value: settings.fontSize.clamp(10, 34).toDouble(),
                    min: 10,
                    max: 34,
                    divisions: 12,
                    label: settings.fontSize.toInt().toString(),
                    onChanged: controller.setFontSize,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      controller.setFontSize(settings.fontSize + 2),
                ),
              ],
            ),

            // Auto-scroll speed.
            _SectionTitle(
              label: l10n.songAutoScrollSpeed,
              value: '${settings.autoScrollSpeed.toInt()}x',
            ),
            Slider(
              value: settings.autoScrollSpeed.clamp(1, 10).toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: settings.autoScrollSpeed.toInt().toString(),
              onChanged: controller.setAutoScrollSpeed,
            ),

            const Divider(),
            const SizedBox(height: 4),

            // Toggles.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songShowChords),
              value: settings.showChords,
              onChanged: (_) => controller.toggleShowChords(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songTwoColumn),
              value: settings.twoColumn,
              onChanged: (_) => controller.toggleTwoColumn(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songShowDiagrams),
              value: settings.showDiagrams,
              onChanged: (_) => controller.toggleDiagrams(),
            ),

            const SizedBox(height: 8),
            _SectionTitle(label: l10n.songInstrument, value: ''),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'guitar',
                  label: Text(l10n.songGuitar),
                  icon: const Icon(Icons.graphic_eq),
                ),
                ButtonSegment(
                  value: 'piano',
                  label: Text(l10n.songPiano),
                  icon: const Icon(Icons.piano),
                ),
              ],
              selected: {settings.instrument},
              onSelectionChanged: (s) => controller.setInstrument(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (value.isNotEmpty)
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.onDec,
    required this.onInc,
    required this.onReset,
    required this.resetLabel,
  });

  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    );
    return Row(
      children: [
        Expanded(
          child: _StepButton(
            icon: Icons.remove,
            onTap: onDec,
            decoration: base,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: base,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                resetLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StepButton(
            icon: Icons.add,
            onTap: onInc,
            decoration: base,
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.decoration,
  });

  final IconData icon;
  final VoidCallback onTap;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _CapoSelector extends StatelessWidget {
  const _CapoSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final fret in [0, 1, 2, 3, 4, 5])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _CapoChip(
                label: fret == 0 ? '-' : '$fret',
                selected: value == fret,
                onTap: () => onChanged(fret),
                theme: theme,
              ),
            ),
          ),
      ],
    );
  }
}

class _CapoChip extends StatelessWidget {
  const _CapoChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
