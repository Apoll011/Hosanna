import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/design/illustrations.dart';
import '../../../../app/design/tokens.dart';
import '../../../../app/providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/hosanna_surface.dart';
import 'ai_import_models.dart';

class AiImportProgressPage extends ConsumerStatefulWidget {
  const AiImportProgressPage({super.key, required this.request});

  final AiImportJobRequest request;

  @override
  ConsumerState<AiImportProgressPage> createState() =>
      _AiImportProgressPageState();
}

class _AiImportProgressPageState extends ConsumerState<AiImportProgressPage> {
  Timer? _poll;
  String? _jobId;
  AiImportJobSnapshot? _snapshot;
  String? _error;
  bool _cancelledByAi = false;
  bool _cancelledByUser = false;
  AiImportCancelCode? _cancelCode;
  bool _started = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _handleSnapshot(AiImportJobSnapshot snap, AppLocalizations l10n) {
    if (_leaving || !mounted) return;
    setState(() => _snapshot = snap);
    if (snap.status == AiImportJobStatus.completed) {
      _poll?.cancel();
      _goReview(
        snap.draft ??
            const AiImportDraft(
              title: 'Untitled',
              artist: '',
              content: '',
              warnings: ['Import finished without a draft payload.'],
            ),
      );
      return;
    }
    if (snap.status == AiImportJobStatus.cancelled) {
      _poll?.cancel();
      final byUser = snap.cancelledBy == 'user';
      setState(() {
        _cancelledByUser = byUser;
        _cancelledByAi = !byUser;
        _cancelCode = snap.cancelCode ?? AiImportCancelCode.unknown;
        _error = snap.cancelReason?.trim().isNotEmpty == true
            ? snap.cancelReason
            : byUser
                ? l10n.songsAiCancelImport
                : _cancelCodeMessage(l10n, _cancelCode!);
      });
      return;
    }
    if (snap.status == AiImportJobStatus.failed) {
      _poll?.cancel();
      setState(() {
        _cancelledByAi = false;
        _cancelledByUser = false;
        _cancelCode = null;
        _error = snap.errorMessage ?? l10n.songsAiImportFailed;
      });
    }
  }

  String _cancelCodeMessage(AppLocalizations l10n, AiImportCancelCode code) {
    return switch (code) {
      AiImportCancelCode.notASong => l10n.songsAiCancelledNotASong,
      AiImportCancelCode.unreadable => l10n.songsAiCancelledUnreadable,
      AiImportCancelCode.blank => l10n.songsAiCancelledBlank,
      AiImportCancelCode.wrongContent => l10n.songsAiCancelledWrongContent,
      AiImportCancelCode.multipleUnclear => l10n.songsAiCancelledMultiple,
      AiImportCancelCode.unknown => l10n.songsAiCancelledGeneric,
    };
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    final l10n = AppLocalizations.of(context);
    try {
      final api = ref.read(hosannaApiProvider).songImport;
      final sourceType = switch (widget.request.sourceType) {
        AiImportSourceType.photo => 'photo',
        AiImportSourceType.gallery => 'gallery',
        AiImportSourceType.pdf => 'pdf',
      };

      final created = await api.createJob(
        sourceType: sourceType,
        imageBase64: base64Encode(widget.request.imageBytes),
        imageMimeType: widget.request.mimeType,
        imagesBase64: widget.request.extraImageBytes.isEmpty
            ? null
            : widget.request.extraImageBytes
                .map(base64Encode)
                .toList(growable: false),
        imageMimeTypes: widget.request.extraMimeTypes.isEmpty
            ? null
            : widget.request.extraMimeTypes,
        pdfBase64: widget.request.pdfBytes == null
            ? null
            : base64Encode(widget.request.pdfBytes!),
        fileName: widget.request.fileName,
      );
      if (!mounted || _leaving) return;
      final id = created['id'] as String?;
      if (id == null || id.isEmpty) {
        throw StateError('Missing job id');
      }
      final snap = AiImportJobSnapshot.fromJson(created);
      setState(() {
        _jobId = id;
        _snapshot = snap;
      });
      if (snap.status == AiImportJobStatus.completed ||
          snap.status == AiImportJobStatus.cancelled ||
          snap.status == AiImportJobStatus.failed) {
        _handleSnapshot(snap, l10n);
        return;
      }
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      // Immediate first poll in case create raced past queued.
      unawaited(_tick());
    } catch (e) {
      _poll?.cancel();
      if (!mounted || _leaving) return;
      setState(() {
        _cancelledByAi = false;
        _error = _errorMessageFrom(e, l10n);
      });
    }
  }

  String _errorMessageFrom(Object e, AppLocalizations l10n) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['errorMessage'] ??
            data['cancelReason'] ??
            data['message'] ??
            data['error'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      if (e.message != null && e.message!.trim().isNotEmpty) {
        return e.message!.trim();
      }
    }
    if (e is StateError && e.message.isNotEmpty) return e.message;
    return l10n.songsAiImportFailed;
  }

  Future<void> _tick() async {
    final id = _jobId;
    if (id == null || _leaving) return;
    try {
      final raw = await ref.read(hosannaApiProvider).songImport.getJob(id);
      final snap = AiImportJobSnapshot.fromJson(raw);
      if (!mounted || _leaving) return;
      _handleSnapshot(snap, AppLocalizations.of(context));
    } catch (_) {
      // Keep polling; transient network blips are OK.
    }
  }

  void _goReview(AiImportDraft draft) {
    if (!mounted || _leaving) return;
    final withThumb = AiImportDraft(
      title: draft.title,
      artist: draft.artist,
      content: draft.content,
      key: draft.key,
      tempo: draft.tempo,
      timeSignature: draft.timeSignature,
      confidence: draft.confidence,
      warnings: draft.warnings,
      diagnostics: draft.diagnostics,
      possibleDuplicates: draft.possibleDuplicates,
      youtube: draft.youtube,
      ccli: draft.ccli,
      composer: draft.composer,
      copyright: draft.copyright,
      subtitle: draft.subtitle,
      duration: draft.duration,
      thumbnailBytes: widget.request.imageBytes,
      folderId: widget.request.folderId,
    );
    context.pushReplacement('/songs/import/ai/review', extra: withThumb);
  }

  Future<void> _abortByUser() async {
    if (_leaving) return;
    _leaving = true;
    _poll?.cancel();
    final id = _jobId;
    if (id != null) {
      try {
        await ref.read(hosannaApiProvider).songImport.cancelJob(id);
      } catch (_) {
        /* best-effort */
      }
    }
    if (!mounted) return;
    context.go('/songs/import/ai');
  }

  List<AiImportJobStep> _fallbackSteps(AppLocalizations l10n) {
    return [
      AiImportJobStep(
        id: 'process',
        label: l10n.songsAiStepProcess,
        done: false,
        active: true,
      ),
      AiImportJobStep(
        id: 'extract',
        label: l10n.songsAiStepExtract,
        done: false,
      ),
      AiImportJobStep(
        id: 'metadata',
        label: l10n.songsAiStepMetadata,
        done: false,
      ),
      AiImportJobStep(id: 'verify', label: l10n.songsAiStepVerify, done: false),
      AiImportJobStep(id: 'draft', label: l10n.songsAiStepDraft, done: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = _snapshot?.steps.isNotEmpty == true
        ? _snapshot!.steps
        : _fallbackSteps(l10n);
    final hasError = _error != null;
    final title = !hasError
        ? l10n.songsAiAnalyzing
        : (_cancelledByAi || _cancelledByUser)
            ? l10n.songsAiCancelledTitle
            : l10n.songsAiImportFailed;
    final body = !hasError ? l10n.songsAiAnalyzingBody : _error!;
    final footerHint = !hasError
        ? null
        : _cancelledByAi
            ? l10n.songsAiCancelledBody
            : _cancelledByUser
                ? null
                : l10n.songsAiImportFailedBody;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songsImportWithAi),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            Image.asset(
              hasError
                  ? HosannaIllustrations.stateError
                  : HosannaIllustrations.aiProcessing,
              height: 240,
              fit: BoxFit.contain,
            ),
            if (!hasError) ...[
              const SizedBox(height: HosannaSpacing.sm),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
            const SizedBox(height: HosannaSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: HosannaSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_cancelledByAi && _cancelCode != null) ...[
              const SizedBox(height: HosannaSpacing.sm),
              Chip(
                avatar: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                label: Text(_cancelCodeMessage(l10n, _cancelCode!)),
              ),
            ],
            const SizedBox(height: HosannaSpacing.xl),
            HosannaSurface(
              elevated: false,
              padding: const EdgeInsets.symmetric(
                horizontal: HosannaSpacing.md,
                vertical: HosannaSpacing.sm,
              ),
              child: Column(
                children: [for (final s in steps) _StepRow(step: s)],
              ),
            ),
            const Spacer(),
            if (!hasError) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    disabledBackgroundColor: scheme.surfaceContainerHighest,
                    disabledForegroundColor: scheme.onSurfaceVariant,
                  ),
                  child: Text(l10n.songsAiPleaseWait),
                ),
              ),
              TextButton(
                onPressed: _abortByUser,
                child: Text(l10n.songsAiCancelImport),
              ),
            ] else ...[
              if (footerHint != null)
                Text(
                  footerHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: HosannaSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/songs/import/ai'),
                  child: Text(
                    (_cancelledByAi || _cancelledByUser)
                        ? l10n.songsAiImportAnother
                        : l10n.commonRetry,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/songs/new'),
                child: Text(l10n.songsCreateManually),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final AiImportJobStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = step.done
        ? Icon(Icons.check_circle_rounded, color: scheme.primary)
        : step.active
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: scheme.primary,
                ),
              )
            : Icon(Icons.circle_outlined, color: scheme.outline);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        step.active || step.done ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
