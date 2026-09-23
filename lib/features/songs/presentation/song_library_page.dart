import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../collections/data/collection_repository.dart';
import '../../folders/data/folder_repository.dart';
import '../data/song_repository.dart';
import '../domain/library_controller.dart';
import 'song_filter_widgets.dart';
import 'song_filters.dart';

class SongLibraryPage extends ConsumerStatefulWidget {
  const SongLibraryPage({super.key});

  @override
  ConsumerState<SongLibraryPage> createState() => _SongLibraryPageState();
}

class _SongLibraryPageState extends ConsumerState<SongLibraryPage> {
  final _search = TextEditingController();
  FilterSettings _settings = const FilterSettings();
  bool _searchOpen = false;

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
    final songsAsync = ref.watch(songsStreamProvider);
    final foldersAsync = ref.watch(foldersStreamProvider);
    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);

    final songs = songsAsync.valueOrNull ?? const <SongRow>[];
    if (!identical(_metaCacheSongs, songs)) {
      _metaCacheSongs = songs;
      _metaBySongId = extractSongMetaById(songs);
    }

    final folders = foldersAsync.valueOrNull ?? const <FolderRow>[];
    final folderNames = {for (final f in folders) f.id: f.name};
    final collections =
        collectionsAsync.valueOrNull ?? const <CollectionRow>[];
    final collectionNames = {for (final c in collections) c.id: c.name};
    final collectionSongIds = {
      for (final c in collections) c.id: c.songIds,
    };

    return Scaffold(
      appBar: AppBar(
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
                _sectionTitle(l10n, library, folderNames, collectionNames),
              ),
        leading: const ShellLeadingButton(),
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
        ],
      ),
      body: Column(
        children: [
          if (!_settings.isDefault) _buildActiveFilterChips(folderNames),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (songsAsync) {
                AsyncValue(hasError: true) => _EmptyState(
                    message: l10n.commonError,
                    onRetry: _refresh,
                  ),
                AsyncValue(:final value?) => _songList(
                    songs: _applySectionAndFilters(
                      value,
                      library,
                      folderNames,
                      collectionSongIds,
                    ),
                    folderNames: folderNames,
                    favorites: library.favoriteIds,
                    onToggleFavorite: libraryController.toggleFavorite,
                    onOpenSong: (id) {
                      libraryController.markPlayed(id);
                      context.push('/songs/$id');
                    },
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(
    AppLocalizations l10n,
    LibraryState library,
    Map<String, String> folderNames,
    Map<String, String> collectionNames,
  ) {
    return switch (library.section) {
      LibrarySection.all => l10n.navAllSongs,
      LibrarySection.favorites => l10n.navFavorites,
      LibrarySection.recent => l10n.navRecents,
      LibrarySection.folder =>
        folderNames[library.folderId] ?? l10n.navFolders,
      LibrarySection.collection =>
        collectionNames[library.collectionId] ?? l10n.navCollections,
    };
  }

  void _openFilterSheet() {
    final songs = ref.read(songsStreamProvider).valueOrNull ??
        const <SongRow>[];
    final folders =
        ref.read(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];
    final folderOptions = <({String id, String name})>[
      for (final f in folders) (id: f.id, name: f.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showSongFilterSheet(
      context,
      initial: _settings,
      tagOptions: tagOptionsFrom(songs),
      folderOptions: folderOptions,
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
    );
  }

  List<SongRow> _applySectionAndFilters(
    List<SongRow> songs,
    LibraryState library,
    Map<String, String> folderNames,
    Map<String, List<String>> collectionSongIds,
  ) {
    final sectionSongs = switch (library.section) {
      LibrarySection.favorites =>
        songs.where((s) => library.favoriteIds.contains(s.id)),
      LibrarySection.recent => _recentSongs(songs, library.recentIds),
      LibrarySection.folder =>
        songs.where((s) => s.folderId == library.folderId),
      LibrarySection.collection => _collectionSongs(
        songs,
        collectionSongIds[library.collectionId] ?? const [],
      ),
      LibrarySection.all => songs,
    };

    return applySongFilters(
      sectionSongs,
      settings: _settings,
      query: _search.text,
      metaBySongId: _metaBySongId,
      folderNames: folderNames,
    );
  }

  /// Songs belonging to a collection, ordered exactly as the collection lists
  /// its `songIds` (missing ids are skipped, e.g. after a song was removed).
  List<SongRow> _collectionSongs(List<SongRow> songs, List<String> songIds) {
    final byId = {for (final s in songs) s.id: s};
    return [
      for (final id in songIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<SongRow> _recentSongs(List<SongRow> songs, List<String> recentIds) {
    final byId = {for (final s in songs) s.id: s};
    return [
      for (final id in recentIds)
        if (byId[id] != null) byId[id]!,
    ];
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

  void _resetFilters() {
    setState(() => _settings = const FilterSettings());
  }

  Widget _songList({
    required List<SongRow> songs,
    required Map<String, String> folderNames,
    required List<String> favorites,
    required ValueChanged<String> onToggleFavorite,
    required ValueChanged<String> onOpenSong,
  }) {
    final l10n = AppLocalizations.of(context);
    if (songs.isEmpty) {
      return _EmptyState(
        message: l10n.songsNoResults,
        onRetry: _refresh,
        onClearFilters: _settings.isDefault ? null : _resetFilters,
        clearLabel: l10n.songsClearFilters,
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final folder = song.folderId == null
            ? null
            : folderNames[song.folderId];
        final isFav = favorites.contains(song.id);
        return ListTile(
          leading: SongBadge(songNumber: song.songNumber),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              song.artist,
              ?folder,
              if (song.tags.isNotEmpty) song.tags.join(', '),
            ].where((e) => e.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.pink : null,
            ),
            tooltip: l10n.navFavorites,
            onPressed: () => onToggleFavorite(song.id),
          ),
          onTap: () => onOpenSong(song.id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onRetry,
    this.clearLabel,
    this.onClearFilters,
  });

  final String message;
  final Future<void> Function() onRetry;
  final String? clearLabel;
  final VoidCallback? onClearFilters;

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
                if (onClearFilters != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.filter_alt_off),
                    label: Text(clearLabel!),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
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
