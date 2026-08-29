import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../folders/data/folder_repository.dart';
import '../data/song_repository.dart';
import '../domain/chordpro/parser.dart';
import '../domain/library_controller.dart';

enum SongSort { title, artist, songNumber, updated, added }

enum SongNumberFilter { any, numbered, unnumbered }

/// All user-adjustable list settings for the song library (sort + filters).
class FilterSettings {
  const FilterSettings({
    this.sort = SongSort.title,
    this.sortAscending = true,
    this.selectedTags = const {},
    this.tagMatchAll = true,
    this.selectedFolders = const {},
    this.selectedKeys = const {},
    this.songNumberFilter = SongNumberFilter.any,
    this.searchLyrics = false,
    this.withChordsOnly = false,
  });

  final SongSort sort;
  final bool sortAscending;

  /// Selected tags; a song matches when it contains all of them
  /// ([tagMatchAll]) or any of them.
  final Set<String> selectedTags;
  final bool tagMatchAll;
  final Set<String> selectedFolders;
  final Set<String> selectedKeys;
  final SongNumberFilter songNumberFilter;

  /// Include the song lyrics in the search query haystack.
  final bool searchLyrics;

  /// Only show songs whose content contains chord annotations.
  final bool withChordsOnly;

  bool get isDefault => activeFilterCount == 0;

  int get activeFilterCount =>
      (selectedTags.isNotEmpty ? 1 : 0) +
      (selectedFolders.isNotEmpty ? 1 : 0) +
      (selectedKeys.isNotEmpty ? 1 : 0) +
      (songNumberFilter != SongNumberFilter.any ? 1 : 0) +
      (searchLyrics ? 1 : 0) +
      (withChordsOnly ? 1 : 0) +
      (sort != SongSort.title || !sortAscending ? 1 : 0);

  FilterSettings copyWith({
    SongSort? sort,
    bool? sortAscending,
    Set<String>? selectedTags,
    bool? tagMatchAll,
    Set<String>? selectedFolders,
    Set<String>? selectedKeys,
    SongNumberFilter? songNumberFilter,
    bool? searchLyrics,
    bool? withChordsOnly,
  }) {
    return FilterSettings(
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedTags: selectedTags ?? this.selectedTags,
      tagMatchAll: tagMatchAll ?? this.tagMatchAll,
      selectedFolders: selectedFolders ?? this.selectedFolders,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      songNumberFilter: songNumberFilter ?? this.songNumberFilter,
      searchLyrics: searchLyrics ?? this.searchLyrics,
      withChordsOnly: withChordsOnly ?? this.withChordsOnly,
    );
  }
}

/// Lightweight info parsed from a song's ChordPro content, used by filters.
class _SongMeta {
  const _SongMeta({this.key, required this.hasChords});

  /// The `{key: ...}` (or `{k: ...}`) metadata directive, if present.
  final String? key;
  final bool hasChords;
}

_SongMeta _extractMeta(SongRow song) {
  final ast = parseChordPro(song.content);
  var hasChords = false;
  for (final section in ast.sections) {
    for (final line in section.lines) {
      final segments = line.segments;
      if (segments != null && segments.any((s) => s.chord.isNotEmpty)) {
        hasChords = true;
        break;
      }
    }
    if (hasChords) break;
  }
  return _SongMeta(key: ast.metadata['key'], hasChords: hasChords);
}

String _songSortLabel(AppLocalizations l10n, SongSort sort) {
  return switch (sort) {
    SongSort.title => l10n.songsSortTitle,
    SongSort.artist => l10n.songsSortArtist,
    SongSort.songNumber => l10n.songsSortNumber,
    SongSort.updated => l10n.songsSortUpdated,
    SongSort.added => l10n.songsSortAdded,
  };
}

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
  Map<String, _SongMeta> _metaBySongId = const {};

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

    final songs = songsAsync.valueOrNull ?? const <SongRow>[];
    if (!identical(_metaCacheSongs, songs)) {
      _metaCacheSongs = songs;
      _metaBySongId = {
        for (final s in songs) s.id: _extractMeta(s),
      };
    }

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
  ) {
    return switch (library.section) {
      LibrarySection.all => l10n.navAllSongs,
      LibrarySection.favorites => l10n.navFavorites,
      LibrarySection.recent => l10n.navRecents,
      LibrarySection.folder =>
        folderNames[library.folderId] ?? l10n.navFolders,
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
    final tagOptions = _tagOptions(songs);
    final keyOptions = _keyOptions();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
        ),
        child: _FilterSheet(
          initial: _settings,
          tagOptions: tagOptions,
          folderOptions: folderOptions,
          keyOptions: keyOptions,
          onChanged: (next) => setState(() => _settings = next),
        ),
      ),
    );
  }

  List<String> _tagOptions(List<SongRow> songs) {
    final tags = <String>{};
    for (final s in songs) {
      tags.addAll(s.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  List<String> _keyOptions() {
    final keys = <String>{};
    for (final meta in _metaBySongId.values) {
      final key = meta.key;
      if (key != null) keys.add(key);
    }
    final sorted = keys.toList()..sort();
    return sorted;
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
    final hasFilters = q.isNotEmpty ||
        _settings.selectedTags.isNotEmpty ||
        _settings.selectedFolders.isNotEmpty ||
        _settings.selectedKeys.isNotEmpty ||
        _settings.songNumberFilter != SongNumberFilter.any ||
        _settings.searchLyrics ||
        _settings.withChordsOnly;
    if (hasFilters) {
      filtered = filtered.where((s) {
        if (q.isNotEmpty && !_matchesQuery(s, q, folderNames)) return false;
        if (_settings.selectedTags.isNotEmpty) {
          final ok = _settings.tagMatchAll
              ? _settings.selectedTags.every(s.tags.contains)
              : _settings.selectedTags.any(s.tags.contains);
          if (!ok) return false;
        }
        if (_settings.selectedFolders.isNotEmpty &&
            (s.folderId == null ||
                !_settings.selectedFolders.contains(s.folderId))) {
          return false;
        }
        if (_settings.selectedKeys.isNotEmpty) {
          final key = _metaBySongId[s.id]?.key;
          if (key == null ||
              !_settings.selectedKeys
                  .any((k) => k.toUpperCase() == key.toUpperCase())) {
            return false;
          }
        }
        switch (_settings.songNumberFilter) {
          case SongNumberFilter.numbered:
            if (s.songNumber == null) return false;
          case SongNumberFilter.unnumbered:
            if (s.songNumber != null) return false;
          case SongNumberFilter.any:
            break;
        }
        if (_settings.withChordsOnly &&
            !(_metaBySongId[s.id]?.hasChords ?? false)) {
          return false;
        }
        return true;
      }).toList();
    }

    switch (_settings.sort) {
      case SongSort.title:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SongSort.artist:
        filtered.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
      case SongSort.songNumber:
        filtered.sort(
          (a, b) => (a.songNumber ?? 1 << 30).compareTo(b.songNumber ?? 1 << 30),
        );
      case SongSort.updated:
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SongSort.added:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    if (!_settings.sortAscending) {
      filtered = filtered.reversed.toList();
    }
    return filtered;
  }

  bool _matchesQuery(
    SongRow s,
    String q,
    Map<String, String> folderNames,
  ) {
    final hay = StringBuffer()
      ..write(s.title.toLowerCase())
      ..write(' ')
      ..write(s.artist.toLowerCase())
      ..write(' ')
      ..write(s.tags.join(' ').toLowerCase());
    final folder = s.folderId == null ? null : folderNames[s.folderId];
    if (folder != null) {
      hay.write(' ');
      hay.write(folder.toLowerCase());
    }
    if (s.songNumber != null) hay.write(' ${s.songNumber}');
    if (_settings.searchLyrics) {
      hay.write(' ');
      hay.write(s.content.toLowerCase());
    }
    return hay.toString().contains(q);
  }

  List<SongRow> _recentSongs(List<SongRow> songs, List<String> recentIds) {
    final byId = {for (final s in songs) s.id: s};
    return [
      for (final id in recentIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Widget _buildActiveFilterChips(Map<String, String> folderNames) {
    return _ActiveFilterChips(
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
          leading: _SongBadge(songNumber: song.songNumber),
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
          : Icon(
              Icons.music_note,
              size: 18,
              color: colorScheme.secondary,
            ),
    );
  }
}

/// Filter button in the AppBar, showing a badge with the number of active
/// filters.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: l10n.songsFilter,
        onPressed: onPressed,
      ),
    );
  }
}

/// Filter/sort sheet opened from the AppBar.
///
/// Stateful on purpose: it keeps its own draft of [FilterSettings] and applies
/// every change to the page immediately, so chips/radios give instant visual
/// feedback while the list behind updates live.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.tagOptions,
    required this.folderOptions,
    required this.keyOptions,
    required this.onChanged,
  });

  final FilterSettings initial;
  final List<String> tagOptions;
  final List<({String id, String name})> folderOptions;
  final List<String> keyOptions;
  final ValueChanged<FilterSettings> onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FilterSettings _draft = widget.initial;

  void _apply(FilterSettings next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(l10n.songsSortBy),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in SongSort.values)
                  ChoiceChip(
                    label: Text(_songSortLabel(l10n, sort)),
                    selected: _draft.sort == sort,
                    onSelected: (_) => _apply(_draft.copyWith(sort: sort)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.songsSortAscending),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.songsSortDescending),
                ),
              ],
              selected: {_draft.sortAscending},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  _apply(_draft.copyWith(sortAscending: selection.first)),
            ),
            const Divider(height: 32),
            if (widget.tagOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByTag,
                clear: _draft.selectedTags.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedTags: const {})),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.songsMatchAll)),
                  ButtonSegment(value: false, label: Text(l10n.songsMatchAny)),
                ],
                selected: {_draft.tagMatchAll},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    _apply(_draft.copyWith(tagMatchAll: selection.first)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.tagOptions)
                    FilterChip(
                      label: Text(tag),
                      selected: _draft.selectedTags.contains(tag),
                      onSelected: (selected) {
                        final tags = Set<String>.of(_draft.selectedTags);
                        selected ? tags.add(tag) : tags.remove(tag);
                        _apply(_draft.copyWith(selectedTags: tags));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            if (widget.folderOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByFolder,
                clear: _draft.selectedFolders.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedFolders: const {})),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final folder in widget.folderOptions)
                    FilterChip(
                      label: Text(folder.name),
                      selected: _draft.selectedFolders.contains(folder.id),
                      onSelected: (selected) {
                        final folders = Set<String>.of(_draft.selectedFolders);
                        selected ? folders.add(folder.id) : folders.remove(folder.id);
                        _apply(_draft.copyWith(selectedFolders: folders));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            if (widget.keyOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByKey,
                clear: _draft.selectedKeys.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedKeys: const {})),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in widget.keyOptions)
                    FilterChip(
                      label: Text(key),
                      selected: _draft.selectedKeys.contains(key),
                      onSelected: (selected) {
                        final keys = Set<String>.of(_draft.selectedKeys);
                        selected ? keys.add(key) : keys.remove(key);
                        _apply(_draft.copyWith(selectedKeys: keys));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            _sectionHeader(l10n.songsFilterBySongNumber),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in SongNumberFilter.values)
                  ChoiceChip(
                    label: Text(_songNumberLabel(l10n, option)),
                    selected: _draft.songNumberFilter == option,
                    onSelected: (_) =>
                        _apply(_draft.copyWith(songNumberFilter: option)),
                  ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songsSearchLyrics),
              value: _draft.searchLyrics,
              onChanged: (value) =>
                  _apply(_draft.copyWith(searchLyrics: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songsWithChords),
              value: _draft.withChordsOnly,
              onChanged: (value) =>
                  _apply(_draft.copyWith(withChordsOnly: value)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _apply(const FilterSettings()),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.songsResetFilters),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _songNumberLabel(AppLocalizations l10n, SongNumberFilter option) {
    return switch (option) {
      SongNumberFilter.any => l10n.songsNumberAny,
      SongNumberFilter.numbered => l10n.songsNumberOnly,
      SongNumberFilter.unnumbered => l10n.songsNumberNone,
    };
  }

  Widget _sectionHeader(String title, {VoidCallback? clear}) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (clear != null)
          TextButton(
            onPressed: clear,
            child: Text(l10n.songsClear),
          ),
      ],
    );
  }
}

/// Row of removable chips under the app bar summarizing the active filters.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.settings,
    required this.folderNames,
    required this.onOpenFilters,
    required this.onRemoveTag,
    required this.onRemoveFolder,
    required this.onRemoveKey,
    required this.onSongNumberAny,
    required this.onLyricsOff,
    required this.onChordsOff,
    required this.onReset,
  });

  final FilterSettings settings;
  final Map<String, String> folderNames;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onRemoveFolder;
  final ValueChanged<String> onRemoveKey;
  final VoidCallback onSongNumberAny;
  final VoidCallback onLyricsOff;
  final VoidCallback onChordsOff;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (settings.sort != SongSort.title || !settings.sortAscending) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.sort, size: 18),
          label: Text(
            '${_songSortLabel(l10n, settings.sort)} '
            '${settings.sortAscending ? '↑' : '↓'}',
          ),
          onPressed: onOpenFilters,
        ),
      );
    }
    for (final tag in settings.selectedTags) {
      chips.add(
        InputChip(
          label: Text(tag),
          onDeleted: () => onRemoveTag(tag),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    for (final folderId in settings.selectedFolders) {
      chips.add(
        InputChip(
          label: Text(folderNames[folderId] ?? folderId),
          onDeleted: () => onRemoveFolder(folderId),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    for (final key in settings.selectedKeys) {
      chips.add(
        InputChip(
          label: Text(key),
          onDeleted: () => onRemoveKey(key),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.songNumberFilter != SongNumberFilter.any) {
      chips.add(
        InputChip(
          label: Text(
            settings.songNumberFilter == SongNumberFilter.numbered
                ? l10n.songsNumberOnly
                : l10n.songsNumberNone,
          ),
          onDeleted: onSongNumberAny,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.searchLyrics) {
      chips.add(
        InputChip(
          label: Text(l10n.songsSearchLyrics),
          onDeleted: onLyricsOff,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.withChordsOnly) {
      chips.add(
        InputChip(
          label: Text(l10n.songsWithChords),
          onDeleted: onChordsOff,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.restart_alt, size: 18),
        label: Text(l10n.songsResetFilters),
        onPressed: onReset,
      ),
    );

    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
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
