import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  late final TextEditingController _key;
  late final TextEditingController _tempo;
  late final TextEditingController _time;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _title = TextEditingController(text: d.title);
    _key = TextEditingController(
      text: d.key ?? readChordProDirective(d.content, 'key') ?? '',
    );
    _tempo = TextEditingController(
      text: d.tempo ?? readChordProDirective(d.content, 'tempo') ?? '',
    );
    _time = TextEditingController(
      text: d.timeSignature ?? readChordProDirective(d.content, 'time') ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _key.dispose();
    _tempo.dispose();
    _time.dispose();
    super.dispose();
  }

  String _contentWithMeta() {
    return applyChordProMetadata(
      widget.draft.content,
      title: _title.text,
      artist: widget.draft.artist,
      key: _key.text,
      tempo: _tempo.text,
      timeSignature: _time.text,
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      setState(() => _error = l10n.songsTitleRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref.read(songRepositoryProvider).createSong(
            title: _title.text.trim(),
            artist: widget.draft.artist,
            content: _contentWithMeta(),
          );
      unawaited(ref.read(syncControllerProvider.notifier).syncAll());
      if (!mounted) return;
      // Keep library under detail so the AppBar back button works.
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
        'artist': widget.draft.artist,
        'content': _contentWithMeta(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thumb = widget.draft.thumbnailBytes;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.songsAiResultTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (thumb != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(HosannaRadii.md),
              child: SizedBox(
                height: 360,
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
                  onPressed: _saving ? null : _save,
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
        ],
      ),
    );
  }
}
