import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/domain/library_controller.dart';
import '../../songs/presentation/song_filter_widgets.dart';
import '../../songs/presentation/song_filters.dart';
import '../data/folder_repository.dart';
import '../domain/folder_explorer_controller.dart';

/// File-explorer style browser for the song library's folders.
///
/// The root level lists the top-level folders together with any songs that
/// live outside a folder; tapping a folder drills into it, showing its
/// subfolders and the songs directly inside it. A breadcrumb trail (and the
/// back button) walks back up the hierarchy.
///
/// The search field matches folder names and songs (title, artist, tags…),
/// while the filter sheet narrows the songs down by tag, key, song number and
/// chords. Both the list and a card grid layout are supported.
class FolderBrowserPage extends ConsumerStatefulWidget {
  const FolderBrowserPage({super.key});

  @override
  ConsumerState<FolderBrowserPage> createState() => _FolderBrowserPageState();
}

class _FolderBrowserPageState extends ConsumerState<FolderBrowserPage> {
  final _search = TextEditingController();
  FilterSettings _settings = const FilterSettings();
  bool _searchOpen = false;
  bool _gridView = false;

  /// Cache of parsed content metadata, rebuilt only when the songs list
  /// reference changes (i.e. after a sync), so filtering stays cheap.
  List<SongRow>? _metaCacheSongs;
  Map<String, SongMeta> _metaBySongId = const {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folders =
        ref.watch(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];
    final songs =
        ref.watch(songsStreamProvider).valueOrNull ?? const <SongRow>[];
    final currentId = ref.watch(folderExplorerProvider);

    if (!identical(_metaCacheSongs, songs)) {
      _metaCacheSongs = songs;
      _metaBySongId = extractSongMetaById(songs);
    }

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

    final folderNames = {for (final f in folders) f.id: f.name};
    final query = _search.text.trim().toLowerCase();
    final childFolders = folders.where((f) => f.parentId == activeId).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final visibleFolders = query.isEmpty
        ? childFolders
        : childFolders
              .where((f) => f.name.toLowerCase().contains(query))
              .toList();
    final visibleSongs = applySongFilters(
      songs.where((s) => s.folderId == activeId),
      settings: _settings,
      query: _search.text,
      metaBySongId: _metaBySongId,
      folderNames: folderNames,
    );

    final explorer = ref.read(folderExplorerProvider.notifier);
    final isEmpty = visibleFolders.isEmpty && visibleSongs.isEmpty;
    final hasQuery = query.isNotEmpty;

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
          title: _searchOpen
              ? TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.songsSearchHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => setState(() {}),
                )
              : Text(
                  current?.name ?? l10n.foldersTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            IconButton(
              icon: Icon(_searchOpen ? Icons.close : Icons.search),
              tooltip: l10n.commonSearch,
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _search.clear();
                });
              },
            ),
            SongFilterButton(
              activeCount: _settings.activeFilterCount,
              onPressed: _openFilterSheet,
            ),
            // Long-press-free toggle between the compact list and the card
            // grid built for tablet/desktop folders.
            IconButton(
              icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
              tooltip: _gridView ? l10n.foldersViewList : l10n.foldersViewGrid,
              onPressed: () => setState(() => _gridView = !_gridView),
            ),
          ],
        ),
        body: Column(
          children: [
            if (path.isNotEmpty) _Breadcrumbs(path: path),
            if (!_settings.isDefault) _buildActiveFilterChips(folderNames),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: isEmpty
                    ? _Empty(
                        message: hasQuery || !_settings.isDefault
                            ? l10n.songsNoResults
                            : l10n.foldersEmpty,
                        onRefresh: _refresh,
                        onClear: hasQuery
                            ? _clearSearch
                            : (_settings.isDefault ? null : _resetFilters),
                        clearLabel: hasQuery
                            ? l10n.songsClearSearch
                            : l10n.songsClearFilters,
                      )
                    : _gridView
                    ? _BrowserGrid(
                        entries: _entries(visibleFolders, visibleSongs),
                        onOpenFolder: explorer.open,
                        onOpenSong: _openSong,
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          for (final folder in visibleFolders)
                            _FolderTile(
                              folder: folder,
                              subfolderCount: folders
                                  .where((f) => f.parentId == folder.id)
                                  .length,
                              onOpen: () => explorer.open(folder.id),
                            ),
                          if (visibleFolders.isNotEmpty &&
                              visibleSongs.isNotEmpty)
                            const Divider(height: 1),
                          for (final song in visibleSongs)
                            _SongTile(
                              song: song,
                              onOpen: () => _openSong(song),
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

  /// Folders first, then songs — the order both layouts render them in.
  List<_BrowserEntry> _entries(
    List<FolderRow> folders,
    List<SongRow> songs,
  ) {
    return [
      for (final folder in folders) _FolderEntry(folder),
      for (final song in songs) _SongEntry(song),
    ];
  }

  void _openSong(SongRow song) {
    ref.read(libraryControllerProvider.notifier).markPlayed(song.id);
    context.push('/songs/${song.id}');
  }

  void _clearSearch() {
    setState(() {
      _search.clear();
      _searchOpen = false;
    });
  }

  void _resetFilters() {
    setState(() => _settings = const FilterSettings());
  }

  void _openFilterSheet() {
    final songs =
        ref.read(songsStreamProvider).valueOrNull ?? const <SongRow>[];
    final folders =
        ref.read(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];
    final folderOptions = <({String id, String name})>[
      for (final f in folders) (id: f.id, name: f.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // The folder filter is left out: this page is already scoped to the folder
    // you drilled into.
    showSongFilterSheet(
      context,
      initial: _settings,
      tagOptions: tagOptionsFrom(songs),
      folderOptions: folderOptions,
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
      showFolderFilter: false,
    );
  }

  Widget _buildActiveFilterChips(Map<String, String> folderNames) {
    return ActiveFilterChips(
      settings: _settings,
      folderNames: folderNames,
      onOpenFilters: _openFilterSheet,
      onRemoveTag: (tag) => setState(() {
        _settings = _settings.copyWith(
          selectedTags: {..._settings.selectedTags}..remove(tag),
        );
      }),
      onRemoveFolder: (folderId) => setState(() {
        _settings = _settings.copyWith(
          selectedFolders: {..._settings.selectedFolders}..remove(folderId),
        );
      }),
      onRemoveKey: (key) => setState(() {
        _settings = _settings.copyWith(
          selectedKeys: {..._settings.selectedKeys}..remove(key),
        );
      }),
      onSongNumberAny: () => setState(() {
        _settings = _settings.copyWith(songNumberFilter: SongNumberFilter.any);
      }),
      onLyricsOff: () => setState(() {
        _settings = _settings.copyWith(searchLyrics: false);
      }),
      onChordsOff: () => setState(() {
        _settings = _settings.copyWith(withChordsOnly: false);
      }),
      onReset: _resetFilters,
    );
  }
}

/// One cell of the folder browser grid: either a subfolder or a song.
sealed class _BrowserEntry {
  const _BrowserEntry();
}

class _FolderEntry extends _BrowserEntry {
  const _FolderEntry(this.folder);

  final FolderRow folder;
}

class _SongEntry extends _BrowserEntry {
  const _SongEntry(this.song);

  final SongRow song;
}

/// Card grid layout for the folder browser (used on wider screens or when the
/// user prefers cards over the dense list).
class _BrowserGrid extends StatelessWidget {
  const _BrowserGrid({
    required this.entries,
    required this.onOpenFolder,
    required this.onOpenSong,
  });

  final List<_BrowserEntry> entries;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<SongRow> onOpenSong;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 96,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        _FolderEntry(:final folder) => _FolderCard(
          folder: folder,
          onOpen: () => onOpenFolder(folder.id),
        ),
        _SongEntry(:final song) => _SongCard(
          song: song,
          onOpen: () => onOpenSong(song),
        ),
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.onOpen});

  final FolderRow folder;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.folder, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            l10n.foldersSongsCount(folder.songCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({required this.song, required this.onOpen});

  final SongRow song;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SongBadge(songNumber: song.songNumber),
          const SizedBox(height: 4),
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
            _Crumb(label: l10n.foldersRoot, onTap: () => explorer.open(null)),
            for (final folder in path) ...[
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _Crumb(label: folder.name, onTap: () => explorer.open(folder.id)),
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
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      leading: SongBadge(songNumber: song.songNumber),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onOpen,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.message,
    required this.onRefresh,
    this.clearLabel,
    this.onClear,
  });

  final String message;
  final Future<void> Function() onRefresh;
  final String? clearLabel;
  final VoidCallback? onClear;

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
                if (onClear != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_alt_off),
                    label: Text(clearLabel!),
                  ),
                ],
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
