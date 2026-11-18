import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';

/// Which slice of the song library the browser is showing.
enum LibrarySection { all, favorites, recent, folder, collection }

/// Library-level, non-replicated user state: favorite songs, recently played
/// songs, and the currently selected browse section (mirrors the React app's
/// `activeListContext` + `favoriteSongIds` / `recentlyPlayedSongIds`).
///
/// Favorites and recents are scoped per organization so switching churches
/// never shows another tenant's counts or ghost ids.
class LibraryState {
  const LibraryState({
    this.section = LibrarySection.all,
    this.folderId,
    this.collectionId,
    this.favoriteIds = const [],
    this.recentIds = const [],
    this.organizationId,
  });

  final LibrarySection section;
  final String? folderId;
  final String? collectionId;
  final List<String> favoriteIds;

  /// Most-recent-first list of song ids.
  final List<String> recentIds;

  /// Organization these favorite/recent ids belong to.
  final String? organizationId;

  bool isFavorite(String id) => favoriteIds.contains(id);

  LibraryState copyWith({
    LibrarySection? section,
    String? folderId,
    bool clearFolder = false,
    String? collectionId,
    bool clearCollection = false,
    List<String>? favoriteIds,
    List<String>? recentIds,
    String? organizationId,
    bool clearOrganization = false,
  }) {
    return LibraryState(
      section: section ?? this.section,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      collectionId: clearCollection
          ? null
          : (collectionId ?? this.collectionId),
      favoriteIds: favoriteIds ?? this.favoriteIds,
      recentIds: recentIds ?? this.recentIds,
      organizationId: clearOrganization
          ? null
          : (organizationId ?? this.organizationId),
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._prefs) : super(const LibraryState());

  static const _legacyFavoritesKey = 'library.favoriteIds';
  static const _legacyRecentsKey = 'library.recentIds';
  static const _maxRecents = 25;

  final SharedPreferences _prefs;

  static String _favoritesKey(String orgId) => 'library.$orgId.favoriteIds';
  static String _recentsKey(String orgId) => 'library.$orgId.recentIds';

  /// Loads (or clears) favorites/recents for [organizationId].
  ///
  /// Call on every auth org change. Legacy unscoped prefs are migrated into
  /// the first org that binds after upgrade, then removed.
  void bindOrganization(String? organizationId) {
    if (state.organizationId == organizationId) return;

    if (organizationId == null) {
      state = const LibraryState();
      return;
    }

    var favorites = _prefs.getStringList(_favoritesKey(organizationId));
    var recents = _prefs.getStringList(_recentsKey(organizationId));

    // One-time migration from pre-scoping global keys.
    if (favorites == null && _prefs.containsKey(_legacyFavoritesKey)) {
      favorites = _prefs.getStringList(_legacyFavoritesKey) ?? const [];
      _prefs.setStringList(_favoritesKey(organizationId), favorites);
      _prefs.remove(_legacyFavoritesKey);
    }
    if (recents == null && _prefs.containsKey(_legacyRecentsKey)) {
      recents = _prefs.getStringList(_legacyRecentsKey) ?? const [];
      _prefs.setStringList(_recentsKey(organizationId), recents);
      _prefs.remove(_legacyRecentsKey);
    }

    state = LibraryState(
      organizationId: organizationId,
      favoriteIds: favorites ?? const [],
      recentIds: recents ?? const [],
    );
  }

  void selectAll() => state = state.copyWith(
    section: LibrarySection.all,
    clearFolder: true,
    clearCollection: true,
  );

  void selectFavorites() => state = state.copyWith(
    section: LibrarySection.favorites,
    clearFolder: true,
    clearCollection: true,
  );

  void selectRecent() => state = state.copyWith(
    section: LibrarySection.recent,
    clearFolder: true,
    clearCollection: true,
  );

  void selectFolder(String folderId) => state = state.copyWith(
    section: LibrarySection.folder,
    folderId: folderId,
    clearCollection: true,
  );

  void selectCollection(String collectionId) => state = state.copyWith(
    section: LibrarySection.collection,
    collectionId: collectionId,
    clearFolder: true,
  );

  void toggleFavorite(String id) {
    final orgId = state.organizationId;
    if (orgId == null) return;

    final ids = List<String>.from(state.favoriteIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.insert(0, id);
    }
    state = state.copyWith(favoriteIds: ids);
    _prefs.setStringList(_favoritesKey(orgId), ids);
  }

  /// Records a song as recently played (deduped, most recent first).
  void markPlayed(String id) {
    final orgId = state.organizationId;
    if (orgId == null) return;

    final ids = [id, ...state.recentIds.where((e) => e != id)];
    final capped = ids.length > _maxRecents ? ids.sublist(0, _maxRecents) : ids;
    state = state.copyWith(recentIds: capped);
    _prefs.setStringList(_recentsKey(orgId), capped);
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
      return LibraryController(ref.watch(sharedPreferencesProvider));
    });
