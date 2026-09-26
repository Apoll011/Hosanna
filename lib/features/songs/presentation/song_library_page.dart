import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shell_insets.dart';
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
    final collectionIdsBySongId = collectionIdsBySongIdFrom(collections);

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _search,
                autofocus: true,
                style: Theme.of(context).textTheme.titleLarge,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.songsSearchHint,
                  hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
          if (!_settings.isDefault)
            _buildActiveFilterChips(folderNames, collectionNames),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (songsAsync) {
                AsyncValue(hasError: true) => ErrorState(
                    title: l10n.commonError,
                    description: l10n.commonErrorDesc,
                    retryLabel: l10n.commonRetry,
                    onRetry: _refresh,
                    scrollable: true,
                  ),
                AsyncValue(:final value?) => _songList(
                    songs: _applySectionAndFilters(
                      value,
                      library,
                      folderNames,
                      collectionSongIds,
                      collectionIdsBySongId,
                    ),
                    folderNames: folderNames,
                    favorites: library.favoriteIds,
                    library: library,
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
    final collectionOptions = <({String id, String name})>[
      for (final c in ref.read(collectionsStreamProvider).valueOrNull ??
          const <CollectionRow>[])
        (id: c.id, name: c.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // The collection filter is left out when the page is already scoped to a
    // single collection.
    showSongFilterSheet(
      context,
      initial: _settings,
      tagOptions: tagOptionsFrom(songs),
      folderOptions: folderOptions,
      collectionOptions: collectionOptions,
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
      showCollectionFilter:
          ref.read(libraryControllerProvider).section !=
              LibrarySection.collection,
    );
  }

  List<SongRow> _applySectionAndFilters(
    List<SongRow> songs,
    LibraryState library,
    Map<String, String> folderNames,
    Map<String, List<String>> collectionSongIds,
    Map<String, Set<String>> collectionIdsBySongId,
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
      collectionIdsBySongId: collectionIdsBySongId,
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

  void _resetFilters() {
    setState(() => _settings = const FilterSettings());
  }

  Widget _songList({
    required List<SongRow> songs,
    required Map<String, String> folderNames,
    required List<String> favorites,
    required LibraryState library,
    required ValueChanged<String> onToggleFavorite,
    required ValueChanged<String> onOpenSong,
  }) {
    final l10n = AppLocalizations.of(context);
    if (songs.isEmpty) {
      return _buildEmpty(l10n, library);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: shellBottomContentPadding(context)),
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
              color: isFav ? Theme.of(context).colorScheme.error : null,
            ),
            tooltip: isFav ? l10n.navFavorites : l10n.navFavorites,
            onPressed: () => onToggleFavorite(song.id),
          ),
          onTap: () => onOpenSong(song.id),
        );
      },
    );
  }

  Widget _buildEmpty(AppLocalizations l10n, LibraryState library) {
    final hasFilters = !_settings.isDefault || _search.text.trim().isNotEmpty;

    if (hasFilters) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: l10n.songsNoResults,
        description: l10n.songsNoResultsDesc,
        primaryLabel: l10n.songsClearFilters,
        primaryIcon: Icons.filter_alt_off_outlined,
        onPrimary: () {
          _search.clear();
          _resetFilters();
          if (_searchOpen) setState(() => _searchOpen = false);
        },
        scrollable: true,
      );
    }

    return switch (library.section) {
      LibrarySection.favorites => EmptyState(
          icon: Icons.favorite_border,
          title: l10n.songsFavoritesEmpty,
          description: l10n.songsFavoritesEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.recent => EmptyState(
          icon: Icons.history,
          title: l10n.songsRecentsEmpty,
          description: l10n.songsRecentsEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.folder ||
      LibrarySection.collection =>
        EmptyState(
          icon: Icons.music_note_outlined,
          title: l10n.songsEmpty,
          description: l10n.songsEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.all => EmptyState(
          icon: Icons.library_music_outlined,
          title: l10n.songsEmpty,
          description: l10n.songsEmptyDesc,
          scrollable: true,
        ),
    };
  }
}
