import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RxDB-style replication checkpoint: `{ updatedAt: epoch-ms, id: string }`.
class ReplicationCheckpoint {
  const ReplicationCheckpoint({required this.updatedAt, required this.id});

  final int updatedAt;
  final String id;

  Map<String, dynamic> toJson() => {'updatedAt': updatedAt, 'id': id};

  static ReplicationCheckpoint? fromJson(dynamic json) {
    if (json is! Map) return null;
    final updatedAt = (json['updatedAt'] as num?)?.toInt();
    final id = json['id'] as String?;
    if (updatedAt == null || id == null) return null;
    return ReplicationCheckpoint(updatedAt: updatedAt, id: id);
  }
}

/// One row of a push batch: the new local state plus the last-known server
/// state used for conflict detection.
class ChangeRow {
  const ChangeRow({
    required this.id,
    required this.newDocumentState,
    this.assumedMasterState,
  });

  final String id;
  final Map<String, dynamic> newDocumentState;
  final Map<String, dynamic>? assumedMasterState;

  Map<String, dynamic> toJson() => {
        'newDocumentState': newDocumentState,
        'assumedMasterState': assumedMasterState,
      };
}

/// Resource-specific adapter bridging a wire document collection and its
/// local Drift table. The engine owns the loop + checkpoints; adapters own the
/// mapping.
abstract class ReplicationAdapter {
  /// `songs` | `folders` | `services`.
  String get resourceName;

  /// Upsert a batch of pulled wire documents into the local table.
  Future<void> upsertFromWire(List<Map<String, dynamic>> docs);

  /// Collect locally-created/modified/deleted rows since the last push.
  Future<List<ChangeRow>> collectChanges();

  /// Server-wins reconciliation: overwrite local rows with the returned
  /// conflicting server documents.
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs);

  /// Clear the dirty flag for rows the server has accepted.
  Future<void> markPushed(Iterable<String> ids);
}

/// Generic, resource-agnostic pull/push engine for the three replicated
/// collections. Mirrors the exact `/api/replication/{resource}/{pull|push}`
/// contract confirmed in the Hosanna server (`replication.service.ts`).
class ReplicationEngine {
  ReplicationEngine({
    required this._dio,
    required this._prefs,
    required this._adapters,
  });

  static const int batchLimit = 100;

  final Dio _dio;
  final SharedPreferences _prefs;
  final List<ReplicationAdapter> _adapters;

  String _checkpointKey(String resource) => 'replication.checkpoint.$resource';

  Future<void> pullAll() async {
    for (final adapter in _adapters) {
      await pullOne(adapter);
    }
  }

  Future<void> pullOne(ReplicationAdapter adapter) async {
    var checkpoint = await _loadCheckpoint(adapter.resourceName);

    while (true) {
      final res = await _dio.post<dynamic>(
        '/api/replication/${adapter.resourceName}/pull',
        data: {
          'checkpoint': checkpoint?.toJson(),
          'limit': batchLimit,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final docs = (data['documents'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (docs.isNotEmpty) {
        await adapter.upsertFromWire(docs);
      }

      final next = ReplicationCheckpoint.fromJson(data['checkpoint']);
      if (next != null) {
        checkpoint = next;
        await _saveCheckpoint(adapter.resourceName, checkpoint);
      }

      // A short batch means the server has no more rows after this one.
      if (docs.length < batchLimit) break;
    }
  }

  Future<void> pushAll() async {
    for (final adapter in _adapters) {
      await pushOne(adapter);
    }
  }

  Future<void> pushOne(ReplicationAdapter adapter) async {
    final changes = await adapter.collectChanges();
    if (changes.isEmpty) return;

    // Server caps push batches at 100 rows.
    for (var i = 0; i < changes.length; i += batchLimit) {
      final chunk = changes.sublist(
        i,
        i + batchLimit > changes.length ? changes.length : i + batchLimit,
      );

      final res = await _dio.post<dynamic>(
        '/api/replication/${adapter.resourceName}/push',
        data: {
          'changeRows': chunk.map((c) => c.toJson()).toList(),
        },
      );

      final conflicts = (res.data as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (conflicts.isNotEmpty) {
        await adapter.applyServerConflicts(conflicts);
      }
    }

    await adapter.markPushed(changes.map((c) => c.id));
  }

  Future<ReplicationCheckpoint?> _loadCheckpoint(String resource) async {
    final raw = _prefs.getString(_checkpointKey(resource));
    if (raw == null || raw.isEmpty) return null;
    return ReplicationCheckpoint.fromJson(
      _prefsToJson(raw),
    );
  }

  Future<void> _saveCheckpoint(
    String resource,
    ReplicationCheckpoint checkpoint,
  ) async {
    await _prefs.setString(
      _checkpointKey(resource),
      '${checkpoint.updatedAt}|${checkpoint.id}',
    );
  }

  static Map<String, dynamic> _prefsToJson(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return const {};
    return {
      'updatedAt': int.tryParse(parts[0]),
      'id': parts[1],
    };
  }
}
