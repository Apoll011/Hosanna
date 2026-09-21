import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

class CollectionRepository {
  CollectionRepository(this._db);

  final AppDatabase _db;

  Stream<List<CollectionRow>> watchCollections() {
    return (_db.select(_db.collections)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<CollectionRow?> watchCollection(String id) {
    return (_db.select(_db.collections)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }
}

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository(ref.watch(databaseProvider));
});

final collectionsStreamProvider = StreamProvider<List<CollectionRow>>((ref) {
  return ref.watch(collectionRepositoryProvider).watchCollections();
});
