import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/song_repository.dart';
import '../domain/chordpro_content.dart';
import 'song_reader.dart';

/// Create or edit a song (metadata + ChordPro body).
class SongEditorPage extends ConsumerStatefulWidget {
  const SongEditorPage({
    super.key,
    this.songId,
    this.initialTitle,
    this.initialArtist,
    this.initialContent,
    this.initialFolderId,
    this.initialTags = const [],
  });

  /// Null ⇒ create mode.
  final String? songId;

  /// Prefill when arriving from AI import review.
  final String? initialTitle;
  final String? initialArtist;
  final String? initialContent;
  final String? initialFolderId;
  final List<String> initialTags;

  bool get isCreate => songId == null;

  @override
  ConsumerState<SongEditorPage> createState() => _SongEditorPageState();
}

class _SongEditorPageState extends ConsumerState<SongEditorPage> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _key = TextEditingController();
  final _tempo = TextEditingController();
  final _time = TextEditingController();
  final _content = TextEditingController();

  bool _saving = false;
  bool _hydrated = false;
  String? _folderId;
  List<String> _tags = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      _hydrateCreate();
    }
  }

  void _hydrateCreate() {
    final title = widget.initialTitle?.trim() ?? '';
    final artist = widget.initialArtist?.trim() ?? '';
    final content = widget.initialContent?.trim().isNotEmpty == true
        ? widget.initialContent!
        : defaultChordProContent(title: title.isEmpty ? 'Untitled' : title, artist: artist);
    _title.text = title;
    _artist.text = artist;
    _content.text = content;
    _key.text = readChordProDirective(content, 'key') ?? 'G';
    _tempo.text = readChordProDirective(content, 'tempo') ?? '';
    _time.text = readChordProDirective(content, 'time') ?? '4/4';
    _folderId = widget.initialFolderId;
    _tags = widget.initialTags;
    _hydrated = true;
  }

  void _hydrateFromSong(SongRow song) {
    if (_hydrated) return;
    _hydrated = true;
    _title.text = song.title;
    _artist.text = song.artist;
    _content.text = song.content;
    _key.text = readChordProDirective(song.content, 'key') ?? '';
    _tempo.text = readChordProDirective(song.content, 'tempo') ?? '';
    _time.text = readChordProDirective(song.content, 'time') ?? '';
    _folderId = song.folderId;
    _tags = song.tags;
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _key.dispose();
    _tempo.dispose();
    _time.dispose();
    _content.dispose();
    super.dispose();
  }

  String _composedContent() {
    return applyChordProMetadata(
      _content.text,
      title: _title.text,
      artist: _artist.text,
      key: _key.text,
      tempo: _tempo.text,
      timeSignature: _time.text,
    );
  }

  Future<void> _preview() async {
    final content = _composedContent();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              _title.text.trim().isEmpty
                  ? AppLocalizations.of(context).songsPreview
                  : _title.text.trim(),
            ),
          ),
          body: SongReader(content: content),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.songsTitleRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final content = _composedContent();
      final repo = ref.read(songRepositoryProvider);
      final SongRow saved;
      if (widget.isCreate) {
        saved = await repo.createSong(
          title: title,
          artist: _artist.text,
          content: content,
          folderId: _folderId,
          tags: _tags,
        );
      } else {
        saved = await repo.updateSong(
          id: widget.songId!,
          title: title,
          artist: _artist.text,
          content: content,
          folderId: _folderId,
          clearFolderId: _folderId == null,
          tags: _tags,
        );
      }

      // Best-effort push so Studio sees the song quickly.
      unawaited(ref.read(syncControllerProvider.notifier).syncAll());

      if (!mounted) return;
      context.go('/songs/${saved.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.commonError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!widget.isCreate) {
      final async = ref.watch(songByIdProvider(widget.songId!));
      if (async.isLoading && !_hydrated) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.songsEdit)),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (async.hasError) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.songsEdit)),
          body: ErrorState(
            title: l10n.commonError,
            description: l10n.commonErrorDesc,
          ),
        );
      }
      final song = async.valueOrNull;
      if (song == null) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.songsEdit)),
          body: EmptyState(
            icon: Icons.music_off_outlined,
            title: l10n.songsNotFound,
            description: l10n.songsNotFoundDesc,
          ),
        );
      }
      if (!_hydrated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _hydrateFromSong(song);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreate ? l10n.songsCreate : l10n.songsEdit),
        actions: [
          TextButton(
            onPressed: _saving ? null : _preview,
            child: Text(l10n.songsPreview),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.songsFieldTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artist,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.songsFieldArtist,
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
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _time,
                  decoration: InputDecoration(
                    labelText: l10n.songsFieldTime,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.songsRawContent,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _content,
            minLines: 14,
            maxLines: 28,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: l10n.songsChordPro,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(l10n.commonSave),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _preview,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.songsPreview),
          ),
        ],
      ),
    );
  }
}
