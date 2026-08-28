import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

class SongRepository {
  SongRepository(this._db);

  final AppDatabase _db;

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
