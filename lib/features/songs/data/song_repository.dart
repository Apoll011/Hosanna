import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../domain/chordpro_content.dart';

class SongRepository {
  SongRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<SongRow>> watchSongs() {
    return (_db.select(_db.songs)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch();
  }

  Stream<SongRow?> watchSong(String id) {
    return (_db.select(_db.songs)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<SongRow?> getSong(String id) {
    return (_db.select(_db.songs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new song locally and marks it dirty for the next push.
  Future<SongRow> createSong({
    required String title,
    String artist = '',
    required String content,
    String? folderId,
    List<String> tags = const [],
    int? songNumber,
    String? id,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final songId = id ?? _uuid.v4();
    final path = sanitizeSongPath(title);
    final companion = SongsCompanion.insert(
      id: songId,
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      artist: artist.trim().isEmpty ? 'Unknown' : artist.trim(),
      content: content,
      folderId: Value(folderId),
      path: path,
      tags: Value(tags),
      songNumber: Value(songNumber),
      createdAt: now,
      updatedAt: now,
      dirty: const Value(true),
    );
    await _db.into(_db.songs).insert(companion);
    final row = await getSong(songId);
    if (row == null) {
      throw StateError('Failed to read song after insert: $songId');
    }
    return row;
  }

  /// Updates an existing song and marks it dirty for the next push.
  Future<SongRow> updateSong({
    required String id,
    String? title,
    String? artist,
    String? content,
    String? folderId,
    bool clearFolderId = false,
    List<String>? tags,
    int? songNumber,
    bool clearSongNumber = false,
  }) async {
    final existing = await getSong(id);
    if (existing == null || existing.isDeleted) {
      throw StateError('Song not found: $id');
    }

    final nextTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : existing.title;
    final nextPath = title != null ? sanitizeSongPath(nextTitle) : existing.path;
    final now = DateTime.now().toUtc().toIso8601String();

    await (_db.update(_db.songs)..where((t) => t.id.equals(id))).write(
      SongsCompanion(
        title: title != null ? Value(nextTitle) : const Value.absent(),
        artist: artist != null
            ? Value(artist.trim().isEmpty ? 'Unknown' : artist.trim())
            : const Value.absent(),
        content: content != null ? Value(content) : const Value.absent(),
        folderId: clearFolderId
            ? const Value(null)
            : folderId != null
                ? Value(folderId)
                : const Value.absent(),
        path: title != null ? Value(nextPath) : const Value.absent(),
        tags: tags != null ? Value(tags) : const Value.absent(),
        songNumber: clearSongNumber
            ? const Value(null)
            : songNumber != null
                ? Value(songNumber)
                : const Value.absent(),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );

    final row = await getSong(id);
    if (row == null) {
      throw StateError('Failed to read song after update: $id');
    }
    return row;
  }
}

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.watch(databaseProvider));
});

final songsStreamProvider = StreamProvider<List<SongRow>>((ref) {
  return ref.watch(songRepositoryProvider).watchSongs();
});

final songByIdProvider = StreamProvider.family<SongRow?, String>((ref, id) {
  return ref.watch(songRepositoryProvider).watchSong(id);
});
