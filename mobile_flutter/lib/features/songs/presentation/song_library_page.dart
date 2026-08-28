import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        title: Text(_sectionTitle(l10n, library, folderNames)),
        actions: [
          _SortButton(sort: _sort, onChanged: (s) => setState(() => _sort = s)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.songsSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown<String?>(
                    value: _tagFilter,
                    hint: l10n.songsFilterByTag,
                    items: _tagOptions(songsAsync),
                    onChanged: (v) => setState(() => _tagFilter = v),
                  ),
                ),
              ],
            ),
          ),
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

  /// Preserves the stored recency order, dropping ids that no longer exist.
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

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onChanged});

  final SongSort sort;
  final ValueChanged<SongSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      SongSort.title: l10n.songsSortTitle,
      SongSort.artist: l10n.songsSortArtist,
      SongSort.updated: l10n.songsSortUpdated,
    };
    return PopupMenuButton<SongSort>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.songsSortBy,
      initialValue: sort,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in SongSort.values)
          PopupMenuItem(value: s, child: Text(labels[s]!)),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
