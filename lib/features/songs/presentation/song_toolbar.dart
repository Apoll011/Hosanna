import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/chordpro/chord_notation.dart';
import '../domain/chordpro/parser.dart';
import '../domain/chordpro/resolve_chords.dart';
import '../domain/chordpro/transpose.dart';
import 'chordpro/instrument_selector.dart';
import 'chordpro/song_display_settings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sliders icon button that opens the reading-settings popup, mirroring the
/// React `SongView` "Ajustes de Leitura" popover.
///
/// Standalone song views show a compact variant dropdown beside the button.
/// Service song views keep variants inside [SongControlsSheet] as chips.
class SongToolbarButton extends ConsumerWidget {
  const SongToolbarButton({super.key, this.variantAsChips = false});

  /// When true (service song reader), variants appear as chips inside the
  /// song controls sheet instead of a dropdown on the service top bar.
  final bool variantAsChips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final doc = ref.watch(songCurrentDocumentProvider);
    final settings = ref.watch(songDisplaySettingsProvider);
    final controller = ref.read(songDisplaySettingsProvider.notifier);
    final versions = doc != null && doc.variants.isNotEmpty
        ? [doc.defaultVersion, ...doc.variants]
        : const <ChordProVersion>[];
    void selectVariant(String id) {
      if (doc == null) return;
      final defaults = resolveVariantDefaults(
        doc.defaultVersion,
        id == 'default' ? null : selectVersion(doc, id),
      );
      controller.setVariantId(
        id,
        transpose: defaults.transpose,
        capo: defaults.capo,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!variantAsChips && versions.isNotEmpty)
          _ToolbarVariantButton(
            versions: versions,
            selectedId: settings.variantId,
            onSelected: selectVariant,
          ),
        IconButton(
          icon: const Icon(LucideIcons.slidersHorizontal),
          tooltip: l10n.songControlsTitle,
          onPressed: () =>
              showSongControlsSheet(context, variantAsChips: variantAsChips),
        ),
      ],
    );
  }
}

/// Opens the reading-settings popup as a rounded bottom sheet.
Future<void> showSongControlsSheet(
  BuildContext context, {
  bool variantAsChips = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: HosannaRadii.sheet),
    builder: (_) => SongControlsSheet(variantAsChips: variantAsChips),
  );
}

/// Transpose / capo / font size / toggles, laid out like the React popover.
class SongControlsSheet extends ConsumerStatefulWidget {
  const SongControlsSheet({super.key, this.variantAsChips = false});

  /// When true, show a chip variant selector at the top of this sheet.
  final bool variantAsChips;

  @override
  ConsumerState<SongControlsSheet> createState() => _SongControlsSheetState();
}

class _SongControlsSheetState extends ConsumerState<SongControlsSheet> {
  /// Instrument picker starts collapsed so the sheet opens compact.
  bool _instrumentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(songDisplaySettingsProvider);
    final controller = ref.read(songDisplaySettingsProvider.notifier);
    final doc = ref.watch(songCurrentDocumentProvider);
    final versions =
        widget.variantAsChips && doc != null && doc.variants.isNotEmpty
        ? [doc.defaultVersion, ...doc.variants]
        : const <ChordProVersion>[];
    void selectVariant(String id) {
      if (doc == null) return;
      final defaults = resolveVariantDefaults(
        doc.defaultVersion,
        id == 'default' ? null : selectVersion(doc, id),
      );
      controller.setVariantId(
        id,
        transpose: defaults.transpose,
        capo: defaults.capo,
      );
    }

    final version = doc == null ? null : selectVersion(doc, settings.variantId);
    final originalKey = version?.metadata['key'];
    final keyNames = _keyNamesFor(originalKey);
    final originalPitch = _keyPitch(originalKey);
    final notation = ChordNotationRegistry.resolve(settings.chordNotationId);
    final selectedKeyName = ChordNotationConverter.formatChord(
      keyNames[_keyPitchAfter(originalPitch, settings.transpose)],
      notation,
    );
    final transposeValue = settings.transpose > 0
        ? '+${settings.transpose} ${l10n.songSemitones}'
        : '${settings.transpose} ${l10n.songSemitones}';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),

            if (versions.isNotEmpty) ...[
              _SectionTitle(label: l10n.songVariant, value: ''),
              _ToolbarVariantChips(
                versions: versions,
                selectedId: settings.variantId,
                onSelected: selectVariant,
              ),
              const SizedBox(height: 16),
            ],

            // Transpose / capo only matter when chords are visible.
            if (settings.showChords) ...[
              _SectionTitle(
                label: l10n.songTranspose,
                value: '$selectedKeyName · $transposeValue',
              ),
              _KeyPickerChart(
                keyNames: keyNames,
                originalPitch: originalPitch,
                transpose: settings.transpose,
                notation: notation,
                onSelected: controller.setTranspose,
              ),
              const SizedBox(height: 8),
              const _KeyChartLegend(),
              const SizedBox(height: 16),

              // Capo (only for instruments where it changes the pitch).
              if (settings.instrumentSupportsCapo) ...[
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
            ],

            // Font size.
            _SectionTitle(
              label: l10n.songFontSize,
              value: '${settings.fontSize.toInt()}px',
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.minus),
                  onPressed: () =>
                      controller.setFontSize(settings.fontSize - 2),
                ),
                Expanded(
                  child: Slider(
                    value: settings.fontSize
                        .clamp(
                          SongDisplaySettings.minFontSize,
                          SongDisplaySettings.maxFontSize,
                        )
                        .toDouble(),
                    min: SongDisplaySettings.minFontSize,
                    max: SongDisplaySettings.maxFontSize,
                    divisions:
                        ((SongDisplaySettings.maxFontSize -
                                    SongDisplaySettings.minFontSize) /
                                2)
                            .round(),
                    label: settings.fontSize.toInt().toString(),
                    onChanged: controller.setFontSize,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus),
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
            if (settings.showChords)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.songShowDiagrams),
                value: settings.showDiagrams,
                onChanged: (_) => controller.toggleDiagrams(),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songSectionBackground),
              value: settings.sectionColorBackground,
              onChanged: (_) => controller.toggleSectionColorBackground(),
            ),

            if (settings.showChords) ...[
              const SizedBox(height: 8),
              _CollapsibleInstrumentHeader(
                label: l10n.songInstrument,
                selectedLabel: settings.instrumentInfo.localizedLabel(l10n),
                expanded: _instrumentExpanded,
                onToggle: () {
                  setState(() => _instrumentExpanded = !_instrumentExpanded);
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _instrumentExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InstrumentSelector(
                          selected: settings.instrument,
                          onChanged: controller.setInstrument,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable instrument row: shows the current choice and a rotating chevron.
class _CollapsibleInstrumentHeader extends StatelessWidget {
  const _CollapsibleInstrumentHeader({
    required this.label,
    required this.selectedLabel,
    required this.expanded,
    required this.onToggle,
  });

  final String label;
  final String selectedLabel;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                selectedLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  LucideIcons.chevronDown,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
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

/// The twelve chromatic keys, spelled with sharps or flats to match the
/// song's written key.
const List<String> _sharpKeyNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];
const List<String> _flatKeyNames = [
  'C',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

bool _usesFlatKeyNames(String? key) {
  final match = RegExp(r'^[A-Ga-g][#b]?').firstMatch(key?.trim() ?? '');
  return match?.group(0)?.endsWith('b') ?? false;
}

List<String> _keyNamesFor(String? key) =>
    _usesFlatKeyNames(key) ? _flatKeyNames : _sharpKeyNames;

int _keyPitch(String? key) => getNoteValue(key ?? '') ?? 0;

int _keyPitchAfter(int originalPitch, int transpose) =>
    (originalPitch + transpose % 12 + 24) % 12;

/// Semitone shift for a tapped key, kept within one octave of the original.
///
/// Keys to the left of the original lower the pitch, so musicians get the
/// expected `-1` rather than `+11` when tapping the key below the original.
int _shiftForKey(int originalPitch, int keyPitch) {
  final shift = (keyPitch - originalPitch + 12) % 12;
  return shift > 6 ? shift - 12 : shift;
}

/// Inline, Cifra Club-style chart of the twelve keys.
///
/// The selected key is filled; the song's original key carries a small dot so
/// both can be identified at a glance, even when they are the same key.
class _KeyPickerChart extends StatelessWidget {
  const _KeyPickerChart({
    required this.keyNames,
    required this.originalPitch,
    required this.transpose,
    required this.notation,
    required this.onSelected,
  });

  final List<String> keyNames;
  final int originalPitch;
  final int transpose;
  final ChordNotationSystem notation;
  final ValueChanged<int> onSelected;

  static const int _columns = 4;
  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedPitch = _keyPitchAfter(originalPitch, transpose);
    final rows = <Widget>[];

    for (var start = 0; start < keyNames.length; start += _columns) {
      final cells = <Widget>[];
      for (var index = start; index < start + _columns; index++) {
        if (index > start) {
          cells.add(const SizedBox(width: _spacing));
        }
        final label = keyNames[index];
        final displayLabel = ChordNotationConverter.formatChord(
          label,
          notation,
        );
        final isSelected = index == selectedPitch;
        final isOriginal = index == originalPitch;
        cells.add(
          Expanded(
            child: _KeyButton(
              key: ValueKey('song-key-$label'),
              label: displayLabel,
              selected: isSelected,
              original: isOriginal,
              semanticsLabel: l10n.songKeyPill(displayLabel),
              originalHint: isOriginal
                  ? l10n.songOriginalKeyPill(displayLabel)
                  : null,
              onTap: () => onSelected(_shiftForKey(originalPitch, index)),
            ),
          ),
        );
      }
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: _spacing));
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    super.key,
    required this.label,
    required this.selected,
    required this.original,
    required this.semanticsLabel,
    required this.onTap,
    this.originalHint,
  });

  final String label;
  final bool selected;
  final bool original;
  final String semanticsLabel;
  final String? originalHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    final markerColor = selected ? scheme.onPrimary : scheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      hint: originalHint,
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HosannaRadii.sm),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HosannaRadii.sm),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (original)
                  Positioned(
                    bottom: 7,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small legend explaining the chart's two states.
class _KeyChartLegend extends StatelessWidget {
  const _KeyChartLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendItem(
          marker: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          label: l10n.songOriginal,
          style: style,
        ),
        _LegendItem(
          marker: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          label: l10n.songKeySelected,
          style: style,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.marker,
    required this.label,
    required this.style,
  });

  final Widget marker;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
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
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final fret in [6, 7, 8, 9, 10, 11])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _CapoChip(
                    label: '$fret',
                    selected: value == fret,
                    onTap: () => onChanged(fret),
                    theme: theme,
                  ),
                ),
              ),
          ],
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

/// Compact variant selector button that appears directly on the app bar / toolbar.
class _ToolbarVariantButton extends StatelessWidget {
  const _ToolbarVariantButton({
    required this.versions,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ChordProVersion> versions;
  final String selectedId;
  final void Function(String id) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final current = versions.firstWhere(
      (v) => v.id == selectedId,
      orElse: () => versions.first,
    );

    return PopupMenuButton<String>(
      tooltip: l10n.songVariantTooltip(current.name),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final version in versions)
          PopupMenuItem<String>(
            value: version.id,
            child: Row(
              children: [
                if (version.id == selectedId)
                  Icon(LucideIcons.check, size: 18, color: theme.colorScheme.primary)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(
                  version.name,
                  style: TextStyle(
                    fontWeight: version.id == selectedId
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: version.id == selectedId
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.7,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.gitFork,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  current.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip selector used inside [SongControlsSheet] for service song variants.
class _ToolbarVariantChips extends StatelessWidget {
  const _ToolbarVariantChips({
    required this.versions,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ChordProVersion> versions;
  final String selectedId;
  final void Function(String id) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final version in versions)
          ChoiceChip(
            label: Text(version.name),
            selected: version.id == selectedId,
            onSelected: (_) => onSelected(version.id),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: version.id == selectedId
                  ? FontWeight.w700
                  : FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
