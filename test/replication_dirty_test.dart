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
            serverUpdatedAt: const Value('2024-01-01T00:00:00.000Z'),
          ),
        );

    final adapter = SongReplicationAdapter(db);
    expect(await adapter.collectChanges(), isEmpty);

    await db.markSongDirty('s1');
    final changes = await adapter.collectChanges();
    expect(changes, hasLength(1));
    expect(changes.first.id, 's1');
    expect(changes.first.newDocumentState['title'], 'Hello');
    // assumedMaster must be the last server token — NOT the new local state.
    expect(changes.first.assumedMasterState, {
      'id': 's1',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    });

    await adapter.markPushed(['s1']);
    expect(await adapter.collectChanges(), isEmpty);
  });

  test('local edit keeps prior serverUpdatedAt as assumedMaster', () async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: 's2',
            title: 'Old',
            artist: 'Artist',
            content: '{title: Old}',
            path: 'Old.pro',
            createdAt: '2024-01-01T00:00:00.000Z',
            updatedAt: '2024-01-01T00:00:00.000Z',
            dirty: const Value(false),
            serverUpdatedAt: const Value('2024-01-01T00:00:00.000Z'),
          ),
        );

    await (db.update(db.songs)..where((t) => t.id.equals('s2'))).write(
      const SongsCompanion(
        title: Value('New'),
        content: Value('{title: New}'),
        updatedAt: Value('2024-06-01T00:00:00.000Z'),
        dirty: Value(true),
      ),
    );

    final adapter = SongReplicationAdapter(db);
    final changes = await adapter.collectChanges();
    expect(changes, hasLength(1));
    expect(changes.first.newDocumentState['updatedAt'],
        '2024-06-01T00:00:00.000Z');
    expect(changes.first.assumedMasterState?['updatedAt'],
        '2024-01-01T00:00:00.000Z');
  });

  test('pull does not overwrite dirty local rows', () async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: 's3',
            title: 'Local edit',
            artist: 'Artist',
            content: '{title: Local}',
            path: 'Local.pro',
            createdAt: '2024-01-01T00:00:00.000Z',
            updatedAt: '2024-06-01T00:00:00.000Z',
            dirty: const Value(true),
            serverUpdatedAt: const Value('2024-01-01T00:00:00.000Z'),
          ),
        );

    final adapter = SongReplicationAdapter(db);
    await adapter.upsertFromWire([
      {
        'id': 's3',
        'title': 'Server old',
        'artist': 'Artist',
        'content': '{title: Server}',
        'path': 'Local.pro',
        'tags': <String>[],
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'isDeleted': false,
        'purgeAt': null,
        '_deleted': false,
      },
    ]);

    final row =
        await (db.select(db.songs)..where((t) => t.id.equals('s3'))).getSingle();
    expect(row.title, 'Local edit');
    expect(row.content, '{title: Local}');
    expect(row.dirty, isTrue);
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
    expect(rows.first.serverUpdatedAt, '2026-11-01T00:00:00.000Z');
  });
}
