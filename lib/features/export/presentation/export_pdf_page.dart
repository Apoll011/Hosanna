import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/domain/chordpro/parser.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../../songs/presentation/song_reader.dart';
import '../../songs/presentation/song_toolbar.dart';
import '../domain/song_pdf_builder.dart';

/// Exports a song as a PDF.
///
/// The page mirrors [SongDetailPage]: it previews the song through the reader
/// and exposes the same reading-settings toolbar (transpose, capo, chords,
/// two-column, font size, instrument, diagrams and variant). Tapping the share
/// action builds the PDF with those exact settings.
class ExportPdfPage extends ConsumerStatefulWidget {
  const ExportPdfPage({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<ExportPdfPage> createState() => _ExportPdfPageState();
}

class _ExportPdfPageState extends ConsumerState<ExportPdfPage> {
  bool _isExporting = false;

  /// Last previewed content, used to restore the shared document provider when
  /// this preview is popped (its nested renderer clears it on dispose).
  String? _lastContent;
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    final content = _lastContent;
    if (content != null) {
      _container?.read(songCurrentDocumentProvider.notifier).state =
          parseChordProDocument(content);
    }
    super.dispose();
  }

  Future<void> _exportAndShare(SongRow song) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);

    try {
      final settings = ref.read(songDisplaySettingsProvider);
      final bytes = await buildSongPdf(
        content: song.content,
        fallbackTitle: song.title,
        fallbackArtist: song.artist,
        songNumber: song.songNumber,
        options: SongPdfOptions(
          transpose: settings.transpose,
          capo: settings.capo,
          showChords: settings.showChords,
          twoColumn: settings.twoColumn,
          fontSize: settings.fontSize,
          instrument: settings.instrument,
          showDiagrams: settings.showDiagrams,
          sectionColorBackground: settings.sectionColorBackground,
          variantId: settings.variantId,
        ),
      );

      final fileName = '${_sanitizeFileName(song.title)}.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: [fileName],
          subject: song.title,
          text: song.title,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _sanitizeFileName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'song' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportPdfTitle),
        actions: [
          const SongToolbarButton(),
          IconButton(
            tooltip: l10n.navExportPdf,
            onPressed: (_isExporting || songAsync.value == null)
                ? null
                : () => _exportAndShare(songAsync.value!),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (song) {
          if (song == null) {
            return Center(child: Text(l10n.songsNoResults));
          }
          _lastContent = song.content;
          return SongReader(content: song.content);
        },
      ),
    );
  }
}
