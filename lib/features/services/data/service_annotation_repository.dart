// lib/services/data/service_annotation_repository.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client_provider.dart';

/// Result of a remote annotation fetch — bytes plus the version they were
/// stored at, so callers can detect stale/duplicate realtime events.
class RemoteAnnotation {
  const RemoteAnnotation({required this.bytes, required this.version});
  final Uint8List bytes;
  final int version;
}

class ServiceAnnotationRepository {
  ServiceAnnotationRepository(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'service_song_annotations';

  String _key(String serviceId, String songId) => '$serviceId:$songId';

  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'annotations'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileName(String serviceId, String songId) =>
      'annotation_${serviceId}_$songId.fcv';

  Future<Uint8List?> loadAnnotation({
    required String serviceId,
    required String songId,
  }) async {
    try {
      final dir = await _getStorageDir();
      final file = File(p.join(dir.path, _fileName(serviceId, songId)));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveAnnotation({
    required String serviceId,
    required String songId,
    required Uint8List bytes,
  }) async {
    try {
      final dir = await _getStorageDir();
      final file = File(p.join(dir.path, _fileName(serviceId, songId)));
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<void> deleteAnnotation({
    required String serviceId,
    required String songId,
  }) async {
    try {
      final dir = await _getStorageDir();
      final file = File(p.join(dir.path, _fileName(serviceId, songId)));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // --- Supabase sync (only used when syncAnnotations setting is on) -------

  /// Fetches the current row from Supabase and refreshes the local cache.
  /// Returns null if there's no remote row yet, or the fetch failed (e.g.
  /// offline) — callers should fall back to [loadAnnotation].
  Future<RemoteAnnotation?> fetchRemoteAnnotation({
    required String workspaceId,
    required String serviceId,
    required String songId,
  }) async {
    try {
      final row = await _supabase
          .from(_table)
          .select('canvas_data_b64, version')
          .eq('workspace_id', workspaceId)
          .eq('service_song_key', _key(serviceId, songId))
          .maybeSingle();

      if (row == null) return null;

      final bytes = base64Decode(row['canvas_data_b64'] as String);
      final version = row['version'] as int;

      // Keep the local cache warm for instant offline loads next time.
      await saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

      return RemoteAnnotation(bytes: bytes, version: version);
    } catch (_) {
      return null;
    }
  }

  /// Upserts the annotation to Supabase. Does NOT touch the local cache —
  /// callers should already have written it locally before calling this.
  /// Throws on failure (e.g. offline) so the caller can decide how to react.
  Future<int> pushAnnotation({
    required String workspaceId,
    required String serviceId,
    required String songId,
    required Uint8List bytes,
    required String? updatedBy,
    required int baseVersion,
  }) async {
    final nextVersion = baseVersion + 1;

    await _supabase.from(_table).upsert({
      'workspace_id': workspaceId,
      'service_id': serviceId,
      'song_id': songId,
      'service_song_key': _key(serviceId, songId),
      'canvas_data_b64': base64Encode(bytes),
      'version': nextVersion,
      'updated_by': updatedBy,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'workspace_id,service_id,song_id');

    return nextVersion;
  }

  /// Subscribes to remote changes for a single song's annotation. Call
  /// [unsubscribe] with the returned channel on song change / dispose /
  /// when sync is turned off.
  RealtimeChannel subscribeToAnnotationUpdates({
    required String workspaceId,
    required String serviceId,
    required String songId,
    required void Function(Uint8List bytes, int version) onRemoteUpdate,
  }) {
    final channel = _supabase.channel('annotation-${_key(serviceId, songId)}');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'service_song_key',
            value: _key(serviceId, songId),
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            if (record['workspace_id'] != workspaceId) return;

            final b64 = record['canvas_data_b64'] as String?;
            final version = record['version'] as int?;
            if (b64 == null || version == null) return;

            onRemoteUpdate(base64Decode(b64), version);
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) {
    return _supabase.removeChannel(channel);
  }
}

final serviceAnnotationRepositoryProvider =
    Provider<ServiceAnnotationRepository>((ref) {
      return ServiceAnnotationRepository(ref.watch(supabaseClientProvider));
    });

final serviceAnnotationBytesProvider =
    FutureProvider.family<Uint8List?, ({String serviceId, String songId})>((
      ref,
      args,
    ) async {
      final repo = ref.watch(serviceAnnotationRepositoryProvider);
      return repo.loadAnnotation(
        serviceId: args.serviceId,
        songId: args.songId,
      );
    });
