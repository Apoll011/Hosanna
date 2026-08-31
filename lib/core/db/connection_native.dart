import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the on-device SQLite database (Android/iOS/desktop).
///
/// The database file is created lazily, on first use, inside the platform's
/// documents directory (`hosanna.db`).
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hosanna.db'));
    return NativeDatabase(file);
  });
}
