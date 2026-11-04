import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Typed REST facade aligned with `openapi/openapi.yaml` (operationIds).
///
/// Uses the shared [Dio] interceptors (cookies, bearer, captcha, User-Agent,
/// Origin) with [baseUrl] at [AppConfig.apiRoot]. Better Auth stays on the
/// origin-scoped shared Dio with absolute `/api/auth/...` paths.
///
/// Full `dart-dio` codegen lives under `tool/generate_openapi_client.sh` for
/// experimentation; the app compiles against this hand-maintained facade so
/// we are not blocked on generator/json_serializable quirks.
class HosannaApi {
  HosannaApi._({
    required this.replication,
    required this.annotations,
    required this.serviceNotes,
    required this.songImport,
  });

  final ReplicationApi replication;
  final AnnotationsApi annotations;
  final ServiceNotesApi serviceNotes;
  final SongImportApi songImport;

  factory HosannaApi.fromSharedDio(
    Dio shared, {
    required AppConfig config,
  }) {
    final apiRoot = config.apiRoot.replaceFirst(RegExp(r'/$'), '');
    final dio = Dio(shared.options.copyWith(baseUrl: apiRoot));
    dio.interceptors.addAll(shared.interceptors);
    return HosannaApi._(
      replication: ReplicationApi(dio),
      annotations: AnnotationsApi(dio),
      serviceNotes: ServiceNotesApi(dio),
      songImport: SongImportApi(dio),
    );
  }
}

const _kReplicationCollections = {
  'songs',
  'folders',
  'collections',
  'services',
  'agendaEvents',
};

/// Validates a replication resource name against the OpenAPI enum.
String replicationCollectionFor(String resourceName) {
  if (!_kReplicationCollections.contains(resourceName)) {
    throw ArgumentError.value(
      resourceName,
      'resourceName',
      'Unknown replication collection',
    );
  }
  return resourceName;
}

class ReplicationApi {
  ReplicationApi(this._dio);
  final Dio _dio;

  Future<PullResponse> pullCollection({
    required String collection,
    required PullRequest pullRequest,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/replication/$collection/pull',
      data: pullRequest.toJson(),
    );
    return PullResponse.fromJson(res.data ?? const {});
  }

  Future<List<Map<String, dynamic>>> pushCollection({
    required String collection,
    required List<ChangeRowBody> changeRows,
  }) async {
    final res = await _dio.post<List<dynamic>>(
      '/replication/$collection/push',
      data: {
        'changeRows': changeRows.map((c) => c.toJson()).toList(),
      },
    );
    final raw = res.data ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class AnnotationsApi {
  AnnotationsApi(this._dio);
  final Dio _dio;

  Future<Response<AnnotationPayload?>> getAnnotation({
    required String serviceId,
    required String songId,
    Map<String, dynamic>? headers,
    ValidateStatus? validateStatus,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/annotation/services/$serviceId/songs/$songId/annotation',
      options: Options(headers: headers, validateStatus: validateStatus),
    );
    final raw = res.data;
    return Response<AnnotationPayload?>(
      data: raw == null ? null : AnnotationPayload.fromJson(raw),
      headers: res.headers,
      requestOptions: res.requestOptions,
      statusCode: res.statusCode,
      statusMessage: res.statusMessage,
      isRedirect: res.isRedirect,
      redirects: res.redirects,
      extra: res.extra,
    );
  }

  Future<Response<AnnotationWriteResult>> putAnnotation({
    required String serviceId,
    required String songId,
    required String canvasDataBase64,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/annotation/services/$serviceId/songs/$songId/annotation',
      data: {'canvasDataBase64': canvasDataBase64},
    );
    return Response<AnnotationWriteResult>(
      data: AnnotationWriteResult.fromJson(res.data ?? const {}),
      headers: res.headers,
      requestOptions: res.requestOptions,
      statusCode: res.statusCode,
      statusMessage: res.statusMessage,
      isRedirect: res.isRedirect,
      redirects: res.redirects,
      extra: res.extra,
    );
  }
}

class ServiceNotesApi {
  ServiceNotesApi(this._dio);
  final Dio _dio;

  Future<List<ServiceNoteDto>> listServiceNotes({
    required String id,
    String? elementId,
    String? scope,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/services/$id/notes',
      queryParameters: {
        if (elementId != null) 'elementId': elementId,
        if (scope != null) 'scope': scope,
      },
    );
    return (res.data ?? const [])
        .whereType<Map>()
        .map((e) => ServiceNoteDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ServiceNoteDto> createServiceNote({
    required String id,
    required String body,
    String? elementId,
    bool private = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/services/$id/notes',
      data: {
        'body': body,
        if (elementId != null) 'elementId': elementId,
        'private': private,
      },
    );
    return ServiceNoteDto.fromJson(res.data ?? const {});
  }

  Future<ServiceNoteDto> updateServiceNote({
    required String id,
    required String noteId,
    String? body,
    bool? private,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/services/$id/notes/$noteId',
      data: {
        if (body != null) 'body': body,
        if (private != null) 'private': private,
      },
    );
    return ServiceNoteDto.fromJson(res.data ?? const {});
  }

  Future<void> deleteServiceNote({
    required String id,
    required String noteId,
  }) async {
    await _dio.delete<void>('/services/$id/notes/$noteId');
  }
}

/// Logos AI sheet-music → ChordPro draft jobs.
class SongImportApi {
  SongImportApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> createJob({
    required String sourceType,
    required String imageBase64,
    required String imageMimeType,
    String? pdfBase64,
    String? fileName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/songs/import/jobs',
      data: {
        'sourceType': sourceType,
        'imageBase64': imageBase64,
        'imageMimeType': imageMimeType,
        if (pdfBase64 != null) 'pdfBase64': pdfBase64,
        if (fileName != null) 'fileName': fileName,
      },
      options: Options(
        // Vision + web verify can take a while.
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> getJob(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/songs/import/jobs/$id',
    );
    return res.data ?? const {};
  }
}

// --- DTOs (OpenAPI schemas used by migrated call sites) --------------------

class PullRequest {
  const PullRequest({this.checkpoint, this.limit});
  final Map<String, dynamic>? checkpoint;
  final int? limit;

  Map<String, dynamic> toJson() => {
        if (checkpoint != null) 'checkpoint': checkpoint,
        if (limit != null) 'limit': limit,
      };
}

class PullResponse {
  const PullResponse({required this.documents, this.checkpoint});
  final List<Map<String, dynamic>> documents;
  final Map<String, dynamic>? checkpoint;

  factory PullResponse.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'];
    return PullResponse(
      documents: docs is List
          ? docs
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      checkpoint: json['checkpoint'] is Map
          ? Map<String, dynamic>.from(json['checkpoint'] as Map)
          : null,
    );
  }
}

class ChangeRowBody {
  const ChangeRowBody({
    required this.newDocumentState,
    this.assumedMasterState,
  });
  final Map<String, dynamic> newDocumentState;
  final Map<String, dynamic>? assumedMasterState;

  Map<String, dynamic> toJson() => {
        'newDocumentState': newDocumentState,
        if (assumedMasterState != null)
          'assumedMasterState': assumedMasterState,
      };
}

class AnnotationPayload {
  const AnnotationPayload({
    this.canvasDataBase64,
    this.updatedAt,
    this.updatedById,
    this.revision,
  });

  final String? canvasDataBase64;
  final DateTime? updatedAt;
  final String? updatedById;
  final int? revision;

  factory AnnotationPayload.fromJson(Map<String, dynamic> json) {
    return AnnotationPayload(
      canvasDataBase64: json['canvasDataBase64'] as String?,
      updatedAt: _parseDate(json['updatedAt']),
      updatedById: json['updatedById'] as String?,
      revision: (json['revision'] as num?)?.toInt(),
    );
  }
}

class AnnotationWriteResult {
  const AnnotationWriteResult({
    this.updatedAt,
    this.updatedById,
    this.revision,
  });

  final DateTime? updatedAt;
  final String? updatedById;
  final int? revision;

  factory AnnotationWriteResult.fromJson(Map<String, dynamic> json) {
    return AnnotationWriteResult(
      updatedAt: _parseDate(json['updatedAt']),
      updatedById: json['updatedById'] as String?,
      revision: (json['revision'] as num?)?.toInt(),
    );
  }
}

class ServiceNoteDto {
  const ServiceNoteDto({
    this.id,
    this.serviceId,
    this.elementId,
    this.body,
    this.private,
    this.author,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? serviceId;
  final String? elementId;
  final String? body;
  final bool? private;
  final ServiceNoteAuthorDto? author;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ServiceNoteDto.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return ServiceNoteDto(
      id: json['id'] as String?,
      serviceId: json['serviceId'] as String?,
      elementId: json['elementId'] as String?,
      body: json['body'] as String?,
      private: json['private'] as bool?,
      author: author is Map
          ? ServiceNoteAuthorDto.fromJson(Map<String, dynamic>.from(author))
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class ServiceNoteAuthorDto {
  const ServiceNoteAuthorDto({this.id, this.name, this.image});
  final String? id;
  final String? name;
  final String? image;

  factory ServiceNoteAuthorDto.fromJson(Map<String, dynamic> json) {
    return ServiceNoteAuthorDto(
      id: json['id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
