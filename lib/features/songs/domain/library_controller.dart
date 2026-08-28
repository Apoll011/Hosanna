import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';

/// Which slice of the song library the browser is showing.
enum LibrarySection { all, favorites, recent, folder }

/// Library-level, non-replicated user state: favorite songs, recently played
/// songs, and the currently selected browse section (mirrors the React app's
/// `activeListContext` + `favoriteSongIds` / `recentlyPlayedSongIds`).
class LibraryState {
  const LibraryState({
    this.section = LibrarySection.all,
    this.folderId,
    this.favoriteIds = const [],
    this.recentIds = const [],
  });

  final LibrarySection section;
  final String? folderId;
  final List<String> favoriteIds;

  /// Most-recent-first list of song ids.
  final List<String> recentIds;

  bool isFavorite(String id) => favoriteIds.contains(id);

  LibraryState copyWith({
    LibrarySection? section,
    String? folderId,
    bool clearFolder = false,
    List<String>? favoriteIds,
    List<String>? recentIds,
  }) {
    return LibraryState(
      section: section ?? this.section,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      favoriteIds: favoriteIds ?? this.favoriteIds,
      recentIds: recentIds ?? this.recentIds,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._prefs) : super(const LibraryState()) {
    _restore();
  }

  static const _favoritesKey = 'library.favoriteIds';
  static const _recentsKey = 'library.recentIds';
  static const _maxRecents = 50;

  final SharedPreferences _prefs;

  void _restore() {
    state = LibraryState(
      favoriteIds: _prefs.getStringList(_favoritesKey) ?? const [],
      recentIds: _prefs.getStringList(_recentsKey) ?? const [],
    );
  }

  void selectAll() => state = state.copyWith(
        section: LibrarySection.all,
        clearFolder: true,
      );

  void selectFavorites() => state = state.copyWith(
        section: LibrarySection.favorites,
        clearFolder: true,
      );

  void selectRecent() => state = state.copyWith(
        section: LibrarySection.recent,
        clearFolder: true,
      );

  void selectFolder(String folderId) => state = state.copyWith(
        section: LibrarySection.folder,
        folderId: folderId,
      );

  void toggleFavorite(String id) {
    final ids = List<String>.from(state.favoriteIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.insert(0, id);
    }
    state = state.copyWith(favoriteIds: ids);
    _prefs.setStringList(_favoritesKey, ids);
  }

  /// Records a song as recently played (deduped, most recent first).
  void markPlayed(String id) {
    final ids = [id, ...state.recentIds.where((e) => e != id)];
    final capped = ids.length > _maxRecents ? ids.sublist(0, _maxRecents) : ids;
    state = state.copyWith(recentIds: capped);
    _prefs.setStringList(_recentsKey, capped);
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(ref.watch(sharedPreferencesProvider));
});
