import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/core/sync/adapters.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('markSongDirty makes collectChanges return the row for push', () async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: 's1',
            title: 'Hello',
            artist: 'Artist',
            content: '{title: Hello}',
            path: 'Hello.pro',
            createdAt: '2024-01-01T00:00:00.000Z',
            updatedAt: '2024-01-01T00:00:00.000Z',
            dirty: const Value(false),
          ),
        );

    final adapter = SongReplicationAdapter(db);
    expect(await adapter.collectChanges(), isEmpty);

    await db.markSongDirty('s1');
    final changes = await adapter.collectChanges();
    expect(changes, hasLength(1));
    expect(changes.first.id, 's1');
    expect(changes.first.newDocumentState['title'], 'Hello');

    await adapter.markPushed(['s1']);
    expect(await adapter.collectChanges(), isEmpty);
  });

  test('agendaEvents adapter upserts wire docs from the server', () async {
    final adapter = AgendaEventReplicationAdapter(db);
    await adapter.upsertFromWire([
      {
        'id': 'a1',
        'date': '2026-11-10',
        'title': 'Rehearsal',
        'type': 'rehearsal',
        'time': '19:00',
        'durationMinutes': 90,
        'location': 'Hall',
        'notes': null,
        'reminder': {'enabled': false, 'label': ''},
        'linkedServiceId': null,
        'responsibilities': [],
        'createdAt': '2026-11-01T00:00:00.000Z',
        'updatedAt': '2026-11-01T00:00:00.000Z',
        'isDeleted': false,
        'purgeAt': null,
        '_deleted': false,
      },
    ]);

    final rows = await db.select(db.agendaEvents).get();
    expect(rows, hasLength(1));
    expect(rows.first.title, 'Rehearsal');
    expect(rows.first.durationMinutes, 90);
  });
}
