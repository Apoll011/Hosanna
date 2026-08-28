import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../folders/data/folder_repository.dart';
import '../data/song_repository.dart';
import '../domain/library_controller.dart';

enum SongSort { title, artist, updated }

class SongLibraryPage extends ConsumerStatefulWidget {
  const SongLibraryPage({super.key});

  @override
  ConsumerState<SongLibraryPage> createState() => _SongLibraryPageState();
}

class _SongLibraryPageState extends ConsumerState<SongLibraryPage> {
  final _search = TextEditingController();
  SongSort _sort = SongSort.title;
  String? _tagFilter; // null = all tags
  bool _searchOpen = false;

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
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);

    final folders = foldersAsync.valueOrNull ?? const <FolderRow>[];
    final folderNames = {for (final f in folders) f.id: f.name};

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
            : Text(_sectionTitle(l10n, library, folderNames)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l10n.commonOpenDrawer,
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
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
          _FilterButton(
            sort: _sort,
            tagFilter: _tagFilter,
            tags: _tagOptions(songsAsync).keys.whereType<String>().toList(),
            onSortChanged: (s) => setState(() => _sort = s),
            onTagChanged: (t) => setState(() => _tagFilter = t),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (songsAsync) {
                AsyncValue(hasError: true) => _EmptyState(
                    message: l10n.commonError,
                    onRetry: _refresh,
                  ),
                AsyncValue(:final value?) => _songList(
                    songs: _applySectionAndFilters(value, library, folderNames),
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
  ) {
    return switch (library.section) {
      LibrarySection.all => l10n.navAllSongs,
      LibrarySection.favorites => l10n.navFavorites,
      LibrarySection.recent => l10n.navRecents,
      LibrarySection.folder =>
        folderNames[library.folderId] ?? l10n.navFolders,
    };
  }

  Map<String?, String> _tagOptions(AsyncValue<List<SongRow>> songsAsync) {
    final tags = <String>{};
    for (final s in songsAsync.valueOrNull ?? const <SongRow>[]) {
      tags.addAll(s.tags);
    }
    final sorted = tags.toList()..sort();
    return {null: AppLocalizations.of(context).songsAllSongs, for (final t in sorted) t: t};
  }

  List<SongRow> _applySectionAndFilters(
    List<SongRow> songs,
    LibraryState library,
    Map<String, String> folderNames,
  ) {
    var filtered = switch (library.section) {
      LibrarySection.favorites =>
        songs.where((s) => library.favoriteIds.contains(s.id)).toList(),
      LibrarySection.recent => _recentSongs(songs, library.recentIds),
      LibrarySection.folder =>
        songs.where((s) => s.folderId == library.folderId).toList(),
      LibrarySection.all => List<SongRow>.from(songs),
    };

    final q = _search.text.trim().toLowerCase();
    if (_tagFilter != null || q.isNotEmpty) {
      filtered = filtered.where((s) {
        if (_tagFilter != null && !s.tags.contains(_tagFilter)) return false;
        if (q.isNotEmpty) {
          final hay = '${s.title} ${s.artist}'.toLowerCase();
          if (!hay.contains(q)) return false;
        }
        return true;
      }).toList();
    }

    switch (_sort) {
      case SongSort.title:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SongSort.artist:
        filtered.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case SongSort.updated:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  List<SongRow> _recentSongs(List<SongRow> songs, List<String> recentIds) {
    final byId = {for (final s in songs) s.id: s};
    return [
      for (final id in recentIds)
        if (byId[id] != null) byId[id]!,
    ];
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
      return _EmptyState(message: l10n.songsNoResults, onRetry: _refresh);
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
          leading: const Icon(Icons.music_note),
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

/// Filter popup (sort + tag), opened from the AppBar action.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.sort,
    required this.tagFilter,
    required this.tags,
    required this.onSortChanged,
    required this.onTagChanged,
  });

  final SongSort sort;
  final String? tagFilter;
  final List<String> tags;
  final ValueChanged<SongSort> onSortChanged;
  final ValueChanged<String?> onTagChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.filter_list),
      tooltip: l10n.songsFilter,
      onPressed: () => _showFilterSheet(context, l10n),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final sortLabels = {
          SongSort.title: l10n.songsSortTitle,
          SongSort.artist: l10n.songsSortArtist,
          SongSort.updated: l10n.songsSortUpdated,
        };
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.songsSortBy,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final s in SongSort.values)
                  RadioListTile<SongSort>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sortLabels[s]!),
                    value: s,
                    groupValue: sort,
                    onChanged: (v) {
                      if (v != null) onSortChanged(v);
                    },
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n.songsFilterByTag,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: l10n.songsAllSongs,
                      selected: tagFilter == null,
                      onTap: () => onTagChanged(null),
                    ),
                    for (final t in tags)
                      _TagChip(
                        label: t,
                        selected: tagFilter == t,
                        onTap: () => onTagChanged(t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.commonDone),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
