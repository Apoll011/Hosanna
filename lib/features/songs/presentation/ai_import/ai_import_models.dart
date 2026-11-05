import 'dart:typed_data';

enum AiImportSourceType { photo, gallery, pdf }

/// Payload handed from the source page to the progress page.
class AiImportJobRequest {
  const AiImportJobRequest({
    required this.sourceType,
    required this.imageBytes,
    required this.mimeType,
    this.pdfBytes,
    this.fileName,
  });

  final AiImportSourceType sourceType;

  /// Photo/gallery image, or PDF first-page screenshot.
  final Uint8List imageBytes;
  final String mimeType;

  /// Original PDF bytes when [sourceType] is pdf.
  final Uint8List? pdfBytes;
  final String? fileName;
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
    this.thumbnailBytes,
  });

  final String title;
  final String artist;
  final String content;
  final String? key;
  final String? tempo;
  final String? timeSignature;
  final double? confidence;
  final List<String> warnings;
  final Uint8List? thumbnailBytes;

  bool get isLowConfidence =>
      confidence != null && confidence! < 0.45;

  factory AiImportDraft.fromJson(
    Map<String, dynamic> json, {
    Uint8List? thumbnailBytes,
  }) {
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
      warnings: (json['warnings'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      thumbnailBytes: thumbnailBytes,
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
  });

  final String id;
  final AiImportJobStatus status;
  final List<AiImportJobStep> steps;
  final AiImportDraft? draft;
  final String? errorMessage;
  final AiImportCancelCode? cancelCode;
  final String? cancelReason;

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
    );
  }
}
