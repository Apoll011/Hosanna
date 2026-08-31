import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteAnnotation {
  const RemoteAnnotation({required this.bytes, required this.updatedAt});
  final Uint8List bytes;
  final DateTime updatedAt;
}

class ServiceAnnotationRepository {
  ServiceAnnotationRepository(this._supabase, this._dio);

  final SupabaseClient _supabase;
  final Dio _dio;

  // --- Local file cache (unchanged from before) ---------------------------

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

  // --- Backend API (source of truth) ---------------------------------------

  String _annotationUri(String serviceId, String songId) =>
      '/api/annotation/services/$serviceId/songs/$songId/annotation';

  Future<RemoteAnnotation?> fetchRemoteAnnotation({
    required String serviceId,
    required String songId,
  }) async {
    try {
      final res = await _dio.get(_annotationUri(serviceId, songId));
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.data) as Map<String, dynamic>;
      final bytes = base64Decode(json['canvasDataBase64'] as String);
      final updatedAt = DateTime.parse(json['updatedAt'] as String);

      await saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

      return RemoteAnnotation(bytes: bytes, updatedAt: updatedAt);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime> pushAnnotation({
    required String serviceId,
    required String songId,
    required Uint8List bytes,
  }) async {
    final res = await _dio.put(
      _annotationUri(serviceId, songId),
      data: jsonEncode({'canvasDataBase64': base64Encode(bytes)}),
    );

    if (res.statusCode != 200) {
      throw HttpException('Failed to push annotation (${res.statusCode})');
    }

    final json = jsonDecode(res.data) as Map<String, dynamic>;
    return DateTime.parse(json['updatedAt'] as String);
  }

  RealtimeChannel subscribeToAnnotationUpdates({
    required String serviceId,
    required String songId,
    required VoidCallback onRemoteChange,
  }) {
    final channel = _supabase.channel('annotation:$serviceId:$songId');
    channel
        .onBroadcast(event: 'updated', callback: (_) => onRemoteChange())
        .subscribe();
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) {
    return _supabase.removeChannel(channel);
  }
}
