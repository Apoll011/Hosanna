import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'ai_import_models.dart';

class AiImportSourcePage extends StatefulWidget {
  const AiImportSourcePage({super.key});

  @override
  State<AiImportSourcePage> createState() => _AiImportSourcePageState();
}

class _AiImportSourcePageState extends State<AiImportSourcePage> {
  bool _busy = false;
  String? _error;

  Future<void> _start(AiImportJobRequest request) async {
    if (!mounted) return;
    context.push('/songs/import/ai/progress', extra: request);
  }

  Future<void> _pickCamera() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.photo,
          imageBytes: bytes,
          mimeType: 'image/jpeg',
          fileName: file.name,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).commonError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickGallery() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.gallery,
          imageBytes: bytes,
          mimeType: mime,
          fileName: file.name,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).commonError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPdf() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final pdfBytes = await file.readAsBytes();
      if (pdfBytes.isEmpty) return;

      final screenshot = await _renderPdfFirstPage(pdfBytes);
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.pdf,
          imageBytes: screenshot,
          mimeType: 'image/png',
          pdfBytes: pdfBytes,
          fileName: file.name,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).commonError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Renders page 1 of [pdfBytes] to a PNG for Logos vision + anti-hallucination.
  Future<Uint8List> _renderPdfFirstPage(Uint8List pdfBytes) async {
    final doc = await PdfDocument.openData(pdfBytes);
    try {
      final page = doc.pages.first;
      final fullWidth = 1280.0;
      final fullHeight = page.height / page.width * fullWidth;
      final image = await page.renderForDisplay(
        fullWidth: fullWidth,
        fullHeight: fullHeight,
      );
      if (image == null) {
        throw StateError('Failed to rasterize PDF page');
      }
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('Failed to encode PDF screenshot');
        }
        return byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      doc.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.songsImportWithAi)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.songsImportSheetMusic,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.songsImportSheetMusicBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SourceCard(
                icon: Icons.photo_camera_outlined,
                title: l10n.songsTakePhoto,
                onTap: _busy ? null : _pickCamera,
              ),
              const SizedBox(height: 10),
              _SourceCard(
                icon: Icons.photo_library_outlined,
                title: l10n.songsChooseGallery,
                onTap: _busy ? null : _pickGallery,
              ),
              const SizedBox(height: 10),
              _SourceCard(
                icon: Icons.picture_as_pdf_outlined,
                title: l10n.songsImportPdf,
                onTap: _busy ? null : _pickPdf,
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Text(
                          l10n.songsImportSheetMusicBody,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.songsHowItWorks),
                ),
              ),
            ],
          ),
          if (_busy)
            const ModalBarrier(dismissible: false, color: Color(0x33000000)),
          if (_busy)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
