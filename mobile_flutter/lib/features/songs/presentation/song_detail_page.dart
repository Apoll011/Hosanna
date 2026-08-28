import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/song_repository.dart';
import 'chordpro/song_display_settings.dart';
import 'song_body_renderer.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  const SongDetailPage({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  @override
  void initState() {
    super.initState();
    // Keep the screen awake while viewing a song.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));
    final song = songAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(song?.title ?? l10n.songsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.navExportPdf,
            onPressed: () => context.go('/export-pdf'),
          ),
        ],
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (song) => song == null
            ? Center(child: Text(l10n.songsNoResults))
            : Column(
                children: [
                  const _SongToolbar(),
                  const Divider(height: 1),
                  Expanded(child: SongBodyRenderer(content: song.content)),
                ],
              ),
      ),
    );
  }
}

/// Transpose / capo / font / chord-visibility / instrument / diagrams controls.
class _SongToolbar extends ConsumerWidget {
  const _SongToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(songDisplaySettingsProvider);
    final controller = ref.read(songDisplaySettingsProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _Stepper(
            label: l10n.songKey,
            value: settings.transpose,
            onDec: () => controller.setTranspose(settings.transpose - 1),
            onInc: () => controller.setTranspose(settings.transpose + 1),
          ),
          const SizedBox(width: 8),
          if (settings.isGuitar)
            _Stepper(
              label: l10n.songCapo,
              value: settings.capo,
              onDec: () => controller.setCapo(settings.capo - 1),
              onInc: () => controller.setCapo(settings.capo + 1),
            ),
          if (settings.isGuitar) const SizedBox(width: 8),
          _Stepper(
            label: 'A',
            value: settings.fontSize.toInt(),
            onDec: () => controller.setFontSize(settings.fontSize - 1),
            onInc: () => controller.setFontSize(settings.fontSize + 1),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.songChords,
            icon: const Icon(Icons.music_note),
            color: settings.showChords
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: controller.toggleShowChords,
          ),
          IconButton(
            tooltip: l10n.songInstrument,
            icon: Icon(settings.isGuitar ? Icons.piano : Icons.graphic_eq),
            onPressed: () => controller.setInstrument(
              settings.isGuitar ? 'piano' : 'guitar',
            ),
          ),
          IconButton(
            tooltip: l10n.songDiagrams,
            icon: const Icon(Icons.grid_on),
            color: settings.showDiagrams
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: controller.toggleDiagrams,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
  });

  final String label;
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onDec,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text('$value', style: theme.textTheme.titleSmall),
            ],
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: onInc,
          ),
        ],
      ),
    );
  }
}
