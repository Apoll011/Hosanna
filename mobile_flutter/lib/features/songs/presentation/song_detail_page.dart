import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/song_repository.dart';
import 'song_body_renderer.dart';
import 'song_toolbar.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  const SongDetailPage({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  @override
  void initState() {
    super.initState();
    // Keep the screen awake while viewing a song.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));
    final song = songAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(song?.title ?? l10n.songsTitle),
        actions: [
          const SongToolbarButton(),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.navExportPdf,
            onPressed: () => context.push('/export-pdf'),
          ),
        ],
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (song) => song == null
            ? Center(child: Text(l10n.songsNoResults))
            : SongBodyRenderer(content: song.content),
      ),
    );
  }
}
