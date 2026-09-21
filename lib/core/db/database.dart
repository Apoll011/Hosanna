import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Songs, Folders, Services, Collections])
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
  int get schemaVersion => 3;

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
}
