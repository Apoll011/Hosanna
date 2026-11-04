import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/illustrations.dart';
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

class _SongEditorPageState extends ConsumerState<SongEditorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _artist = TextEditingController();
  final _composer = TextEditingController();
  final _songNumber = TextEditingController();
  final _key = TextEditingController();
  final _originalKey = TextEditingController();
  final _tempo = TextEditingController();
  final _time = TextEditingController();
  final _duration = TextEditingController();
  final _capo = TextEditingController();
  final _keyNote = TextEditingController();
  final _copyright = TextEditingController();
  final _ccli = TextEditingController();
  final _youtube = TextEditingController();
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
    _tabs = TabController(length: 2, vsync: this);
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
    _applyFromContent(raw, titleOverride: title, artistOverride: artist);
    _folderId = widget.initialFolderId;
    _tags = widget.initialTags;
    _hydrated = true;
  }

  void _hydrateFromSong(SongRow song) {
    if (_hydrated) return;
    _hydrated = true;
    _applyFromContent(
      song.content,
      titleOverride: song.title,
      artistOverride: song.artist,
    );
    _folderId = song.folderId;
    _tags = song.tags;
  }

  void _applyFromContent(
    String raw, {
    String? titleOverride,
    String? artistOverride,
  }) {
    _title.text = (titleOverride != null && titleOverride.isNotEmpty)
        ? titleOverride
        : (readChordProDirective(raw, 'title') ?? '');
    _subtitle.text = readChordProDirective(raw, 'subtitle') ?? '';
    _artist.text = (artistOverride != null && artistOverride.isNotEmpty)
        ? artistOverride
        : (readChordProDirective(raw, 'artist') ?? '');
    _composer.text = readChordProDirective(raw, 'composer') ?? '';
    _songNumber.text = readChordProDirective(
          raw,
          'song_number',
          aliases: const ['songNumber'],
        ) ??
        '';
    _key.text = readChordProDirective(raw, 'key') ?? 'G';
    _originalKey.text = readChordProDirective(
          raw,
          'original_key',
          aliases: const ['originalKey'],
        ) ??
        '';
    _tempo.text = readChordProDirective(raw, 'tempo') ?? '';
    _time.text = readChordProDirective(
          raw,
          'time',
          aliases: const ['time_signature'],
        ) ??
        '4/4';
    _duration.text = _formatDurationForField(
      readChordProDirective(raw, 'duration'),
    );
    _capo.text = readChordProDirective(raw, 'capo') ?? '';
    _keyNote.text = readChordProDirective(
          raw,
          'key_note',
          aliases: const ['keyNote'],
        ) ??
        '';
    _copyright.text = readChordProDirective(raw, 'copyright') ?? '';
    _ccli.text = readChordProDirective(raw, 'ccli') ?? '';
    _youtube.text = readChordProDirective(raw, 'youtube') ?? '';
    _content.text = stripManagedDirectives(raw);
  }

  /// Parser stores duration as seconds; show m:ss in the field when numeric.
  String _formatDurationForField(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final seconds = int.tryParse(raw);
    if (seconds == null) return raw;
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _subtitle.dispose();
    _artist.dispose();
    _composer.dispose();
    _songNumber.dispose();
    _key.dispose();
    _originalKey.dispose();
    _tempo.dispose();
    _time.dispose();
    _duration.dispose();
    _capo.dispose();
    _keyNote.dispose();
    _copyright.dispose();
    _ccli.dispose();
    _youtube.dispose();
    _content.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  String _composedContent() {
    return applyChordProMetadata(
      _content.text,
      title: _title.text,
      subtitle: _subtitle.text,
      artist: _artist.text,
      composer: _composer.text,
      key: _key.text,
      originalKey: _originalKey.text,
      tempo: _tempo.text,
      timeSignature: _time.text,
      duration: _duration.text,
      capo: _capo.text,
      copyright: _copyright.text,
      ccli: _ccli.text,
      songNumber: _songNumber.text,
      keyNote: _keyNote.text,
      youtube: _youtube.text,
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
              tooltip:
                  MaterialLocalizations.of(previewContext).backButtonTooltip,
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
      setState(() {
        _error = l10n.songsTitleRequired;
        _tabs.index = 1;
      });
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: maxLines > 1
          ? TextCapitalization.sentences
          : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
    );
  }

  Widget _metadataForm(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 12),
        ],
        _field(_title, l10n.songsFieldTitle),
        const SizedBox(height: 10),
        _field(_subtitle, l10n.songsFieldSubtitle),
        const SizedBox(height: 10),
        _field(_artist, l10n.songsFieldArtist),
        const SizedBox(height: 10),
        _field(_composer, l10n.songsFieldComposer),
        const SizedBox(height: 10),
        _field(
          _songNumber,
          l10n.songsFieldSongNumber,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _field(_key, l10n.songsFieldKey)),
            const SizedBox(width: 8),
            Expanded(child: _field(_originalKey, l10n.songsFieldOriginalKey)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _field(
                _tempo,
                l10n.songsFieldTempo,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _field(_time, l10n.songsFieldTime)),
            const SizedBox(width: 8),
            Expanded(child: _field(_duration, l10n.songsFieldDuration)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _field(
                _capo,
                l10n.songsFieldCapo,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _field(_ccli, l10n.songsFieldCcli)),
          ],
        ),
        const SizedBox(height: 10),
        _field(
          _keyNote,
          l10n.songsFieldKeyNote,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 10),
        _field(_copyright, l10n.songsFieldCopyright),
        const SizedBox(height: 10),
        _field(
          _youtube,
          l10n.songsFieldYoutube,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _bodyEditor(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _content,
        focusNode: _contentFocus,
        expands: true,
        maxLines: null,
        minLines: null,
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
          contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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
            illustrationAsset: HosannaIllustrations.emptySongs,
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
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.songsTabContent),
            Tab(text: l10n.songsTabMetadata),
          ],
        ),
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
      body: TabBarView(
        controller: _tabs,
        children: [
          SafeArea(child: _bodyEditor(l10n)),
          SafeArea(child: _metadataForm(l10n)),
        ],
      ),
    );
  }
}
