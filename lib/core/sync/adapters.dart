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

// ── Songs ──────────────────────────────────────────────────────────────────

class SongReplicationAdapter extends ReplicationAdapter {
  SongReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'songs';

  @override
  Future<void> upsertFromWire(List<Map<String, dynamic>> docs) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.songs,
        docs.map(_songCompanion).toList(),
      );
    });
  }

  SongsCompanion _songCompanion(Map<String, dynamic> d) {
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
      updatedAt: _str(d['updatedAt']),
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.songs)
      ..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _songToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: wire,
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
        '_deleted': r.isDeleted,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final stmt = _db.update(_db.songs)..where((t) => t.id.isIn(list));
    await stmt.write(const SongsCompanion(dirty: Value(false)));
  }
}

// ── Folders ────────────────────────────────────────────────────────────────

class FolderReplicationAdapter extends ReplicationAdapter {
  FolderReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'folders';

  @override
  Future<void> upsertFromWire(List<Map<String, dynamic>> docs) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.folders,
        docs.map(_folderCompanion).toList(),
      );
    });
  }

  FoldersCompanion _folderCompanion(Map<String, dynamic> d) {
    return FoldersCompanion.insert(
      id: _str(d['id']),
      name: _str(d['name']),
      color: Value(_str(d['color'], 'default')),
      icon: Value(_str(d['icon'], 'default')),
      parentId: Value(_nullableStr(d['parentId'])),
      songCount: Value(_int(d['songCount']) ?? 0),
      folderCount: Value(_int(d['folderCount']) ?? 0),
      createdAt: _str(d['createdAt']),
      updatedAt: _str(d['updatedAt']),
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.folders)
      ..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _folderToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: wire,
      );
    }).toList();
  }

  Map<String, dynamic> _folderToWire(FolderRow r) => {
        'id': r.id,
        'name': r.name,
        'color': r.color,
        'icon': r.icon,
        'parentId': r.parentId,
        'songCount': r.songCount,
        'folderCount': r.folderCount,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'isDeleted': r.isDeleted,
        'purgeAt': r.purgeAt,
        '_deleted': r.isDeleted,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final stmt = _db.update(_db.folders)..where((t) => t.id.isIn(list));
    await stmt.write(const FoldersCompanion(dirty: Value(false)));
  }
}

// ── Services ───────────────────────────────────────────────────────────────

class ServiceReplicationAdapter extends ReplicationAdapter {
  ServiceReplicationAdapter(this._db);

  final AppDatabase _db;

  @override
  String get resourceName => 'services';

  @override
  Future<void> upsertFromWire(List<Map<String, dynamic>> docs) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.services,
        docs.map(_serviceCompanion).toList(),
      );
    });
  }

  ServicesCompanion _serviceCompanion(Map<String, dynamic> d) {
    return ServicesCompanion.insert(
      id: _str(d['id']),
      name: _str(d['name']),
      date: _str(d['date']),
      notes: Value(_nullableStr(d['notes'])),
      elements: Value(_elements(d['elements'])),
      archived: Value(_bool(d['archived'])),
      createdAt: _str(d['createdAt']),
      updatedAt: _str(d['updatedAt']),
      isDeleted: Value(_bool(d['isDeleted'])),
      dirty: const Value(false),
      purgeAt: Value(_nullableStr(d['purgeAt'])),
    );
  }

  @override
  Future<List<ChangeRow>> collectChanges() async {
    final query = _db.select(_db.services)
      ..where((t) => t.dirty.equals(true));
    final rows = await query.get();
    return rows.map((r) {
      final wire = _serviceToWire(r);
      return ChangeRow(
        id: r.id,
        newDocumentState: wire,
        assumedMasterState: wire,
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
        '_deleted': r.isDeleted,
      };

  @override
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs) =>
      upsertFromWire(serverDocs);

  @override
  Future<void> markPushed(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final stmt = _db.update(_db.services)..where((t) => t.id.isIn(list));
    await stmt.write(const ServicesCompanion(dirty: Value(false)));
  }
}
