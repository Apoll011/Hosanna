import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/design/tokens.dart';
import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hosanna_surface.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../../../shared/widgets/shell_modal.dart';
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

  void _openAiImport() {
    final library = ref.read(libraryControllerProvider);
    final folderId = library.section == LibrarySection.folder
        ? library.folderId
        : null;
    if (folderId == null) {
      context.push('/songs/import/ai');
      return;
    }
    context.push('/songs/import/ai?folderId=$folderId');
  }

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
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.songsNewSong,
            onPressed: _showNewSongSheet,
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
                    illustrationAsset: HosannaIllustrations.stateError,
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

    // Folder/collection filters are contextual: hidden on the main library,
    // folder filter only when browsing a collection, collection filter only
    // when browsing a folder.
    final section = ref.read(libraryControllerProvider).section;
    showSongFilterSheet(
      context,
      initial: _settings,
      tagOptions: tagOptionsFrom(songs),
      folderOptions: folderOptions,
      collectionOptions: collectionOptions,
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
      showFolderFilter: section == LibrarySection.collection,
      showCollectionFilter: section == LibrarySection.folder,
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

  Future<void> _showNewSongSheet() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = HosannaTokens.of(context);
    await showShellModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.songsNewSong,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: HosannaSpacing.md),
                HosannaSurface(
                  elevated: false,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/songs/new');
                  },
                  child: Row(
                    children: [
                      HosannaLeadingBadge(icon: Icons.edit_outlined),
                      const SizedBox(width: HosannaSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.songsCreateManually,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.songsCreateManuallyDesc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HosannaSpacing.sm),
                HosannaSurface(
                  elevated: false,
                  selected: true,
                  color: tokens.selectedNav,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAiImport();
                  },
                  child: Row(
                    children: [
                      HosannaLeadingBadge(
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(width: HosannaSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.songsImportWithAi,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.songsImportWithAiDesc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final theme = Theme.of(context);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        HosannaSpacing.md,
        HosannaSpacing.xs,
        HosannaSpacing.md,
        shellBottomContentPadding(context),
      ),
      itemCount: songs.length,
      separatorBuilder: (_, _) => const SizedBox(height: HosannaSpacing.xs),
      itemBuilder: (context, index) {
        final song = songs[index];
        final folder = song.folderId == null
            ? null
            : folderNames[song.folderId];
        final isFav = favorites.contains(song.id);
        final meta = _metaBySongId[song.id];
        final metaBits = <String>[
          if (song.artist.isNotEmpty) song.artist,
          if (meta?.key != null && meta!.key!.isNotEmpty) meta.key!,
          if (folder != null && folder.isNotEmpty) folder,
        ];
        return HosannaSurface(
          elevated: false,
          padding: const EdgeInsets.symmetric(
            horizontal: HosannaSpacing.sm,
            vertical: HosannaSpacing.xs,
          ),
          onTap: () => onOpenSong(song.id),
          child: Row(
            children: [
              SongBadge(songNumber: song.songNumber),
              const SizedBox(width: HosannaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (metaBits.isNotEmpty)
                      Text(
                        metaBits.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? theme.colorScheme.primary : null,
                ),
                tooltip: l10n.navFavorites,
                onPressed: () => onToggleFavorite(song.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(AppLocalizations l10n, LibraryState library) {
    final hasFilters = !_settings.isDefault || _search.text.trim().isNotEmpty;

    if (hasFilters) {
      return EmptyState(
        illustrationAsset: HosannaIllustrations.emptySearch,
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
          illustrationAsset: HosannaIllustrations.emptyFavorites,
          title: l10n.songsFavoritesEmpty,
          description: l10n.songsFavoritesEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.recent => EmptyState(
          illustrationAsset: HosannaIllustrations.emptySongs,
          title: l10n.songsRecentsEmpty,
          description: l10n.songsRecentsEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.folder ||
      LibrarySection.collection =>
        EmptyState(
          illustrationAsset: HosannaIllustrations.emptyFolders,
          title: l10n.songsEmpty,
          description: l10n.songsEmptyDesc,
          scrollable: true,
        ),
      LibrarySection.all => EmptyState(
          illustrationAsset: HosannaIllustrations.emptySongs,
          title: l10n.songsEmpty,
          description: l10n.songsEmptyAddHint,
          primaryLabel: l10n.songsAddSong,
          primaryIcon: Icons.add_rounded,
          onPrimary: _showNewSongSheet,
          secondaryLabel: l10n.songsImportWithAi,
          onSecondary: _openAiImport,
          scrollable: true,
        ),
    };
  }
}
