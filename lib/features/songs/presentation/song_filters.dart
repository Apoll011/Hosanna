import '../../../core/db/database.dart';
import '../domain/chordpro/parser.dart';

enum SongSort { title, artist, songNumber, updated, added }

enum SongNumberFilter { any, numbered, unnumbered }

/// All user-adjustable list settings for a song list (sort + filters).
class FilterSettings {
  const FilterSettings({
    this.sort = SongSort.title,
    this.sortAscending = true,
    this.selectedTags = const {},
    this.tagMatchAll = true,
    this.selectedFolders = const {},
    this.selectedCollections = const {},
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

  /// Selected collections; a song matches when it belongs to any of them.
  final Set<String> selectedCollections;
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
      (selectedCollections.isNotEmpty ? 1 : 0) +
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
    Set<String>? selectedCollections,
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
      selectedCollections: selectedCollections ?? this.selectedCollections,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      songNumberFilter: songNumberFilter ?? this.songNumberFilter,
      searchLyrics: searchLyrics ?? this.searchLyrics,
      withChordsOnly: withChordsOnly ?? this.withChordsOnly,
    );
  }
}

/// Lightweight info parsed from a song's ChordPro content, used by filters.
class SongMeta {
  const SongMeta({this.key, required this.hasChords});

  /// The `{key: ...}` (or `{k: ...}`) metadata directive, if present.
  final String? key;
  final bool hasChords;
}

SongMeta extractSongMeta(SongRow song) {
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
  return SongMeta(key: ast.metadata['key'], hasChords: hasChords);
}

/// Parses every song once, building the `{songId: meta}` cache that
/// [applySongFilters] reads. Cheap to keep around and rebuild only when the
/// song list reference changes.
Map<String, SongMeta> extractSongMetaById(Iterable<SongRow> songs) {
  return {for (final s in songs) s.id: extractSongMeta(s)};
}

/// Tags present across [songs], sorted alphabetically.
List<String> tagOptionsFrom(Iterable<SongRow> songs) {
  final tags = <String>{};
  for (final s in songs) {
    tags.addAll(s.tags);
  }
  return tags.toList()..sort();
}

/// Maps each song id to the ids of the collections that contain it, backing
/// the collection filter.
Map<String, Set<String>> collectionIdsBySongIdFrom(
  Iterable<CollectionRow> collections,
) {
  final bySongId = <String, Set<String>>{};
  for (final collection in collections) {
    for (final songId in collection.songIds) {
      (bySongId[songId] ??= <String>{}).add(collection.id);
    }
  }
  return bySongId;
}

/// Song keys present in [metaBySongId] (from parsed `{key: ...}` metadata),
/// sorted alphabetically.
List<String> keyOptionsFrom(Map<String, SongMeta> metaBySongId) {
  final keys = <String>{};
  for (final meta in metaBySongId.values) {
    final key = meta.key;
    if (key != null) keys.add(key);
  }
  return keys.toList()..sort();
}

/// Whether [song] passes the query and the tag/folder/key/number/chord filters
/// in [settings]. Sorting is not considered here (see [applySongFilters]).
bool songMatchesFilters(
  SongRow song, {
  required FilterSettings settings,
  required String query,
  SongMeta? meta,
  Map<String, String> folderNames = const {},
  Map<String, Set<String>> collectionIdsBySongId = const {},
}) {
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty &&
      !_matchesQuery(song, q, folderNames, searchLyrics: settings.searchLyrics)) {
    return false;
  }
  if (settings.selectedTags.isNotEmpty) {
    final ok = settings.tagMatchAll
        ? settings.selectedTags.every(song.tags.contains)
        : settings.selectedTags.any(song.tags.contains);
    if (!ok) return false;
  }
  if (settings.selectedFolders.isNotEmpty &&
      (song.folderId == null ||
          !settings.selectedFolders.contains(song.folderId))) {
    return false;
  }
  if (settings.selectedCollections.isNotEmpty) {
    final collectionIds = collectionIdsBySongId[song.id] ?? const <String>{};
    if (!settings.selectedCollections.any(collectionIds.contains)) return false;
  }
  if (settings.selectedKeys.isNotEmpty) {
    final key = meta?.key;
    if (key == null ||
        !settings.selectedKeys.any((k) => k.toUpperCase() == key.toUpperCase())) {
      return false;
    }
  }
  switch (settings.songNumberFilter) {
    case SongNumberFilter.numbered:
      if (song.songNumber == null) return false;
    case SongNumberFilter.unnumbered:
      if (song.songNumber != null) return false;
    case SongNumberFilter.any:
      break;
  }
  if (settings.withChordsOnly && !(meta?.hasChords ?? false)) {
    return false;
  }
  return true;
}

/// Filters [songs] by [query] and [settings], then returns them sorted.
///
/// [metaBySongId] (see [extractSongMetaById]) backs the key/chord filters, and
/// [folderNames] lets the query match folder names.
List<SongRow> applySongFilters(
  Iterable<SongRow> songs, {
  FilterSettings settings = const FilterSettings(),
  String query = '',
  Map<String, SongMeta> metaBySongId = const {},
  Map<String, String> folderNames = const {},
  Map<String, Set<String>> collectionIdsBySongId = const {},
}) {
  final q = query.trim().toLowerCase();
  final hasFilters = q.isNotEmpty ||
      settings.selectedTags.isNotEmpty ||
      settings.selectedFolders.isNotEmpty ||
      settings.selectedCollections.isNotEmpty ||
      settings.selectedKeys.isNotEmpty ||
      settings.songNumberFilter != SongNumberFilter.any ||
      settings.searchLyrics ||
      settings.withChordsOnly;

  var filtered = List<SongRow>.of(songs);
  if (hasFilters) {
    filtered = filtered
        .where(
          (s) => songMatchesFilters(
            s,
            settings: settings,
            query: q,
            meta: metaBySongId[s.id],
            folderNames: folderNames,
            collectionIdsBySongId: collectionIdsBySongId,
          ),
        )
        .toList();
  }

  switch (settings.sort) {
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
  if (!settings.sortAscending) {
    filtered = filtered.reversed.toList();
  }
  return filtered;
}

bool _matchesQuery(
  SongRow s,
  String q,
  Map<String, String> folderNames, {
  required bool searchLyrics,
}) {
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
  if (searchLyrics) {
    hay.write(' ');
    hay.write(s.content.toLowerCase());
  }
  return hay.toString().contains(q);
}
