import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

class AgendaRepository {
  AgendaRepository(this._db);

  final AppDatabase _db;

  Stream<List<AgendaEventRow>> watchUpcoming({int limit = 50}) {
    final query = _db.select(_db.agendaEvents)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm.asc(t.date),
        (t) => OrderingTerm.asc(t.time),
      ])
      ..limit(limit);
    return query.watch();
  }
}

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(databaseProvider));
});

final agendaEventsStreamProvider =
    StreamProvider.autoDispose<List<AgendaEventRow>>((ref) {
  return ref.watch(agendaRepositoryProvider).watchUpcoming();
});
