import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  Stream<List<FolderRow>> watchFolders() {
    return (_db.select(_db.folders)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<FolderRow?> watchFolder(String id) {
    return (_db.select(_db.folders)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }
}

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository(ref.watch(databaseProvider));
});

final foldersStreamProvider = StreamProvider<List<FolderRow>>((ref) {
  return ref.watch(folderRepositoryProvider).watchFolders();
});
