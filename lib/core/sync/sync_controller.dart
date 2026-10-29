import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../network/api_exception.dart';
import 'adapters.dart';
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
  SyncController(this._engine, this._prefs, this._clearLocalData)
      : super(const SyncState());

  static const _lastSyncedKey = 'sync.lastSyncedAt';

  final ReplicationEngine _engine;
  final SharedPreferences _prefs;
  final Future<void> Function() _clearLocalData;

  DateTime? get lastSyncedAt => state.lastSyncedAt;

  void restore() {
    final millis = _prefs.getInt(_lastSyncedKey);
    if (millis != null) {
      state = state.copyWith(
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      );
    }
  }

  /// Full pull + push cycle for every replicated resource.
  Future<void> syncAll() async {
    if (state.isSyncing) return;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);

    try {
      await _engine.pullAll();
      await _engine.pushAll();

      final now = DateTime.now();
      await _prefs.setInt(_lastSyncedKey, now.millisecondsSinceEpoch);
      state = state.copyWith(status: SyncStatus.synced, lastSyncedAt: now);
    } on ApiException catch (e) {
      state = state.copyWith(
        status: e.isNetworkError ? SyncStatus.offline : SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears local tenant data + checkpoints, then pulls (and only then pushes)
  /// for the newly active organization. Call this on org switch.
  Future<void> resetForOrganizationSwitch() async {
    if (state.isSyncing) return;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      await _clearLocalData();
      await _engine.clearAllCheckpoints();
      await _prefs.remove(_lastSyncedKey);
      await _engine.pullAll();
      // Push only after a clean pull so dirty rows from the previous org
      // cannot be uploaded against the new tenant.
      await _engine.pushAll();
      final now = DateTime.now();
      await _prefs.setInt(_lastSyncedKey, now.millisecondsSinceEpoch);
      state = state.copyWith(status: SyncStatus.synced, lastSyncedAt: now);
    } on ApiException catch (e) {
      state = state.copyWith(
        status: e.isNetworkError ? SyncStatus.offline : SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
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
    ServiceReplicationAdapter(db),
  ];
});

final replicationEngineProvider = Provider<ReplicationEngine>((ref) {
  return ReplicationEngine(
    dio: ref.watch(dioProvider),
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
      () => db.clearAllReplicatedData(),
    );
  },
);
