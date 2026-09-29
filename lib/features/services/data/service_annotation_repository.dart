import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RemoteAnnotation {
  const RemoteAnnotation({
    required this.bytes,
    required this.updatedAt,
    this.updatedById,
    this.revision,
  });

  final Uint8List bytes;
  final DateTime updatedAt;
  final String? updatedById;
  final int? revision;
}

/// Handle returned by [ServiceAnnotationRepository.subscribeToAnnotationUpdates].
class AnnotationSyncHandle {
  AnnotationSyncHandle({
    required this.cancel,
  });

  final Future<void> Function() cancel;
}

/// Local `.fcv` cache + Firestore-backed live sync for service song annotations.
///
/// Writes go through the Hosanna API (Admin → Firestore metadata / inline
/// bytes; large canvases stay in Postgres). Reads use Firestore first with a
/// REST fallback. Live updates use a Firestore snapshot **plus** a slow REST
/// poll so sync still works if the listener is denied / offline.
class ServiceAnnotationRepository {
  ServiceAnnotationRepository(this._dio, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final Dio _dio;
  final FirebaseFirestore _firestore;

  /// Safety net when Firestore snapshots are unavailable (rules, network).
  static const pollInterval = Duration(seconds: 12);

  // --- Local file cache ----------------------------------------------------

  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'annotations'));
    if (!await dir.exists()) await dir.create(recursive: true);
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
      if (await file.exists()) return await file.readAsBytes();
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
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // --- Firebase + REST -----------------------------------------------------

  DocumentReference<Map<String, dynamic>> _annotationDoc(
    String serviceId,
    String songId,
  ) => _firestore
      .collection('services')
      .doc(serviceId)
      .collection('annotations')
      .doc(songId);

  String _annotationUri(String serviceId, String songId) =>
      '/api/annotation/services/$serviceId/songs/$songId/annotation';

  static DateTime? _parseUpdatedAt(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  static int? _parseRevision(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse('$value');
  }

  Future<RemoteAnnotation?> _fromFirestoreDoc(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    required String serviceId,
    required String songId,
  }) async {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;

    final updatedAt = _parseUpdatedAt(data['updatedAt']);
    if (updatedAt == null) return null;

    final updatedById = data['updatedById'] as String?;
    final revision = _parseRevision(data['revision']);

    final inline = data['canvasDataBase64'] as String?;
    if (inline != null && inline.trim().isNotEmpty) {
      try {
        final bytes = Uint8List.fromList(base64Decode(inline));
        await saveAnnotation(
          serviceId: serviceId,
          songId: songId,
          bytes: bytes,
        );
        return RemoteAnnotation(
          bytes: bytes,
          updatedAt: updatedAt,
          updatedById: updatedById,
          revision: revision,
        );
      } catch (e) {
        debugPrint('Annotation inline base64 decode failed: $e');
      }
    }

    // Metadata-only ping: bytes live on the API / Postgres.
    return _fetchViaRest(
      serviceId: serviceId,
      songId: songId,
      preferUpdatedAt: updatedAt,
      preferUpdatedById: updatedById,
      preferRevision: revision,
    );
  }

  Future<RemoteAnnotation?> _fetchViaRest({
    required String serviceId,
    required String songId,
    DateTime? preferUpdatedAt,
    String? preferUpdatedById,
    int? preferRevision,
  }) async {
    try {
      final res = await _dio.get(
        _annotationUri(serviceId, songId),
        // Bust any intermediary caches; annotations change often.
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
          extra: {'refresh': DateTime.now().millisecondsSinceEpoch},
        ),
      );
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) return null;

      final raw = res.data;
      final json = raw is Map<String, dynamic>
          ? raw
          : jsonDecode(raw as String) as Map<String, dynamic>;
      final bytes = Uint8List.fromList(
        base64Decode(json['canvasDataBase64'] as String),
      );
      final updatedAt =
          preferUpdatedAt ??
          DateTime.parse(json['updatedAt'] as String).toUtc();
      final updatedById =
          preferUpdatedById ?? json['updatedById'] as String?;
      final revision =
          preferRevision ?? _parseRevision(json['revision']);

      await saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

      return RemoteAnnotation(
        bytes: bytes,
        updatedAt: updatedAt,
        updatedById: updatedById,
        revision: revision,
      );
    } catch (e) {
      debugPrint('Annotation REST fetch failed: $e');
      return null;
    }
  }

  /// Firestore first (inline bytes, or REST when payload is API-only).
  Future<RemoteAnnotation?> fetchRemoteAnnotation({
    required String serviceId,
    required String songId,
    bool preferServer = false,
  }) async {
    try {
      final snap = await _annotationDoc(serviceId, songId).get(
        preferServer
            ? const GetOptions(source: Source.server)
            : const GetOptions(source: Source.serverAndCache),
      );
      final fromFs = await _fromFirestoreDoc(
        snap,
        serviceId: serviceId,
        songId: songId,
      );
      if (fromFs != null) return fromFs;
    } catch (e) {
      debugPrint('Annotation Firestore fetch failed: $e');
    }
    return _fetchViaRest(serviceId: serviceId, songId: songId);
  }

  /// Pushes via the Hosanna API (server writes Firestore + Postgres).
  /// Returns version markers so the caller can ignore its own echo.
  Future<({DateTime updatedAt, int revision})> pushAnnotation({
    required String serviceId,
    required String songId,
    required Uint8List bytes,
  }) async {
    await saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

    final res = await _dio.put(
      _annotationUri(serviceId, songId),
      data: {'canvasDataBase64': base64Encode(bytes)},
    );

    if (res.statusCode != 200) {
      throw HttpException('Failed to push annotation (${res.statusCode})');
    }

    final raw = res.data;
    final json = raw is Map<String, dynamic>
        ? raw
        : jsonDecode(raw as String) as Map<String, dynamic>;
    final updatedAt = DateTime.parse(json['updatedAt'] as String).toUtc();
    final revision =
        _parseRevision(json['revision']) ?? updatedAt.millisecondsSinceEpoch;
    return (updatedAt: updatedAt, revision: revision);
  }

  /// Live listener on `services/{serviceId}/annotations/{songId}` plus a
  /// slow REST poll. [onRemoteUpdate] receives a fully resolved annotation
  /// (bytes included) whenever a newer remote version is detected.
  AnnotationSyncHandle subscribeToAnnotationUpdates({
    required String serviceId,
    required String songId,
    required void Function(RemoteAnnotation remote) onRemoteUpdate,
  }) {
    var skipFirstSnapshot = true;
    var disposed = false;

    Future<void> emitFromSnap(
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) async {
      final remote = await _fromFirestoreDoc(
        snap,
        serviceId: serviceId,
        songId: songId,
      );
      if (disposed || remote == null) return;
      onRemoteUpdate(remote);
    }

    Future<void> poll() async {
      if (disposed) return;
      final remote = await _fetchViaRest(
        serviceId: serviceId,
        songId: songId,
      );
      if (disposed || remote == null) return;
      onRemoteUpdate(remote);
    }

    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    try {
      sub = _annotationDoc(serviceId, songId).snapshots().listen(
        (snap) {
          if (skipFirstSnapshot) {
            skipFirstSnapshot = false;
            return;
          }
          if (!snap.exists) return;
          // Apply the snapshot itself (no second get) so we don't race the cache.
          unawaited(emitFromSnap(snap));
        },
        onError: (Object e, StackTrace st) {
          debugPrint('Annotation Firestore listen failed: $e');
        },
      );
    } catch (e) {
      debugPrint('Annotation Firestore subscribe failed: $e');
    }

    final pollTimer = Timer.periodic(pollInterval, (_) => unawaited(poll()));

    return AnnotationSyncHandle(
      cancel: () async {
        disposed = true;
        pollTimer.cancel();
        await sub?.cancel();
      },
    );
  }

  Future<void> unsubscribe(AnnotationSyncHandle? handle) async {
    await handle?.cancel();
  }
}
