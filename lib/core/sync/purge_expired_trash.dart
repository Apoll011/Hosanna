import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/tables.dart';

/// Hard-removes local trashed rows whose [purgeAt] has expired.
///
/// Soft-delete (`isDeleted` + `purgeAt`) stays in trash until this runs.
/// Server-side hard-delete is handled by the purge-trash cron (and by the
/// dashboard tombstone push). This client only cleans its local SQLite copy
/// so expired trash does not accumulate offline.
Future<void> purgeExpiredTrash(AppDatabase db) async {
  final nowIso = DateTime.now().toUtc().toIso8601String();

  Expression<bool> expired(SyncMetadata t) =>
      t.isDeleted.equals(true) &
      t.purgeAt.isNotNull() &
      t.purgeAt.isSmallerOrEqualValue(nowIso);

  await db.transaction(() async {
    await (db.delete(db.songs)..where(expired)).go();
    await (db.delete(db.folders)..where(expired)).go();
    await (db.delete(db.collections)..where(expired)).go();
    await (db.delete(db.services)..where(expired)).go();
  });
}
