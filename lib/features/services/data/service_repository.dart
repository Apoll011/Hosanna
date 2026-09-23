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

/// The service the "next service" shortcut opens: the earliest non-archived
/// service dated today or later.
///
/// When there is nothing scheduled ahead (e.g. the next service hasn't been
/// synced yet), the most recent past service is returned instead, so the
/// shortcut still lands somewhere useful. Services without a parsable date are
/// ignored.
ServiceRow? nextUpcomingService(
  Iterable<ServiceRow> services, {
  DateTime? now,
}) {
  final today = _dayOf(now ?? DateTime.now());
  ServiceRow? upcoming;
  DateTime? upcomingDay;
  ServiceRow? latestPast;
  DateTime? latestPastDay;

  for (final service in services) {
    if (service.archived) continue;
    final date = DateTime.tryParse(service.date);
    if (date == null) continue;
    final day = _dayOf(date);

    if (!day.isBefore(today)) {
      if (upcomingDay == null || day.isBefore(upcomingDay)) {
        upcoming = service;
        upcomingDay = day;
      }
    } else if (latestPastDay == null || day.isAfter(latestPastDay)) {
      latestPast = service;
      latestPastDay = day;
    }
  }

  return upcoming ?? latestPast;
}

DateTime _dayOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
