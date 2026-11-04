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
  final _contentFocus = FocusNode();

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
    final raw = widget.initialContent?.trim().isNotEmpty == true
        ? widget.initialContent!
        : defaultChordProContent(
            title: title.isEmpty ? 'Untitled' : title,
            artist: artist,
          );
    _title.text = title.isNotEmpty
        ? title
        : (readChordProDirective(raw, 'title') ?? '');
    _artist.text = artist.isNotEmpty
        ? artist
        : (readChordProDirective(raw, 'artist') ?? '');
    _key.text = readChordProDirective(raw, 'key') ?? 'G';
    _tempo.text = readChordProDirective(raw, 'tempo') ?? '';
    _time.text = readChordProDirective(raw, 'time') ?? '4/4';
    _content.text = stripManagedDirectives(raw);
    _folderId = widget.initialFolderId;
    _tags = widget.initialTags;
    _hydrated = true;
  }

  void _hydrateFromSong(SongRow song) {
    if (_hydrated) return;
    _hydrated = true;
    _title.text = song.title;
    _artist.text = song.artist;
    _key.text = readChordProDirective(song.content, 'key') ?? '';
    _tempo.text = readChordProDirective(song.content, 'tempo') ?? '';
    _time.text = readChordProDirective(song.content, 'time') ?? '';
    _content.text = stripManagedDirectives(song.content);
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
    _contentFocus.dispose();
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
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (previewContext) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: MaterialLocalizations.of(previewContext).backButtonTooltip,
              onPressed: () => Navigator.of(previewContext).pop(),
            ),
            title: Text(
              _title.text.trim().isEmpty
                  ? l10n.songsPreview
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

      unawaited(ref.read(syncControllerProvider.notifier).syncAll());

      if (!mounted) return;
      // Keep library under the detail page so the AppBar back button works.
      context.go('/songs');
      context.push('/songs/${saved.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.commonError;
      });
    }
  }

  Widget _metadataFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.songsFieldTitle,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _artist,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.songsFieldArtist,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _key,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.songsFieldKey,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _tempo,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.songsFieldTempo,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _time,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocus.requestFocus(),
                decoration: InputDecoration(
                  labelText: l10n.songsFieldTime,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bodyEditor(AppLocalizations l10n, {required bool expanded}) {
    final theme = Theme.of(context);
    final field = TextField(
      controller: _content,
      focusNode: _contentFocus,
      expands: expanded,
      maxLines: expanded ? null : 16,
      minLines: expanded ? null : 16,
      textAlignVertical: TextAlignVertical.top,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        height: 1.4,
        fontSize: 14.5,
      ),
      decoration: InputDecoration(
        hintText: l10n.songsChordPro,
        alignLabelWithHint: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 72),
      ),
    );

    if (!expanded) return field;
    return SizedBox.expand(child: field);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

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
          if (mounted) setState(() => _hydrateFromSong(song));
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreate ? l10n.songsCreate : l10n.songsEdit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        color: scheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _saving ? null : _preview,
                icon: const Icon(Icons.visibility_outlined),
                label: Text(l10n.songsPreview),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.commonSave),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: wide
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.songsRawContent,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: _bodyEditor(l10n, expanded: true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 96),
                        child: _metadataFields(l10n),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _metadataFields(l10n),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.songsRawContent,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _bodyEditor(l10n, expanded: true),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
