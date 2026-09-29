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
typedef AnnotationSubscription =
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>;

/// Local `.fcv` cache + Firestore-backed live sync for service song annotations.
///
/// Writes go through the Hosanna API (Admin SDK → Firestore metadata / inline
/// bytes; large canvases stay in Postgres). Reads/listeners use Firestore
/// first, with a REST fallback when the payload is API-only.
class ServiceAnnotationRepository {
  ServiceAnnotationRepository(this._dio, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final Dio _dio;
  final FirebaseFirestore _firestore;

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
    final revisionRaw = data['revision'];
    final revision = revisionRaw is int
        ? revisionRaw
        : revisionRaw is num
        ? revisionRaw.toInt()
        : int.tryParse('$revisionRaw');

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

    // Oversize / metadata-only ping: bytes live on the API / Postgres.
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
      final res = await _dio.get(_annotationUri(serviceId, songId));
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

      await saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

      return RemoteAnnotation(
        bytes: bytes,
        updatedAt: updatedAt,
        updatedById: updatedById,
        revision: preferRevision,
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
  }) async {
    try {
      final snap = await _annotationDoc(serviceId, songId).get();
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

  /// Pushes via the Hosanna API (server writes Firestore + Storage).
  Future<DateTime> pushAnnotation({
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
    return DateTime.parse(json['updatedAt'] as String).toUtc();
  }

  /// Live listener on `services/{serviceId}/annotations/{songId}`.
  ///
  /// The first snapshot is ignored (seed). Later changes invoke
  /// [onRemoteChange] so the caller can re-fetch / apply conflict UX.
  AnnotationSubscription subscribeToAnnotationUpdates({
    required String serviceId,
    required String songId,
    required VoidCallback onRemoteChange,
  }) {
    var skipFirst = true;
    return _annotationDoc(serviceId, songId).snapshots().listen(
      (snap) {
        if (skipFirst) {
          skipFirst = false;
          return;
        }
        if (!snap.exists) return;
        onRemoteChange();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('Annotation Firestore listen failed: $e');
      },
    );
  }

  Future<void> unsubscribe(AnnotationSubscription? subscription) async {
    await subscription?.cancel();
  }
}
