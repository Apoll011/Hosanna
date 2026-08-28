import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Songs, Folders, Services])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device SQLite database (Android/iOS).
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hosanna.db'));
    return AppDatabase(NativeDatabase(file));
  }

  @override
  int get schemaVersion => 1;
}
