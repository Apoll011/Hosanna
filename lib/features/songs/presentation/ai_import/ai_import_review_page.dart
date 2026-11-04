import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/sync_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
      context.go('/songs/${saved.id}');
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
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(thumb, fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircleAvatar(
                          backgroundColor: Colors.green.shade600,
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                const SizedBox(width: 10),
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
            decoration: InputDecoration(
              labelText: l10n.songsFieldTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _key,
                  decoration: InputDecoration(
                    labelText: l10n.songsFieldKey,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _tempo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.songsFieldTempo,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _time,
            decoration: InputDecoration(
              labelText: l10n.songsFieldTime,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _editFull,
                  child: Text(l10n.songsAiEditContent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.songsAiSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
