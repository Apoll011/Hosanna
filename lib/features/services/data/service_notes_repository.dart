import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/service_note.dart';

/// REST client for `/api/services/:id/notes` (not part of RxDB replication).
class ServiceNotesRepository {
  ServiceNotesRepository(this._dio);

  final Dio _dio;

  String _base(String serviceId) => '/api/services/$serviceId/notes';

  /// Lists notes the caller may see. Oldest first.
  ///
  /// Pass [elementId] to filter by element, or [serviceScope] to get only
  /// service-level notes (`elementId == null`). Do not combine both.
  Future<List<ServiceNote>> listNotes({
    required String serviceId,
    String? elementId,
    bool serviceScope = false,
  }) async {
    assert(
      !(serviceScope && elementId != null),
      'Do not send elementId together with scope=service',
    );
    try {
      final query = <String, dynamic>{};
      if (serviceScope) {
        query['scope'] = 'service';
      } else if (elementId != null) {
        query['elementId'] = elementId;
      }
      final res = await _dio.get<dynamic>(
        _base(serviceId),
        queryParameters: query.isEmpty ? null : query,
      );
      final data = res.data;
      final list = data is List ? data : const <dynamic>[];
      return list
          .whereType<Map>()
          .map((e) => ServiceNote.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ServiceNote> createNote({
    required String serviceId,
    required String body,
    String? elementId,
    bool isPrivate = false,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        _base(serviceId),
        data: {
          'body': body,
          'elementId': elementId,
          'private': isPrivate,
        },
      );
      return ServiceNote.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ServiceNote> updateNote({
    required String serviceId,
    required String noteId,
    String? body,
    bool? isPrivate,
  }) async {
    assert(body != null || isPrivate != null, 'Send body, private, or both');
    try {
      final payload = <String, dynamic>{};
      if (body != null) payload['body'] = body;
      if (isPrivate != null) payload['private'] = isPrivate;
      final res = await _dio.put<dynamic>(
        '${_base(serviceId)}/$noteId',
        data: payload,
      );
      return ServiceNote.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteNote({
    required String serviceId,
    required String noteId,
  }) async {
    try {
      await _dio.delete<dynamic>('${_base(serviceId)}/$noteId');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final serviceNotesRepositoryProvider = Provider<ServiceNotesRepository>((ref) {
  return ServiceNotesRepository(ref.watch(dioProvider));
});
