import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ServiceAnnotationRepository {
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
}

final serviceAnnotationRepositoryProvider =
    Provider<ServiceAnnotationRepository>((ref) {
  return ServiceAnnotationRepository();
});

final serviceAnnotationBytesProvider =
    FutureProvider.family<Uint8List?, ({String serviceId, String songId})>(
  (ref, args) async {
    final repo = ref.watch(serviceAnnotationRepositoryProvider);
    return repo.loadAnnotation(
      serviceId: args.serviceId,
      songId: args.songId,
    );
  },
);
