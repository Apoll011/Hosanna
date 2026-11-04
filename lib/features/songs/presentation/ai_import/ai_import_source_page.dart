import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/shell_modal.dart';
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

  Future<void> _showHowItWorks() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    await showShellModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.songsHowItWorks,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.songsImportSheetMusicBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songsImportWithAi),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                height: 168,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.85),
                      scheme.secondaryContainer.withValues(alpha: 0.55),
                      scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -12,
                      bottom: -8,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 120,
                        color: scheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _HeroBadge(
                            icon: Icons.photo_camera_outlined,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 10),
                          _HeroBadge(
                            icon: Icons.picture_as_pdf_outlined,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 10),
                          _HeroBadge(
                            icon: Icons.auto_awesome_rounded,
                            color: scheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.songsImportSheetMusic,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.songsImportSheetMusicBody,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
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
                subtitle: l10n.songsImportWithAiDesc,
                onTap: _busy ? null : _pickCamera,
              ),
              const SizedBox(height: 10),
              _SourceCard(
                icon: Icons.photo_library_outlined,
                title: l10n.songsChooseGallery,
                subtitle: l10n.songsImportWithAiDesc,
                onTap: _busy ? null : _pickGallery,
              ),
              const SizedBox(height: 10),
              _SourceCard(
                icon: Icons.picture_as_pdf_outlined,
                title: l10n.songsImportPdf,
                subtitle: l10n.songsImportWithAiDesc,
                onTap: _busy ? null : _pickPdf,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: _busy ? null : _showHowItWorks,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: Text(l10n.songsHowItWorks),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const ModalBarrier(dismissible: false, color: Color(0x44000000)),
            Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.commonLoading,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
