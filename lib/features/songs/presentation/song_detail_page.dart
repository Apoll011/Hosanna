import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/settings_controller.dart';
import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../export/presentation/song_pdf_share.dart';
import '../data/song_repository.dart';
import 'chordpro/song_display_settings.dart';
import 'song_reader.dart';
import 'song_toolbar.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  const SongDetailPage({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsControllerProvider).keepScreenAwake) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  /// Builds the PDF from what the reader is currently showing and opens the
  /// system share sheet — no need to leave the song.
  Future<void> _exportAndShare(SongRow song) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);

    try {
      await shareSongPdf(
        content: song.content,
        title: song.title,
        artist: song.artist,
        songNumber: song.songNumber,
        settings: ref.read(songDisplaySettingsProvider),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));
    final song = songAsync.value;

    return Scaffold(
      appBar: AppBar(
        actions: [
          const SongToolbarButton(),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            tooltip: l10n.navExportPdf,
            onPressed: (_isExporting || song == null)
                ? null
                : () => _exportAndShare(song),
          ),
        ],
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (song) => song == null
            ? Center(child: Text(l10n.songsNoResults))
            : SongReader(content: song.content),
      ),
    );
  }
}
