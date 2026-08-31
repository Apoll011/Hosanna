import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Songs, Folders, Services])
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
  int get schemaVersion => 1;
}
