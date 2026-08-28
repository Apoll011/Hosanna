import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

class ServiceRepository {
  ServiceRepository(this._db);

  final AppDatabase _db;

  Stream<List<ServiceRow>> watchServices() {
    return (_db.select(_db.services)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Stream<ServiceRow?> watchService(String id) {
    return (_db.select(_db.services)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.watch(databaseProvider));
});

final servicesStreamProvider = StreamProvider<List<ServiceRow>>((ref) {
  return ref.watch(serviceRepositoryProvider).watchServices();
});

final serviceByIdProvider = StreamProvider.family<ServiceRow?, String>((ref, id) {
  return ref.watch(serviceRepositoryProvider).watchService(id);
});
