import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Songs, Folders, Services, Collections, AgendaEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the app database using the platform's native connection.
  ///
  /// - Native (Android/iOS/desktop): SQLite file in the documents directory.
  /// - Web (Chrome, etc.): SQLite compiled to WebAssembly, stored in the
  ///   browser's OPFS/IndexedDB storage.
  static Future<AppDatabase> open() async {
    return AppDatabase(openConnection());
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 adds the replicated `collections` table.
      if (from < 2) {
        await m.createTable(collections);
      }
      // v3 backfills the local-only `collections.songCount` column. It was
      // introduced while the schema version was still 2, so databases created
      // in that window have the table but not the column, and drift's row
      // mapper throws `Null check operator used on a null value` when reading
      // it (which broke the collection replication pull). The column is only
      // added when it is actually absent, because databases created after the
      // column landed are still tagged as v2.
      if (from < 3 && !await _hasColumn('collections', 'song_count')) {
        await m.addColumn(collections, collections.songCount);
      }
      // v4 adds replicated agenda events (Studio calendar).
      if (from < 4) {
        await m.createTable(agendaEvents);
      }
    },
  );

  /// Whether [table] already has a column called [name].
  ///
  /// Used to keep migrations idempotent for databases created in between
  /// schema version bumps.
  Future<bool> _hasColumn(String table, String name) async {
    final info = await customSelect("PRAGMA table_info('$table')").get();
    return info.any((row) => row.read<String>('name') == name);
  }

  /// Wipes all replicated tenant tables. Used when switching organizations so
  /// the previous church's rows cannot leak into the next sync/push cycle.
  Future<void> clearAllReplicatedData() async {
    await transaction(() async {
      await delete(songs).go();
      await delete(folders).go();
      await delete(collections).go();
      await delete(services).go();
      await delete(agendaEvents).go();
    });
  }

  /// Marks a local row dirty so the next replication push uploads it.
  Future<void> markSongDirty(String id) =>
      (update(songs)..where((t) => t.id.equals(id)))
          .write(const SongsCompanion(dirty: Value(true)));

  Future<void> markFolderDirty(String id) =>
      (update(folders)..where((t) => t.id.equals(id)))
          .write(const FoldersCompanion(dirty: Value(true)));

  Future<void> markCollectionDirty(String id) =>
      (update(collections)..where((t) => t.id.equals(id)))
          .write(const CollectionsCompanion(dirty: Value(true)));

  Future<void> markServiceDirty(String id) =>
      (update(services)..where((t) => t.id.equals(id)))
          .write(const ServicesCompanion(dirty: Value(true)));

  Future<void> markAgendaEventDirty(String id) =>
      (update(agendaEvents)..where((t) => t.id.equals(id)))
          .write(const AgendaEventsCompanion(dirty: Value(true)));
}
