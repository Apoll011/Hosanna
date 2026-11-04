import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/hosanna_api.dart';
import '../domain/service_note.dart';

/// REST client for `/api/services/:id/notes` (not part of RxDB replication).
class ServiceNotesRepository {
  ServiceNotesRepository(this._api);

  final HosannaApi _api;

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
      final list = await _api.serviceNotes.listServiceNotes(
        id: serviceId,
        elementId: elementId,
        scope: serviceScope ? 'service' : (elementId != null ? null : 'all'),
      );
      return list.map(_fromApi).toList();
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
      final note = await _api.serviceNotes.createServiceNote(
        id: serviceId,
        body: body,
        elementId: elementId,
        private: isPrivate,
      );
      return _fromApi(note);
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
      final note = await _api.serviceNotes.updateServiceNote(
        id: serviceId,
        noteId: noteId,
        body: body,
        private: isPrivate,
      );
      return _fromApi(note);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteNote({
    required String serviceId,
    required String noteId,
  }) async {
    try {
      await _api.serviceNotes.deleteServiceNote(
        id: serviceId,
        noteId: noteId,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  static ServiceNote _fromApi(ServiceNoteDto note) {
    final author = note.author;
    return ServiceNote(
      id: note.id ?? '',
      serviceId: note.serviceId ?? '',
      elementId: note.elementId,
      body: note.body ?? '',
      isPrivate: note.private == true,
      author: author == null
          ? null
          : ServiceNoteAuthor(
              id: author.id ?? '',
              name: author.name ?? '',
              image: author.image,
            ),
      createdAt: note.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: note.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

final serviceNotesRepositoryProvider = Provider<ServiceNotesRepository>((ref) {
  return ServiceNotesRepository(ref.watch(hosannaApiProvider));
});
