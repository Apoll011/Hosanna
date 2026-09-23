import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../collections/data/collection_repository.dart';
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
    final collections =
        ref.watch(collectionsStreamProvider).valueOrNull ??
        const <CollectionRow>[];
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
    final collectionNames = {for (final c in collections) c.id: c.name};
    final collectionIdsBySongId = collectionIdsBySongIdFrom(collections);
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
      collectionIdsBySongId: collectionIdsBySongId,
    );
    // Subfolder counts for the currently visible folders — computed once per
    // build so both the list and grid tiles can show "N subfolders" cheaply.
    final subfolderCounts = {
      for (final f in visibleFolders)
        f.id: folders.where((x) => x.parentId == f.id).length,
    };

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
            if (path.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _Breadcrumbs(path: path),
              ),
            if (!_settings.isDefault)
              Align(
                alignment: Alignment.centerLeft,
                child: _buildActiveFilterChips(folderNames, collectionNames),
              ),
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
                        folders: visibleFolders,
                        songs: visibleSongs,
                        subfolderCounts: subfolderCounts,
                        onOpenFolder: explorer.open,
                        onOpenSong: _openSong,
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          for (final folder in visibleFolders)
                            _FolderTile(
                              folder: folder,
                              subfolderCount: subfolderCounts[folder.id] ?? 0,
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
    final collectionOptions = <({String id, String name})>[
      for (final c
          in ref.read(collectionsStreamProvider).valueOrNull ??
              const <CollectionRow>[])
        (id: c.id, name: c.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // The folder filter is left out: this page is already scoped to the folder
    // you drilled into.
    showSongFilterSheet(
      context,
      initial: _settings,
      tagOptions: tagOptionsFrom(songs),
      folderOptions: folderOptions,
      collectionOptions: collectionOptions,
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
      showFolderFilter: false,
    );
  }

  Widget _buildActiveFilterChips(
    Map<String, String> folderNames,
    Map<String, String> collectionNames,
  ) {
    return ActiveFilterChips(
      settings: _settings,
      folderNames: folderNames,
      collectionNames: collectionNames,
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
      onRemoveCollection: (collectionId) => setState(() {
        _settings = _settings.copyWith(
          selectedCollections: {..._settings.selectedCollections}
            ..remove(collectionId),
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

/// A small rounded icon "chip" used as the leading visual for a folder or
/// song, with an optional item-count badge — the same building block backs
/// both the list rows and the grid tiles so switching views feels like one
/// consistent file browser rather than two different UIs.
class _ExplorerIcon extends StatelessWidget {
  const _ExplorerIcon({
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconScale = 0.55,
    this.badgeCount,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconScale;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: color, size: size * iconScale),
    );

    if (badgeCount == null || badgeCount == 0) return chip;
    return Badge(
      label: Text(badgeCount! > 99 ? '99+' : '$badgeCount'),
      alignment: AlignmentDirectional.topEnd,
      offset: const Offset(6, -6),
      backgroundColor: color,
      child: chip,
    );
  }
}

/// Shared icon-grid tile shell (icon on top, label + optional caption below),
/// the layout convention used by desktop/OS file-manager icon views. Reacts
/// to mouse hover on desktop/web while still giving normal touch ripple
/// feedback on mobile.
class _ExplorerTile extends StatefulWidget {
  const _ExplorerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
  });

  final Widget icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;

  @override
  State<_ExplorerTile> createState() => _ExplorerTileState();
}

class _ExplorerTileState extends State<_ExplorerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: _hovered
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.6)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 46, child: Center(child: widget.icon)),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                if (widget.caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-grid layout for the folder browser: folders and songs are grouped
/// into their own grids with a divider between them (mirroring how the list
/// view separates the two), the way a desktop file manager keeps folders
/// ahead of files rather than interleaving them.
class _BrowserGrid extends StatelessWidget {
  const _BrowserGrid({
    required this.folders,
    required this.songs,
    required this.subfolderCounts,
    required this.onOpenFolder,
    required this.onOpenSong,
  });

  final List<FolderRow> folders;
  final List<SongRow> songs;
  final Map<String, int> subfolderCounts;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<SongRow> onOpenSong;

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 108,
    mainAxisExtent: 128,
    crossAxisSpacing: 4,
    mainAxisSpacing: 8,
  );

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (folders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            sliver: SliverGrid(
              gridDelegate: _gridDelegate,
              delegate: SliverChildBuilderDelegate((context, index) {
                final folder = folders[index];
                return _FolderCard(
                  folder: folder,
                  subfolderCount: subfolderCounts[folder.id] ?? 0,
                  onOpen: () => onOpenFolder(folder.id),
                );
              }, childCount: folders.length),
            ),
          ),
        if (folders.isNotEmpty && songs.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Divider(height: 25),
            ),
          ),
        if (songs.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            sliver: SliverGrid(
              gridDelegate: _gridDelegate,
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = songs[index];
                return _SongCard(song: song, onOpen: () => onOpenSong(song));
              }, childCount: songs.length),
            ),
          ),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
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
    final hasContents = folder.songCount > 0 || subfolderCount > 0;

    return _ExplorerTile(
      onTap: onOpen,
      icon: _ExplorerIcon(
        icon: hasContents ? Icons.folder_rounded : Icons.folder_outlined,
        color: theme.colorScheme.primary,
        size: 46,
        iconScale: 0.6,
        badgeCount: folder.songCount,
      ),
      label: folder.name,
      caption: subfolderCount > 0 ? l10n.foldersSubfolders : null,
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
    return _ExplorerTile(
      onTap: onOpen,
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _ExplorerIcon(
            icon: Icons.description_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 46,
            iconScale: 0.55,
          ),
          Positioned(
            bottom: -4,
            right: -8,
            child: Transform.scale(
              scale: 0.72,
              child: SongBadge(songNumber: song.songNumber),
            ),
          ),
        ],
      ),
      label: song.title,
      caption: song.artist,
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
    final hasContents = folder.songCount > 0 || subfolderCount > 0;
    final subtitle = [
      l10n.foldersSongsCount(folder.songCount),
      if (subfolderCount > 0) l10n.foldersSubfolders,
    ].join(' · ');

    return ListTile(
      leading: _ExplorerIcon(
        icon: hasContents ? Icons.folder_rounded : Icons.folder_outlined,
        color: theme.colorScheme.primary,
        badgeCount: folder.songCount,
      ),
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
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: SongBadge(songNumber: song.songNumber)),
      ),
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
