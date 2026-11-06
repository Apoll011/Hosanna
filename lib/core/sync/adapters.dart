import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/tables.dart';
import 'replication_engine.dart';

/// Shared helpers for reading wire values defensively.
String _str(dynamic v, [String fallback = '']) =>
    v is String ? v : (v == null ? fallback : v.toString());

bool _bool(dynamic v) => v == true;

int? _int(dynamic v) => (v as num?)?.toInt();

String? _nullableStr(dynamic v) => v is String ? v : null;

List<String> _tags(dynamic v) {
  if (v is List) return v.whereType<String>().toList();
  return const [];
}

List<ServiceElement> _elements(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => ServiceElement.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// RxDB assumedMasterState: only id + last-known server updatedAt.
Map<String, dynamic>? _assumedMaster(String id, String? serverUpdatedAt) {
  if (serverUpdatedAt == null || serverUpdatedAt.isEmpty) return null;
  return {'id': id, 'updatedAt': serverUpdatedAt};
}

// ── Songs ──────────────────────────────────────────────────────────────────

class SongReplicationAdapter extends ReplicationAdapter {
  SongReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'songs';

  @override
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  }) async {
    final live = <Map<String, dynamic>>[];
    final tombstoneIds = <String>[];
    for (final d in docs) {
      if (_bool(d['_deleted'])) {
        tombstoneIds.add(_str(d['id']));
      } else {
        live.add(d);
      }
    }

    final dirtyIds = overwriteDirty
        ? const <String>{}
        : await _dirtySongIds();

    await _db.transaction(() async {
      if (tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.songs)..where((t) => t.id.isIn(tombstoneIds)))
            .go();
      }
      final toWrite = live
          .where((d) => !dirtyIds.contains(_str(d['id'])))
          .map(_songCompanion)
          .toList();
      if (toWrite.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.songs, toWrite);
        });
      }
    });
  }

  Future<Set<String>> _dirtySongIds() async {
    final rows = await (_db.select(_db.songs)
          ..where((t) => t.dirty.equals(true)))
        .get();
    return rows.map((r) => r.id).toSet();
  }

  SongsCompanion _songCompanion(Map<String, dynamic> d) {
    final updatedAt = _str(d['updatedAt']);
    return SongsCompanion.insert(
      id: _str(d['id']),
      title: _str(d['title']),
      artist: _str(d['artist'], 'Unknown Artist'),
      content: _str(d['content']),
      folderId: Value(_nullableStr(d['folderId'])),
      path: _str(d['path']),
      tags: Value(_tags(d['tags'])),
      songNumber: Value(_int(d['song_number'])),
      createdAt: _str(d['createdAt']),
      updatedAt: updatedAt,
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
      serverUpdatedAt: Value(updatedAt),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.songs)..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _songToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: _assumedMaster(r.id, r.serverUpdatedAt),
      );
    }).toList();
  }

  Map<String, dynamic> _songToWire(SongRow r) => {
        'id': r.id,
        'title': r.title,
        'artist': r.artist,
        'content': r.content,
        'folderId': r.folderId,
        'path': r.path,
        'tags': r.tags,
        'song_number': r.songNumber,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        // Soft-delete uses isDeleted + purgeAt. _deleted is only for
        // hard-delete tombstones (not used by this client yet).
        '_deleted': false,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs, overwriteDirty: true);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final rows =
        await (_db.select(_db.songs)..where((t) => t.id.isIn(list))).get();
    await _db.batch((b) {
      for (final r in rows) {
        b.update(
          _db.songs,
          SongsCompanion(
            dirty: const Value(false),
            serverUpdatedAt: Value(r.updatedAt),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }
}

// ── Folders ────────────────────────────────────────────────────────────────

class FolderReplicationAdapter extends ReplicationAdapter {
  FolderReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'folders';

  @override
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  }) async {
    final live = <Map<String, dynamic>>[];
    final tombstoneIds = <String>[];
    for (final d in docs) {
      if (_bool(d['_deleted'])) {
        tombstoneIds.add(_str(d['id']));
      } else {
        live.add(d);
      }
    }
    final dirtyIds = overwriteDirty
        ? const <String>{}
        : await _dirtyFolderIds();

    await _db.transaction(() async {
      if (tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.folders)..where((t) => t.id.isIn(tombstoneIds)))
            .go();
      }
      final toWrite = live
          .where((d) => !dirtyIds.contains(_str(d['id'])))
          .map(_folderCompanion)
          .toList();
      if (toWrite.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.folders, toWrite);
        });
      }
    });
  }

  Future<Set<String>> _dirtyFolderIds() async {
    final rows = await (_db.select(_db.folders)
          ..where((t) => t.dirty.equals(true)))
        .get();
    return rows.map((r) => r.id).toSet();
  }

  FoldersCompanion _folderCompanion(Map<String, dynamic> d) {
    final updatedAt = _str(d['updatedAt']);
    return FoldersCompanion.insert(
      id: _str(d['id']),
      name: _str(d['name']),
      color: Value(_str(d['color'], 'default')),
      icon: Value(_str(d['icon'], 'default')),
      parentId: Value(_nullableStr(d['parentId'])),
      createdAt: _str(d['createdAt']),
      updatedAt: updatedAt,
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
      serverUpdatedAt: Value(updatedAt),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.folders)..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _folderToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: _assumedMaster(r.id, r.serverUpdatedAt),
      );
    }).toList();
  }

  Map<String, dynamic> _folderToWire(FolderRow r) => {
        'id': r.id,
        'name': r.name,
        'color': r.color,
        'icon': r.icon,
        'parentId': r.parentId,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        '_deleted': false,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs, overwriteDirty: true);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final rows =
        await (_db.select(_db.folders)..where((t) => t.id.isIn(list))).get();
    await _db.batch((b) {
      for (final r in rows) {
        b.update(
          _db.folders,
          FoldersCompanion(
            dirty: const Value(false),
            serverUpdatedAt: Value(r.updatedAt),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }

  @override
  Future<void> refreshLocalCounts() async {
    final songs = await (_db.select(_db.songs)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final songsPerFolder = <String, int>{};
    for (final song in songs) {
      final folderId = song.folderId;
      if (folderId != null) {
        songsPerFolder[folderId] = (songsPerFolder[folderId] ?? 0) + 1;
      }
    }

    final folders = await (_db.select(_db.folders)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final childFoldersPerFolder = <String, int>{};
    for (final folder in folders) {
      final parentId = folder.parentId;
      if (parentId != null) {
        childFoldersPerFolder[parentId] =
            (childFoldersPerFolder[parentId] ?? 0) + 1;
      }
    }

    await _db.batch((b) {
      for (final folder in folders) {
        final songCount = songsPerFolder[folder.id] ?? 0;
        final folderCount = childFoldersPerFolder[folder.id] ?? 0;
        if (songCount == folder.songCount && folderCount == folder.folderCount) {
          continue;
        }
        b.update(
          _db.folders,
          FoldersCompanion(
            songCount: Value(songCount),
            folderCount: Value(folderCount),
          ),
          where: (t) => t.id.equals(folder.id),
        );
      }
    });
  }
}

// ── Collections ─────────────────────────────────────────────────────────────

class CollectionReplicationAdapter extends ReplicationAdapter {
  CollectionReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'collections';

  @override
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  }) async {
    final live = <Map<String, dynamic>>[];
    final tombstoneIds = <String>[];
    for (final d in docs) {
      if (_bool(d['_deleted'])) {
        tombstoneIds.add(_str(d['id']));
      } else {
        live.add(d);
      }
    }
    final dirtyIds = overwriteDirty
        ? const <String>{}
        : await _dirtyCollectionIds();

    await _db.transaction(() async {
      if (tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.collections)
              ..where((t) => t.id.isIn(tombstoneIds)))
            .go();
      }
      final toWrite = live
          .where((d) => !dirtyIds.contains(_str(d['id'])))
          .map(_collectionCompanion)
          .toList();
      if (toWrite.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.collections, toWrite);
        });
      }
    });
  }

  Future<Set<String>> _dirtyCollectionIds() async {
    final rows = await (_db.select(_db.collections)
          ..where((t) => t.dirty.equals(true)))
        .get();
    return rows.map((r) => r.id).toSet();
  }

  CollectionsCompanion _collectionCompanion(Map<String, dynamic> d) {
    final updatedAt = _str(d['updatedAt']);
    return CollectionsCompanion.insert(
      id: _str(d['id']),
      name: _str(d['name']),
      description: Value(_nullableStr(d['description'])),
      color: Value(_str(d['color'], 'default')),
      icon: Value(_str(d['icon'], 'default')),
      image: Value(_nullableStr(d['image'])),
      songIds: Value(_tags(d['songIds'])),
      createdAt: _str(d['createdAt']),
      updatedAt: updatedAt,
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
      serverUpdatedAt: Value(updatedAt),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.collections)
      ..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _collectionToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: _assumedMaster(r.id, r.serverUpdatedAt),
      );
    }).toList();
  }

  Map<String, dynamic> _collectionToWire(CollectionRow r) => {
        'id': r.id,
        'name': r.name,
        'description': r.description,
        'color': r.color,
        'icon': r.icon,
        'image': r.image,
        'songIds': r.songIds,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        '_deleted': false,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs, overwriteDirty: true);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final rows = await (_db.select(_db.collections)
          ..where((t) => t.id.isIn(list)))
        .get();
    await _db.batch((b) {
      for (final r in rows) {
        b.update(
          _db.collections,
          CollectionsCompanion(
            dirty: const Value(false),
            serverUpdatedAt: Value(r.updatedAt),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }

  @override
  Future<void> refreshLocalCounts() async {
    final collections = await (_db.select(_db.collections)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final songs = await (_db.select(_db.songs)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final songIds = songs.map((s) => s.id).toSet();

    await _db.batch((b) {
      for (final collection in collections) {
        final songCount = collection.songIds.where(songIds.contains).length;
        if (songCount == collection.songCount) continue;
        b.update(
          _db.collections,
          CollectionsCompanion(songCount: Value(songCount)),
          where: (t) => t.id.equals(collection.id),
        );
      }
    });
  }
}

// ── Services ───────────────────────────────────────────────────────────────

class ServiceReplicationAdapter extends ReplicationAdapter {
  ServiceReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'services';

  @override
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  }) async {
    final live = <Map<String, dynamic>>[];
    final tombstoneIds = <String>[];
    for (final d in docs) {
      if (_bool(d['_deleted'])) {
        tombstoneIds.add(_str(d['id']));
      } else {
        live.add(d);
      }
    }
    final dirtyIds = overwriteDirty
        ? const <String>{}
        : await _dirtyServiceIds();

    await _db.transaction(() async {
      if (tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.services)..where((t) => t.id.isIn(tombstoneIds)))
            .go();
      }
      final toWrite = live
          .where((d) => !dirtyIds.contains(_str(d['id'])))
          .map(_serviceCompanion)
          .toList();
      if (toWrite.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.services, toWrite);
        });
      }
    });
  }

  Future<Set<String>> _dirtyServiceIds() async {
    final rows = await (_db.select(_db.services)
          ..where((t) => t.dirty.equals(true)))
        .get();
    return rows.map((r) => r.id).toSet();
  }

  ServicesCompanion _serviceCompanion(Map<String, dynamic> d) {
    final updatedAt = _str(d['updatedAt']);
    return ServicesCompanion.insert(
      id: _str(d['id']),
      name: _str(d['name']),
      date: _str(d['date']),
      notes: Value(_nullableStr(d['notes'])),
      elements: Value(_elements(d['elements'])),
      archived: Value(_bool(d['archived'])),
      createdAt: _str(d['createdAt']),
      updatedAt: updatedAt,
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
      serverUpdatedAt: Value(updatedAt),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.services)..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _serviceToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: _assumedMaster(r.id, r.serverUpdatedAt),
      );
    }).toList();
  }

  Map<String, dynamic> _serviceToWire(ServiceRow r) => {
        'id': r.id,
        'name': r.name,
        'date': r.date,
        'notes': r.notes,
        'elements': r.elements.map((e) => e.toJson()).toList(),
        'archived': r.archived,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        '_deleted': false,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs, overwriteDirty: true);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final rows =
        await (_db.select(_db.services)..where((t) => t.id.isIn(list))).get();
    await _db.batch((b) {
      for (final r in rows) {
        b.update(
          _db.services,
          ServicesCompanion(
            dirty: const Value(false),
            serverUpdatedAt: Value(r.updatedAt),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }
}

// ── Agenda events ──────────────────────────────────────────────────────────

class AgendaEventReplicationAdapter extends ReplicationAdapter {
  AgendaEventReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'agendaEvents';

  @override
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  }) async {
    final live = <Map<String, dynamic>>[];
    final tombstoneIds = <String>[];
    for (final d in docs) {
      if (_bool(d['_deleted'])) {
        tombstoneIds.add(_str(d['id']));
      } else {
        live.add(d);
      }
    }
    final dirtyIds = overwriteDirty
        ? const <String>{}
        : await _dirtyAgendaIds();

    await _db.transaction(() async {
      if (tombstoneIds.isNotEmpty) {
        await (_db.delete(_db.agendaEvents)
              ..where((t) => t.id.isIn(tombstoneIds)))
            .go();
      }
      final toWrite = live
          .where((d) => !dirtyIds.contains(_str(d['id'])))
          .map(_agendaCompanion)
          .toList();
      if (toWrite.isNotEmpty) {
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.agendaEvents, toWrite);
        });
      }
    });
  }

  Future<Set<String>> _dirtyAgendaIds() async {
    final rows = await (_db.select(_db.agendaEvents)
          ..where((t) => t.dirty.equals(true)))
        .get();
    return rows.map((r) => r.id).toSet();
  }

  AgendaEventsCompanion _agendaCompanion(Map<String, dynamic> d) {
    final updatedAt = _str(d['updatedAt']);
    return AgendaEventsCompanion.insert(
      id: _str(d['id']),
      date: _str(d['date']),
      title: _str(d['title']),
      type: _str(d['type'], 'event'),
      time: _str(d['time'], '00:00'),
      durationMinutes: Value(_int(d['durationMinutes']) ?? 0),
      location: Value(_nullableStr(d['location'])),
      notes: Value(_nullableStr(d['notes'])),
      reminder: Value(d['reminder'] ?? const {'enabled': false, 'label': ''}),
      linkedServiceId: Value(_nullableStr(d['linkedServiceId'])),
      responsibilities: Value(d['responsibilities'] ?? const []),
      createdAt: _str(d['createdAt']),
      updatedAt: updatedAt,
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
      serverUpdatedAt: Value(updatedAt),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.agendaEvents)
      ..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _agendaToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: _assumedMaster(r.id, r.serverUpdatedAt),
      );
    }).toList();
  }

  Map<String, dynamic> _agendaToWire(AgendaEventRow r) => {
        'id': r.id,
        'date': r.date,
        'title': r.title,
        'type': r.type,
        'time': r.time,
        'durationMinutes': r.durationMinutes,
        'location': r.location,
        'notes': r.notes,
        'reminder': r.reminder,
        'linkedServiceId': r.linkedServiceId,
        'responsibilities': r.responsibilities,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        '_deleted': false,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs, overwriteDirty: true);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final rows = await (_db.select(_db.agendaEvents)
          ..where((t) => t.id.isIn(list)))
        .get();
    await _db.batch((b) {
      for (final r in rows) {
        b.update(
          _db.agendaEvents,
          AgendaEventsCompanion(
            dirty: const Value(false),
            serverUpdatedAt: Value(r.updatedAt),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }
}
