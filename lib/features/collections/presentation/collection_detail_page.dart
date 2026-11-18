import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/design/tokens.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bar_search_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hosanna_surface.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../../folders/data/folder_repository.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/domain/library_controller.dart';
import '../../songs/presentation/song_filter_widgets.dart';
import '../../songs/presentation/song_filters.dart';
import '../data/collection_repository.dart';
import 'collection_visuals.dart';

/// Songs inside one collection — same list patterns as the library, with a
/// small identity header (cover / accent / description).
class CollectionDetailPage extends ConsumerStatefulWidget {
  const CollectionDetailPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState extends ConsumerState<CollectionDetailPage> {
  final _search = TextEditingController();
  FilterSettings _settings = const FilterSettings();
  bool _searchOpen = false;

  List<SongRow>? _metaCacheSongs;
  Map<String, SongMeta> _metaBySongId = const {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  void _resetFilters() {
    setState(() => _settings = const FilterSettings());
  }

  void _clearSearch() {
    setState(() {
      _search.clear();
      _searchOpen = false;
    });
  }

  List<SongRow> _orderedSongs(List<SongRow> songs, List<String> songIds) {
    final byId = {for (final s in songs) s.id: s};
    return [for (final id in songIds) ?byId[id]];
  }

  void _openFilterSheet() {
    final songs =
        ref.read(songsStreamProvider).valueOrNull ?? const <SongRow>[];
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
      collectionOptions: const [],
      keyOptions: keyOptionsFrom(_metaBySongId),
      onChanged: (next) => setState(() => _settings = next),
      showFolderFilter: true,
      showCollectionFilter: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final collection = ref
        .watch(collectionStreamProvider(widget.collectionId))
        .valueOrNull;
    final songs =
        ref.watch(songsStreamProvider).valueOrNull ?? const <SongRow>[];
    final folders =
        ref.watch(foldersStreamProvider).valueOrNull ?? const <FolderRow>[];
    final collections =
        ref.watch(collectionsStreamProvider).valueOrNull ??
        const <CollectionRow>[];
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);

    if (!identical(_metaCacheSongs, songs)) {
      _metaCacheSongs = songs;
      _metaBySongId = extractSongMetaById(songs);
    }

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.navCollections),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: l10n.commonBack,
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          illustrationAsset: HosannaIllustrations.emptyFolders,
          title: l10n.collectionsEmpty,
          description: l10n.collectionsEmptyDesc,
          scrollable: true,
        ),
      );
    }

    final folderNames = {for (final f in folders) f.id: f.name};
    final collectionNames = {for (final c in collections) c.id: c.name};
    final collectionIdsBySongId = collectionIdsBySongIdFrom(collections);
    final ordered = _orderedSongs(songs, collection.songIds);
    final visible = applySongFilters(
      ordered,
      settings: _settings,
      query: _search.text,
      metaBySongId: _metaBySongId,
      folderNames: folderNames,
      collectionIdsBySongId: collectionIdsBySongId,
    );
    final hasQuery = _search.text.trim().isNotEmpty;
    final hasFilters = !_settings.isDefault || hasQuery;
    final description = collection.description?.trim();
    final image = collectionImageProvider(collection.image);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: l10n.commonBack,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/collections');
            }
          },
        ),
        title: _searchOpen
            ? AppBarSearchField(
                controller: _search,
                hintText: l10n.songsSearchHint,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => setState(() {}),
              )
            : Text(
                collection.name,
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
        ],
      ),
      body: Column(
        children: [
          if (!_settings.isDefault)
            ActiveFilterChips(
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
                  selectedFolders: {..._settings.selectedFolders}
                    ..remove(folderId),
                );
              }),
              onRemoveCollection: (_) {},
              onRemoveKey: (key) => setState(() {
                _settings = _settings.copyWith(
                  selectedKeys: {..._settings.selectedKeys}..remove(key),
                );
              }),
              onSongNumberAny: () => setState(() {
                _settings = _settings.copyWith(
                  songNumberFilter: SongNumberFilter.any,
                );
              }),
              onLyricsOff: () => setState(() {
                _settings = _settings.copyWith(searchLyrics: false);
              }),
              onChordsOff: () => setState(() {
                _settings = _settings.copyWith(withChordsOnly: false);
              }),
              onReset: _resetFilters,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: visible.isEmpty
                  ? (hasFilters
                        ? EmptyState(
                            illustrationAsset:
                                HosannaIllustrations.emptySearch,
                            title: l10n.songsNoResults,
                            description: l10n.songsNoResultsDesc,
                            primaryLabel: hasQuery
                                ? l10n.songsClearSearch
                                : l10n.songsClearFilters,
                            primaryIcon: hasQuery
                                ? Icons.search_off_outlined
                                : Icons.filter_alt_off_outlined,
                            onPrimary: hasQuery
                                ? _clearSearch
                                : _resetFilters,
                            scrollable: true,
                          )
                        : EmptyState(
                            illustrationAsset:
                                HosannaIllustrations.emptyFolders,
                            title: l10n.collectionContentsEmpty,
                            description:
                                l10n.collectionContentsEmptyReadonlyDesc,
                            scrollable: true,
                          ))
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        HosannaSpacing.md,
                        HosannaSpacing.xs,
                        HosannaSpacing.md,
                        shellBottomContentPadding(context),
                      ),
                      itemCount: visible.length + 1,
                      separatorBuilder: (_, index) => index == 0
                          ? const SizedBox(height: HosannaSpacing.sm)
                          : const SizedBox(height: HosannaSpacing.xs),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CollectionHeader(
                            collection: collection,
                            image: image,
                            description: description,
                            songCountLabel: l10n.foldersSongsCount(
                              collection.songCount,
                            ),
                          );
                        }
                        final song = visible[index - 1];
                        final folder = song.folderId == null
                            ? null
                            : folderNames[song.folderId];
                        final isFav = library.favoriteIds.contains(song.id);
                        final meta = _metaBySongId[song.id];
                        final metaBits = <String>[
                          if (song.artist.isNotEmpty) song.artist,
                          if (meta?.key != null && meta!.key!.isNotEmpty)
                            meta.key!,
                          if (folder != null && folder.isNotEmpty) folder,
                        ];
                        return HosannaSurface(
                          elevated: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: HosannaSpacing.sm,
                            vertical: HosannaSpacing.xs,
                          ),
                          onTap: () {
                            libraryController.markPlayed(song.id);
                            context.push('/songs/${song.id}');
                          },
                          child: Row(
                            children: [
                              SongBadge(songNumber: song.songNumber),
                              const SizedBox(width: HosannaSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (metaBits.isNotEmpty)
                                      Text(
                                        metaBits.join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : null,
                                ),
                                tooltip: l10n.navFavorites,
                                onPressed: () =>
                                    libraryController.toggleFavorite(song.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.collection,
    required this.image,
    required this.description,
    required this.songCountLabel,
  });

  final CollectionRow collection;
  final ImageProvider? image;
  final String? description;
  final String songCountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HosannaSurface(
      elevated: false,
      padding: const EdgeInsets.all(HosannaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(HosannaRadii.sm),
              child: Image(
                image: image!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CollectionAccentBadge(
                  colorId: collection.color,
                  iconId: collection.icon,
                  size: 64,
                ),
              ),
            )
          else
            CollectionAccentBadge(
              colorId: collection.color,
              iconId: collection.icon,
              size: 64,
            ),
          const SizedBox(width: HosannaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  songCountLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
