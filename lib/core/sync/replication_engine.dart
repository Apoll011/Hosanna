import 'package:shared_preferences/shared_preferences.dart';

import '../network/hosanna_api.dart';

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
}

/// Resource-specific adapter bridging a wire document collection and its
/// local Drift table. The engine owns the loop + checkpoints; adapters own the
/// mapping.
abstract class ReplicationAdapter {
  /// `songs` | `folders` | `collections` | `services`.
  String get resourceName;

  /// Upsert a batch of pulled wire documents into the local table.
  ///
  /// When [overwriteDirty] is false (pull), locally dirty rows are left alone
  /// so an in-flight edit is not wiped by an older server snapshot.
  Future<void> upsertFromWire(
    List<Map<String, dynamic>> docs, {
    bool overwriteDirty = false,
  });

  /// Collect locally-created/modified/deleted rows since the last push.
  Future<List<ChangeRow>> collectChanges();

  /// Server-wins reconciliation: overwrite local rows with the returned
  /// conflicting server documents (including dirty ones).
  Future<void> applyServerConflicts(List<Map<String, dynamic>> serverDocs);

  /// Clear the dirty flag for rows the server has accepted and advance the
  /// local server-updatedAt baseline to the pushed value.
  Future<void> markPushed(Iterable<String> ids);

  /// Recompute locally-derived values that are never replicated (e.g. folder
  /// and collection song counts). Defaults to a no-op for resources without
  /// any such values.
  Future<void> refreshLocalCounts() async {}
}

/// Generic, resource-agnostic pull/push engine for every replicated
/// collection. Uses OpenAPI `pullCollection` / `pushCollection`.
class ReplicationEngine {
  ReplicationEngine({
    required this.api,
    required this.prefs,
    required this.adapters,
  });

  static const int batchLimit = 100;

  final HosannaApi api;
  final SharedPreferences prefs;
  final List<ReplicationAdapter> adapters;

  String _checkpointKey(String resource) => 'replication.checkpoint.$resource';

  /// When [shouldContinue] returns false (e.g. a newer org-switch epoch), stop
  /// before the next network round-trip / checkpoint write so a superseded
  /// pull cannot leave a foreign tenant's cursor on disk.
  Future<void> pullAll({bool Function()? shouldContinue}) async {
    for (final adapter in adapters) {
      if (shouldContinue != null && !shouldContinue()) return;
      await pullOne(adapter, shouldContinue: shouldContinue);
    }
    if (shouldContinue != null && !shouldContinue()) return;
    // Counts are derived from the other tables, so resolve them only once the
    // full pull (songs included) has landed.
    for (final adapter in adapters) {
      if (shouldContinue != null && !shouldContinue()) return;
      await adapter.refreshLocalCounts();
    }
  }

  Future<void> pullOne(
    ReplicationAdapter adapter, {
    bool Function()? shouldContinue,
  }) async {
    var checkpoint = await _loadCheckpoint(adapter.resourceName);
    final collection = replicationCollectionFor(adapter.resourceName);

    while (true) {
      if (shouldContinue != null && !shouldContinue()) return;

      final data = await api.replication.pullCollection(
        collection: collection,
        pullRequest: PullRequest(
          checkpoint: checkpoint?.toJson(),
          limit: batchLimit,
        ),
      );

      if (shouldContinue != null && !shouldContinue()) return;

      final docs = data.documents;

      if (docs.isNotEmpty) {
        await adapter.upsertFromWire(docs);
      }

      if (shouldContinue != null && !shouldContinue()) return;

      final next = ReplicationCheckpoint.fromJson(data.checkpoint);
      if (next != null) {
        checkpoint = next;
        await _saveCheckpoint(adapter.resourceName, checkpoint);
      }

      // A short batch means the server has no more rows after this one.
      if (docs.length < batchLimit) break;
    }
  }

  Future<void> pushAll({bool Function()? shouldContinue}) async {
    for (final adapter in adapters) {
      if (shouldContinue != null && !shouldContinue()) return;
      await pushOne(adapter, shouldContinue: shouldContinue);
    }
  }

  Future<void> pushOne(
    ReplicationAdapter adapter, {
    bool Function()? shouldContinue,
  }) async {
    final changes = await adapter.collectChanges();
    if (changes.isEmpty) return;

    final collection = replicationCollectionFor(adapter.resourceName);

    // Server caps push batches at 100 rows.
    for (var i = 0; i < changes.length; i += batchLimit) {
      if (shouldContinue != null && !shouldContinue()) return;

      final chunk = changes.sublist(
        i,
        i + batchLimit > changes.length ? changes.length : i + batchLimit,
      );

      final conflicts = await api.replication.pushCollection(
        collection: collection,
        changeRows: chunk
            .map(
              (c) => ChangeRowBody(
                newDocumentState: c.newDocumentState,
                assumedMasterState: c.assumedMasterState,
              ),
            )
            .toList(),
      );

      if (shouldContinue != null && !shouldContinue()) return;

      final conflictIds = <String>{};
      if (conflicts.isNotEmpty) {
        for (final doc in conflicts) {
          final id = doc['id'];
          if (id is String && id.isNotEmpty) conflictIds.add(id);
        }
        await adapter.applyServerConflicts(conflicts);
      }

      // Only clear dirty on rows the server accepted — conflicted rows stay
      // dirty after applying the server snapshot (dirty cleared by upsert).
      final accepted =
          chunk.map((c) => c.id).where((id) => !conflictIds.contains(id));
      await adapter.markPushed(accepted);
    }
  }

  /// Drops every resource checkpoint so the next pull starts from scratch
  /// (required after switching organizations).
  Future<void> clearAllCheckpoints() async {
    for (final adapter in adapters) {
      await prefs.remove(_checkpointKey(adapter.resourceName));
    }
  }

  Future<ReplicationCheckpoint?> _loadCheckpoint(String resource) async {
    final raw = prefs.getString(_checkpointKey(resource));
    if (raw == null || raw.isEmpty) return null;
    return ReplicationCheckpoint.fromJson(
      _prefsToJson(raw),
    );
  }

  Future<void> _saveCheckpoint(
    String resource,
    ReplicationCheckpoint checkpoint,
  ) async {
    await prefs.setString(
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
