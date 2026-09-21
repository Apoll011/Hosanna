import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/core/sync/adapters.dart';

void main() {
  test('v2 collections table without song_count is migrated', () async {
    final dir = Directory.systemTemp.createTempSync('hosanna_migration');
    final file = File('${dir.path}/hosanna.db');
    addTearDown(() => dir.deleteSync(recursive: true));

    // Simulate a database created while `collections.songCount` did not exist
    // yet: `collections` loses the column again and the file is tagged as v2,
    // exactly like a device that upgraded from the previous build.
    final current = AppDatabase(NativeDatabase(file));
    await current.customStatement(
      'ALTER TABLE collections DROP COLUMN song_count',
    );
    await current.customStatement('PRAGMA user_version = 2');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(() => db.close());

    // Pulling a collection writes the row and then reads it back, which is what
    // used to throw `Null check operator used on a null value`.
    final adapter = CollectionReplicationAdapter(db);
    await adapter.upsertFromWire([
      {
        'id': 'c1',
        'name': 'Sunday Set',
        'songIds': ['s1'],
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-02T00:00:00Z',
      },
    ]);
    await adapter.refreshLocalCounts();

    final rows = await db.select(db.collections).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Sunday Set');
    expect(rows.single.songIds, ['s1']);
  });
}
