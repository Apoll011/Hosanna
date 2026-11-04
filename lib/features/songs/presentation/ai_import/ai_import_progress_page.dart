import 'dart:async';
import 'dart:convert';

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
  bool _started = false;

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
      // Show optimistic step motion while the (long) create call runs.
      _poll = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (!mounted || _snapshot?.status == AiImportJobStatus.completed) {
          return;
        }
        setState(() {
          _snapshot = _advanceLocalSteps(_snapshot, l10n);
        });
      });

      final created = await api.createJob(
        sourceType: sourceType,
        imageBase64: base64Encode(widget.request.imageBytes),
        imageMimeType: widget.request.mimeType,
        pdfBase64: widget.request.pdfBytes == null
            ? null
            : base64Encode(widget.request.pdfBytes!),
        fileName: widget.request.fileName,
      );
      _poll?.cancel();
      final id = created['id'] as String?;
      if (id == null || id.isEmpty) {
        throw StateError('Missing job id');
      }
      final snap = AiImportJobSnapshot.fromJson(created);
      setState(() {
        _jobId = id;
        _snapshot = snap;
      });
      if (snap.status == AiImportJobStatus.completed && snap.draft != null) {
        _goReview(snap.draft!);
        return;
      }
      if (snap.status == AiImportJobStatus.failed) {
        setState(() => _error = snap.errorMessage ?? l10n.songsAiImportFailed);
        return;
      }
      // Rare: job still running (e.g. older server) — poll.
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.songsAiImportFailed);
    }
  }

  Future<void> _tick() async {
    final id = _jobId;
    if (id == null) return;
    try {
      final raw = await ref.read(hosannaApiProvider).songImport.getJob(id);
      final snap = AiImportJobSnapshot.fromJson(raw);
      if (!mounted) return;
      setState(() => _snapshot = snap);
      if (snap.status == AiImportJobStatus.completed && snap.draft != null) {
        _poll?.cancel();
        _goReview(snap.draft!);
      } else if (snap.status == AiImportJobStatus.failed) {
        _poll?.cancel();
        setState(() {
          _error = snap.errorMessage ??
              AppLocalizations.of(context).songsAiImportFailed;
        });
      }
    } catch (_) {
      // Keep polling; transient network blips are OK.
    }
  }

  void _goReview(AiImportDraft draft) {
    final withThumb = AiImportDraft(
      title: draft.title,
      artist: draft.artist,
      content: draft.content,
      key: draft.key,
      tempo: draft.tempo,
      timeSignature: draft.timeSignature,
      confidence: draft.confidence,
      warnings: draft.warnings,
      thumbnailBytes: widget.request.imageBytes,
    );
    context.pushReplacement('/songs/import/ai/review', extra: withThumb);
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

  AiImportJobSnapshot _advanceLocalSteps(
    AiImportJobSnapshot? current,
    AppLocalizations l10n,
  ) {
    final steps = List<AiImportJobStep>.from(
      current?.steps.isNotEmpty == true ? current!.steps : _fallbackSteps(l10n),
    );
    final activeIdx = steps.indexWhere((s) => s.active);
    final idx = activeIdx < 0 ? 0 : activeIdx;
    if (idx >= steps.length - 1) {
      return AiImportJobSnapshot(
        id: current?.id ?? '',
        status: AiImportJobStatus.running,
        steps: steps,
      );
    }
    steps[idx] = AiImportJobStep(
      id: steps[idx].id,
      label: steps[idx].label,
      done: true,
    );
    steps[idx + 1] = AiImportJobStep(
      id: steps[idx + 1].id,
      label: steps[idx + 1].label,
      done: false,
      active: true,
    );
    return AiImportJobSnapshot(
      id: current?.id ?? '',
      status: AiImportJobStatus.running,
      steps: steps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = _snapshot?.steps.isNotEmpty == true
        ? _snapshot!.steps
        : _fallbackSteps(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songsImportWithAi),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            Image.asset(
              _error == null
                  ? HosannaIllustrations.aiProcessing
                  : HosannaIllustrations.stateError,
              height: 120,
              fit: BoxFit.contain,
            ),
            if (_error == null) ...[
              const SizedBox(height: HosannaSpacing.sm),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
            const SizedBox(height: HosannaSpacing.lg),
            Text(
              _error == null ? l10n.songsAiAnalyzing : l10n.songsAiImportFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: HosannaSpacing.xs),
            Text(
              _error ?? l10n.songsAiAnalyzingBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
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
            if (_error == null)
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
              )
            else ...[
              Text(
                l10n.songsAiImportFailedBody,
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
                  child: Text(l10n.commonRetry),
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
