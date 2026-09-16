import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/data/song_repository.dart';

class ExportPdfPage extends ConsumerStatefulWidget {
  const ExportPdfPage({super.key, required this.songId});

  final String songId;

  @override
  ConsumerState<ExportPdfPage> createState() => _ExportPdfPageState();
}

class _ExportPdfPageState extends ConsumerState<ExportPdfPage> {
  bool _isExporting = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _exportAndShare());
  }

  Future<void> _exportAndShare() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final song = await ref
          .read(songRepositoryProvider)
          .watchSong(widget.songId)
          .first;
      if (song == null) {
        setState(() {
          _isExporting = false;
          _errorMessage = l10n.songsNoResults;
        });
        return;
      }

      final pdfBytes = await _buildPdf(song);
      final fileName = '${_sanitizeFileName(song.title)}.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pdfBytes,
              mimeType: 'application/pdf',
            ),
          ],
          fileNameOverrides: [fileName],
          subject: song.title,
          text: song.title,
        ),
      );

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _errorMessage = l10n.commonError;
      });
    }
  }

  Future<Uint8List> _buildPdf(SongRow song) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            song.title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          if (song.artist.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(song.artist, style: const pw.TextStyle(fontSize: 14)),
          ],
          pw.SizedBox(height: 16),
          pw.Text(song.content),
        ],
      ),
    );
    return pdf.save();
  }

  String _sanitizeFileName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'song' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportPdfTitle)),
      body: Center(
        child: _isExporting
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage ?? l10n.commonError),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _exportAndShare,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
      ),
    );
  }
}
