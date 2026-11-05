import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design/tokens.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/hosanna_surface.dart';
import '../../data/song_repository.dart';
import '../../domain/chordpro_content.dart';
import 'ai_import_models.dart';

class AiImportReviewPage extends ConsumerStatefulWidget {
  const AiImportReviewPage({super.key, required this.draft});

  final AiImportDraft draft;

  @override
  ConsumerState<AiImportReviewPage> createState() => _AiImportReviewPageState();
}

class _AiImportReviewPageState extends ConsumerState<AiImportReviewPage> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _key;
  late final TextEditingController _tempo;
  late final TextEditingController _time;
  late final TextEditingController _youtube;
  late final TextEditingController _ccli;
  late final TextEditingController _composer;
  late final TextEditingController _duration;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    final source = d.content;
    _title = TextEditingController(text: d.title);
    _artist = TextEditingController(text: d.artist);
    _key = TextEditingController(
      text: d.key ?? readChordProDirective(source, 'key') ?? '',
    );
    _tempo = TextEditingController(
      text: d.tempo ?? readChordProDirective(source, 'tempo') ?? '',
    );
    _time = TextEditingController(
      text: d.timeSignature ?? readChordProDirective(source, 'time') ?? '',
    );
    _youtube = TextEditingController(
      text: d.youtube ?? readChordProDirective(source, 'youtube') ?? '',
    );
    _ccli = TextEditingController(
      text: d.ccli ?? readChordProDirective(source, 'ccli') ?? '',
    );
    _composer = TextEditingController(
      text: d.composer ?? readChordProDirective(source, 'composer') ?? '',
    );
    _duration = TextEditingController(
      text: d.duration ?? readChordProDirective(source, 'duration') ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _key.dispose();
    _tempo.dispose();
    _time.dispose();
    _youtube.dispose();
    _ccli.dispose();
    _composer.dispose();
    _duration.dispose();
    super.dispose();
  }

  String _contentWithMeta() {
    final source = widget.draft.content;
    return applyChordProMetadata(
      source,
      title: _title.text,
      artist: _artist.text,
      key: _key.text,
      tempo: _tempo.text,
      timeSignature: _time.text,
      subtitle: readChordProDirective(source, 'subtitle') ??
          widget.draft.subtitle,
      composer: _composer.text,
      copyright: readChordProDirective(source, 'copyright') ??
          widget.draft.copyright,
      ccli: _ccli.text,
      duration: _duration.text,
      youtube: _youtube.text,
    );
  }

  Future<void> _approveAndSave() async {
    final l10n = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      setState(() => _error = l10n.songsTitleRequired);
      return;
    }
    if (widget.draft.content.trim().isEmpty) {
      setState(() => _error = l10n.songsAiImportFailed);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref.read(songRepositoryProvider).createSong(
            title: _title.text.trim(),
            artist: _artist.text.trim(),
            content: _contentWithMeta(),
            folderId: widget.draft.folderId,
          );
      unawaited(ref.read(syncControllerProvider.notifier).syncAll());
      if (!mounted) return;
      context.go('/songs');
      context.push('/songs/${saved.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.commonError;
      });
    }
  }

  void _editFull() {
    context.push(
      '/songs/new',
      extra: {
        'title': _title.text.trim(),
        'artist': _artist.text.trim(),
        'content': _contentWithMeta(),
        'folderId': widget.draft.folderId,
      },
    );
  }

  Future<void> _openYoutube() async {
    final raw = _youtube.text.trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thumb = widget.draft.thumbnailBytes;
    final dupes = widget.draft.possibleDuplicates;
    final diags = widget.draft.diagnostics
        .where((d) => d.severity == 'error' || d.severity == 'warning')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.songsAiResultTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (thumb != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(HosannaRadii.md),
              child: SizedBox(
                height: 280,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(thumb, fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircleAvatar(
                          backgroundColor: HosannaColors.success,
                          radius: 16,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: HosannaSpacing.md),
          HosannaSurface(
            elevated: false,
            selected: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                const SizedBox(width: HosannaSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.songsAiCreatedBanner,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.draft.confidence != null) ...[
            const SizedBox(height: 10),
            HosannaSurface(
              elevated: false,
              child: Row(
                children: [
                  Icon(
                    widget.draft.isLowConfidence
                        ? Icons.warning_amber_rounded
                        : Icons.verified_outlined,
                    color: widget.draft.isLowConfidence
                        ? scheme.error
                        : scheme.primary,
                  ),
                  const SizedBox(width: HosannaSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.draft.isLowConfidence
                          ? l10n.songsAiLowConfidence
                          : l10n.songsAiConfidence(
                              ((widget.draft.confidence ?? 0) * 100)
                                  .round()
                                  .toString(),
                            ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (dupes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.songsAiPossibleDuplicates,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...dupes.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HosannaSurface(
                  elevated: false,
                  onTap: () {
                    context.go('/songs');
                    context.push('/songs/${d.id}');
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.library_music_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              d.artist.isEmpty ? '—' : d.artist,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.songsAiOpenExisting,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (diags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.songsAiLintIssues,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...diags.take(8).map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${d.severity}${d.line != null ? ' L${d.line}' : ''}: ${d.message}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: d.severity == 'error'
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          if (widget.draft.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...widget.draft.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  w,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.songsFieldTitle),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          TextField(
            controller: _artist,
            decoration: InputDecoration(labelText: l10n.songsFieldArtist),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _key,
                  decoration: InputDecoration(labelText: l10n.songsFieldKey),
                ),
              ),
              const SizedBox(width: HosannaSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _tempo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.songsFieldTempo),
                ),
              ),
            ],
          ),
          const SizedBox(height: HosannaSpacing.sm),
          TextField(
            controller: _time,
            decoration: InputDecoration(labelText: l10n.songsFieldTime),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          TextField(
            controller: _composer,
            decoration: InputDecoration(labelText: l10n.songsAiFieldComposer),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          TextField(
            controller: _ccli,
            decoration: InputDecoration(labelText: l10n.songsAiFieldCcli),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          TextField(
            controller: _duration,
            decoration: InputDecoration(labelText: l10n.songsAiFieldDuration),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _youtube,
            builder: (context, value, _) {
              final hasUrl = value.text.trim().isNotEmpty;
              return TextField(
                controller: _youtube,
                decoration: InputDecoration(
                  labelText: l10n.songsAiFieldYoutube,
                  suffixIcon: IconButton(
                    tooltip: l10n.songsAiOpenYoutube,
                    onPressed: hasUrl ? _openYoutube : null,
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: HosannaSpacing.lg),
          Text(
            l10n.songsAiSuccessBody,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: HosannaSpacing.sm),
          HosannaSurface(
            elevated: false,
            padding: const EdgeInsets.all(HosannaSpacing.md),
            child: SelectableText(
              widget.draft.content.trim().isEmpty
                  ? '—'
                  : widget.draft.content,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _editFull,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.songsAiEditContent),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _approveAndSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(l10n.songsAiSave),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed:
                _saving ? null : () => context.go('/songs/import/ai'),
            child: Text(l10n.songsAiDiscardDraft),
          ),
        ],
      ),
    );
  }
}
