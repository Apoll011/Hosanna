import 'dart:typed_data';

enum AiImportSourceType { photo, gallery, pdf }

/// Payload handed from the source page to the progress page.
class AiImportJobRequest {
  const AiImportJobRequest({
    required this.sourceType,
    required this.imageBytes,
    required this.mimeType,
    this.extraImageBytes = const [],
    this.extraMimeTypes = const [],
    this.pdfBytes,
    this.fileName,
    this.folderId,
  });

  final AiImportSourceType sourceType;

  /// Photo/gallery image, or PDF first-page screenshot.
  final Uint8List imageBytes;
  final String mimeType;

  /// Extra PDF page screenshots (pages 2+).
  final List<Uint8List> extraImageBytes;
  final List<String> extraMimeTypes;

  /// Original PDF bytes when [sourceType] is pdf.
  final Uint8List? pdfBytes;
  final String? fileName;

  /// Optional folder to save into after approval.
  final String? folderId;
}

class AiImportDiagnostic {
  const AiImportDiagnostic({
    required this.severity,
    required this.message,
    this.line,
  });

  final String severity;
  final String message;
  final int? line;

  factory AiImportDiagnostic.fromJson(Map<String, dynamic> json) {
    return AiImportDiagnostic(
      severity: (json['severity'] as String?) ?? 'info',
      message: (json['message'] as String?) ?? '',
      line: (json['line'] as num?)?.toInt(),
    );
  }
}

class AiImportDuplicate {
  const AiImportDuplicate({
    required this.id,
    required this.title,
    required this.artist,
    required this.score,
  });

  final String id;
  final String title;
  final String artist;
  final double score;

  factory AiImportDuplicate.fromJson(Map<String, dynamic> json) {
    return AiImportDuplicate(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      artist: (json['artist'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Draft returned by Logos import (not yet persisted).
class AiImportDraft {
  const AiImportDraft({
    required this.title,
    required this.artist,
    required this.content,
    this.key,
    this.tempo,
    this.timeSignature,
    this.confidence,
    this.warnings = const [],
    this.diagnostics = const [],
    this.possibleDuplicates = const [],
    this.youtube,
    this.ccli,
    this.composer,
    this.copyright,
    this.subtitle,
    this.duration,
    this.thumbnailBytes,
    this.folderId,
  });

  final String title;
  final String artist;
  final String content;
  final String? key;
  final String? tempo;
  final String? timeSignature;
  final double? confidence;
  final List<String> warnings;
  final List<AiImportDiagnostic> diagnostics;
  final List<AiImportDuplicate> possibleDuplicates;
  final String? youtube;
  final String? ccli;
  final String? composer;
  final String? copyright;
  final String? subtitle;
  final String? duration;
  final Uint8List? thumbnailBytes;
  final String? folderId;

  bool get isLowConfidence => confidence != null && confidence! < 0.45;

  factory AiImportDraft.fromJson(
    Map<String, dynamic> json, {
    Uint8List? thumbnailBytes,
    String? folderId,
  }) {
    final diags = <AiImportDiagnostic>[];
    final rawDiags = json['diagnostics'];
    if (rawDiags is List) {
      for (final d in rawDiags) {
        if (d is Map) {
          diags.add(
            AiImportDiagnostic.fromJson(Map<String, dynamic>.from(d)),
          );
        }
      }
    }
    final dupes = <AiImportDuplicate>[];
    final rawDupes = json['possibleDuplicates'];
    if (rawDupes is List) {
      for (final d in rawDupes) {
        if (d is Map) {
          dupes.add(
            AiImportDuplicate.fromJson(Map<String, dynamic>.from(d)),
          );
        }
      }
    }
    return AiImportDraft(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Untitled',
      artist: (json['artist'] as String?)?.trim() ?? '',
      content: (json['content'] as String?) ?? '',
      key: json['key'] as String?,
      tempo: json['tempo']?.toString(),
      timeSignature: json['timeSignature'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      warnings: (json['warnings'] as List?)?.whereType<String>().toList() ??
          const [],
      diagnostics: diags,
      possibleDuplicates: dupes,
      youtube: json['youtube'] as String?,
      ccli: json['ccli'] as String?,
      composer: json['composer'] as String?,
      copyright: json['copyright'] as String?,
      subtitle: json['subtitle'] as String?,
      duration: json['duration'] as String?,
      thumbnailBytes: thumbnailBytes,
      folderId: folderId,
    );
  }
}

enum AiImportJobStatus { queued, running, completed, failed, cancelled }

enum AiImportCancelCode {
  notASong,
  unreadable,
  blank,
  wrongContent,
  multipleUnclear,
  unknown,
}

AiImportCancelCode parseAiImportCancelCode(String? raw) {
  return switch (raw) {
    'not_a_song' => AiImportCancelCode.notASong,
    'unreadable' => AiImportCancelCode.unreadable,
    'blank' => AiImportCancelCode.blank,
    'wrong_content' => AiImportCancelCode.wrongContent,
    'multiple_unclear' => AiImportCancelCode.multipleUnclear,
    _ => AiImportCancelCode.unknown,
  };
}

class AiImportJobStep {
  const AiImportJobStep({
    required this.id,
    required this.label,
    required this.done,
    this.active = false,
  });

  final String id;
  final String label;
  final bool done;
  final bool active;
}

class AiImportJobSnapshot {
  const AiImportJobSnapshot({
    required this.id,
    required this.status,
    required this.steps,
    this.draft,
    this.errorMessage,
    this.cancelCode,
    this.cancelReason,
    this.cancelledBy,
  });

  final String id;
  final AiImportJobStatus status;
  final List<AiImportJobStep> steps;
  final AiImportDraft? draft;
  final String? errorMessage;
  final AiImportCancelCode? cancelCode;
  final String? cancelReason;
  final String? cancelledBy;

  factory AiImportJobSnapshot.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String?) ?? 'queued';
    final status = switch (statusRaw) {
      'running' => AiImportJobStatus.running,
      'completed' => AiImportJobStatus.completed,
      'failed' => AiImportJobStatus.failed,
      'cancelled' => AiImportJobStatus.cancelled,
      _ => AiImportJobStatus.queued,
    };
    final stepsRaw = json['steps'];
    final steps = <AiImportJobStep>[];
    if (stepsRaw is List) {
      for (final s in stepsRaw) {
        if (s is! Map) continue;
        final m = Map<String, dynamic>.from(s);
        steps.add(
          AiImportJobStep(
            id: (m['id'] as String?) ?? '',
            label: (m['label'] as String?) ?? '',
            done: m['done'] == true,
            active: m['active'] == true,
          ),
        );
      }
    }
    final result = json['result'];
    final cancelCodeRaw = json['cancelCode'] as String?;
    return AiImportJobSnapshot(
      id: (json['id'] as String?) ?? '',
      status: status,
      steps: steps,
      draft: result is Map
          ? AiImportDraft.fromJson(Map<String, dynamic>.from(result))
          : null,
      errorMessage: json['errorMessage'] as String?,
      cancelCode: status == AiImportJobStatus.cancelled
          ? parseAiImportCancelCode(cancelCodeRaw)
          : null,
      cancelReason: json['cancelReason'] as String? ??
          (status == AiImportJobStatus.cancelled
              ? json['errorMessage'] as String?
              : null),
      cancelledBy: json['cancelledBy'] as String?,
    );
  }
}
