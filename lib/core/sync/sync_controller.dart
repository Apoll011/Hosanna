import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../db/database.dart';
import '../network/api_exception.dart';
import 'adapters.dart';
import 'purge_expired_trash.dart';
import 'replication_engine.dart';

enum SyncStatus { idle, syncing, synced, error, offline }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SyncController extends StateNotifier<SyncState> {
  SyncController(
    this._engine,
    this._prefs,
    this._db,
    this._clearLocalData,
  ) : super(const SyncState());

  static const _lastSyncedKey = 'sync.lastSyncedAt';

  final ReplicationEngine _engine;
  final SharedPreferences _prefs;
  final AppDatabase _db;
  final Future<void> Function() _clearLocalData;

  /// Bumped on every org-switch reset. In-flight sync/reset work that sees a
  /// newer epoch aborts so a fast A→B→C switch cannot leave B's rows under C.
  int _orgEpoch = 0;

  /// Serializes sync/reset so clear+pull never interleave across switches.
  Future<void> _chain = Future<void>.value();

  DateTime? get lastSyncedAt => state.lastSyncedAt;

  void restore() {
    final millis = _prefs.getInt(_lastSyncedKey);
    if (millis != null) {
      state = state.copyWith(
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      );
    }
  }

  /// Completes when the sync/reset queue is idle (including work scheduled
  /// during this call's turn of the event loop via [Future.microtask]).
  Future<void> waitUntilIdle() => _chain;

  Future<void> _enqueue(Future<void> Function() op) {
    final run = _chain.then((_) => op());
    // Keep the chain alive after errors so later ops still run.
    _chain = run.catchError((Object _) {});
    return run;
  }

  /// Full push + pull cycle for every replicated resource.
  ///
  /// Push runs first (same order as Studio) so local edits are uploaded before
  /// a pull can apply an older server snapshot over dirty rows.
  Future<void> syncAll() {
    final epoch = _orgEpoch;
    return _enqueue(() => _syncAllBody(epoch));
  }

  Future<void> _syncAllBody(int epoch) async {
    // An org switch started after this sync was requested — skip so we do not
    // push the previous church's dirty rows into the new tenant.
    if (epoch != _orgEpoch) return;

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);

    try {
      await _engine.pushAll();
      if (epoch != _orgEpoch) return;
      await _engine.pullAll();
      if (epoch != _orgEpoch) return;
      await purgeExpiredTrash(_db);
      if (epoch != _orgEpoch) return;

      final now = DateTime.now();
      await _prefs.setInt(_lastSyncedKey, now.millisecondsSinceEpoch);
      if (epoch != _orgEpoch) return;
      state = state.copyWith(status: SyncStatus.synced, lastSyncedAt: now);
    } on ApiException catch (e) {
      if (epoch != _orgEpoch) return;
      state = state.copyWith(
        status: e.isNetworkError ? SyncStatus.offline : SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (epoch != _orgEpoch) return;
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears local tenant data + checkpoints, then pulls (and only then pushes)
  /// for the newly active organization. Call this on org switch.
  ///
  /// Safe under rapid switching: each call bumps an epoch, work is serialized,
  /// and superseded epochs exit without writing a "synced" result for a stale
  /// tenant. Unlike the previous `if (isSyncing) return`, a switch while a
  /// sync is running is never dropped.
  Future<void> resetForOrganizationSwitch() {
    final epoch = ++_orgEpoch;
    return _enqueue(() => _resetBody(epoch));
  }

  Future<void> _resetBody(int epoch) async {
    // A newer switch was already queued after us — skip this entire reset.
    if (epoch != _orgEpoch) return;

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      // Wipe first so the UI stops showing the previous church immediately.
      await _clearLocalData();
      if (epoch != _orgEpoch) return;

      await _engine.clearAllCheckpoints();
      await _prefs.remove(_lastSyncedKey);
      if (epoch != _orgEpoch) return;

      // Empty local DB after org switch — pull the new tenant first.
      await _engine.pullAll();
      if (epoch != _orgEpoch) return;

      await purgeExpiredTrash(_db);
      if (epoch != _orgEpoch) return;

      await _engine.pushAll();
      if (epoch != _orgEpoch) return;

      final now = DateTime.now();
      await _prefs.setInt(_lastSyncedKey, now.millisecondsSinceEpoch);
      if (epoch != _orgEpoch) return;
      state = state.copyWith(status: SyncStatus.synced, lastSyncedAt: now);
    } on ApiException catch (e) {
      if (epoch != _orgEpoch) return;
      state = state.copyWith(
        status: e.isNetworkError ? SyncStatus.offline : SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (epoch != _orgEpoch) return;
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final replicationAdaptersProvider = Provider<List<ReplicationAdapter>>((ref) {
  final db = ref.watch(databaseProvider);
  return [
    SongReplicationAdapter(db),
    FolderReplicationAdapter(db),
    CollectionReplicationAdapter(db),
    // Services before agendaEvents (FK: linkedServiceId).
    ServiceReplicationAdapter(db),
    AgendaEventReplicationAdapter(db),
  ];
});

final replicationEngineProvider = Provider<ReplicationEngine>((ref) {
  return ReplicationEngine(
    api: ref.watch(hosannaApiProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    adapters: ref.watch(replicationAdaptersProvider),
  );
});

final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>(
  (ref) {
    final db = ref.watch(databaseProvider);
    return SyncController(
      ref.watch(replicationEngineProvider),
      ref.watch(sharedPreferencesProvider),
      db,
      () => db.clearAllReplicatedData(),
    );
  },
);
