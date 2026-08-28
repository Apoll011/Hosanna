import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../folders/data/folder_repository.dart';
import '../data/song_repository.dart';
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
    // Keep the screen awake while viewing a song (v1 requirement).
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
    final folders = ref.watch(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];

    final song = songAsync.valueOrNull;
    String? folderName;
    if (song?.folderId != null) {
      for (final f in folders) {
        if (f.id == song!.folderId) {
          folderName = f.name;
          break;
        }
      }
    }

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
            : _detail(song: song, folderName: folderName),
      ),
    );
  }

  Widget _detail({required SongRow song, required String? folderName}) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (song.artist.isNotEmpty)
                Text(
                  song.artist,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              if (folderName != null || song.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (folderName != null)
                        Chip(
                          avatar: const Icon(Icons.folder_outlined, size: 16),
                          label: Text(folderName),
                        ),
                      for (final tag in song.tags) Chip(label: Text(tag)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SongBodyRenderer(content: song.content),
          ),
        ),
      ],
    );
  }
}
