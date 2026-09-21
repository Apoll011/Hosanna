import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/sync_status_banner.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/domain/library_controller.dart';
import '../data/folder_repository.dart';
import '../domain/folder_explorer_controller.dart';

/// File-explorer style browser for the song library's folders.
///
/// The root level lists the top-level folders together with any songs that
/// live outside a folder; tapping a folder drills into it, showing its
/// subfolders and the songs directly inside it. A breadcrumb trail (and the
/// back button) walks back up the hierarchy.
class FolderBrowserPage extends ConsumerWidget {
  const FolderBrowserPage({super.key});

  Future<void> _refresh(WidgetRef ref) =>
      ref.read(syncControllerProvider.notifier).syncAll();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folders =
        ref.watch(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];
    final songs =
        ref.watch(songsStreamProvider).valueOrNull ?? const <SongRow>[];
    final currentId = ref.watch(folderExplorerProvider);

    final byId = {for (final f in folders) f.id: f};
    // Fall back to the root when the selected folder no longer exists (e.g. it
    // was deleted or trashed by a sync).
    final current = currentId == null ? null : byId[currentId];
    final activeId = current?.id;

    // Breadcrumb path, root first.
    final path = <FolderRow>[];
    var node = current;
    while (node != null) {
      path.insert(0, node);
      final parentId = node.parentId;
      node = parentId == null ? null : byId[parentId];
    }

    final childFolders = folders.where((f) => f.parentId == activeId).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final childSongs = songs.where((s) => s.folderId == activeId).toList()
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

    final explorer = ref.read(folderExplorerProvider.notifier);
    final isEmpty = childFolders.isEmpty && childSongs.isEmpty;

    return PopScope(
      // Inside a folder, back walks up the hierarchy instead of leaving the
      // branch.
      canPop: activeId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        explorer.open(current?.parentId);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: activeId == null
              ? const ShellLeadingButton()
              : IconButton(
                  icon: const BackButtonIcon(),
                  tooltip: l10n.commonBack,
                  onPressed: () => explorer.open(current?.parentId),
                ),
          title: Text(
            current?.name ?? l10n.foldersTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SyncStatusBanner(compact: true),
              ),
            ),
            if (path.isNotEmpty) _Breadcrumbs(path: path),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(ref),
                child: isEmpty
                    ? _Empty(
                        message: l10n.foldersEmpty,
                        onRefresh: () => _refresh(ref),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          for (final folder in childFolders)
                            _FolderTile(
                              folder: folder,
                              subfolderCount: folders
                                  .where((f) => f.parentId == folder.id)
                                  .length,
                              onOpen: () => explorer.open(folder.id),
                            ),
                          if (childFolders.isNotEmpty && childSongs.isNotEmpty)
                            const Divider(height: 1),
                          for (final song in childSongs)
                            _SongTile(
                              song: song,
                              onOpen: () {
                                ref
                                    .read(libraryControllerProvider.notifier)
                                    .markPlayed(song.id);
                                context.push('/songs/${song.id}');
                              },
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal, scrollable trail from the root to the current folder.
class _Breadcrumbs extends ConsumerWidget {
  const _Breadcrumbs({required this.path});

  final List<FolderRow> path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final explorer = ref.read(folderExplorerProvider.notifier);

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            _Crumb(
              label: l10n.foldersRoot,
              onTap: () => explorer.open(null),
            ),
            for (final folder in path) ...[
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _Crumb(
                label: folder.name,
                onTap: () => explorer.open(folder.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// A folder row; tapping it drills into the folder.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.subfolderCount,
    required this.onOpen,
  });

  final FolderRow folder;
  final int subfolderCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtitle = [
      l10n.foldersSongsCount(folder.songCount),
      if (subfolderCount > 0) l10n.foldersSubfolders,
    ].join(' · ');

    return ListTile(
      leading: Icon(Icons.folder, color: theme.colorScheme.primary),
      title: Text(
        folder.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onOpen,
    );
  }
}

/// A song row inside the current folder; tapping it opens the song reader.
class _SongTile extends StatelessWidget {
  const _SongTile({required this.song, required this.onOpen});

  final SongRow song;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SongBadge(songNumber: song.songNumber),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onOpen,
    );
  }
}

/// Leading badge for a song row: shows the song number when present,
/// otherwise falls back to a music note icon.
class _SongBadge extends StatelessWidget {
  const _SongBadge({required this.songNumber});

  final int? songNumber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      alignment: Alignment.center,
      child: songNumber != null
          ? Text(
              '#$songNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            )
          : Icon(Icons.music_note, size: 18, color: colorScheme.secondary),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
