import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../app/design/illustrations.dart';
import '../../../../app/design/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/hosanna_surface.dart';
import '../../../../shared/widgets/shell_modal.dart';
import 'ai_import_models.dart';
import 'ai_import_nav.dart';

/// Max PDF pages sent to the server (1 primary + up to 4 extras).
const _maxPdfPages = 5;

/// Consistent capture settings for camera/gallery.
const _captureMaxWidth = 2048.0;
const _captureQuality = 85;

class AiImportSourcePage extends StatefulWidget {
  const AiImportSourcePage({super.key, this.folderId});

  /// Optional library folder to save into after review approval.
  final String? folderId;

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

  Future<bool> _looksLowQuality(Uint8List bytes) async {
    if (bytes.length < 40 * 1024) return true;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      return w < 800 || h < 800;
    } catch (_) {
      return false;
    }
  }

  /// Returns false if the user cancels after a quality warning.
  Future<bool> _confirmQualityIfNeeded(Uint8List bytes) async {
    if (!await _looksLowQuality(bytes)) return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.songsImportWithAi),
        content: Text(l10n.songsAiCaptureQualityHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    return proceed == true;
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
        imageQuality: _captureQuality,
        maxWidth: _captureMaxWidth,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!await _confirmQualityIfNeeded(bytes)) return;
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.photo,
          imageBytes: bytes,
          mimeType: 'image/jpeg',
          fileName: file.name,
          folderId: widget.folderId,
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
        imageQuality: _captureQuality,
        maxWidth: _captureMaxWidth,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      if (!await _confirmQualityIfNeeded(bytes)) return;
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.gallery,
          imageBytes: bytes,
          mimeType: mime,
          fileName: file.name,
          folderId: widget.folderId,
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

      final pages = await _renderPdfPages(pdfBytes);
      if (pages.isEmpty) {
        throw StateError('Failed to rasterize PDF');
      }
      await _start(
        AiImportJobRequest(
          sourceType: AiImportSourceType.pdf,
          imageBytes: pages.first,
          mimeType: 'image/png',
          extraImageBytes: pages.length > 1
              ? pages.sublist(1)
              : const [],
          extraMimeTypes: pages.length > 1
              ? List.filled(pages.length - 1, 'image/png')
              : const [],
          pdfBytes: pdfBytes,
          fileName: file.name,
          folderId: widget.folderId,
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

  Future<List<Uint8List>> _renderPdfPages(Uint8List pdfBytes) async {
    final doc = await PdfDocument.openData(pdfBytes);
    try {
      final out = <Uint8List>[];
      final limit =
          doc.pages.length < _maxPdfPages ? doc.pages.length : _maxPdfPages;
      for (var i = 0; i < limit; i++) {
        out.add(await _renderPdfPage(doc.pages[i]));
      }
      return out;
    } finally {
      doc.dispose();
    }
  }

  Future<Uint8List> _renderPdfPage(PdfPage page) async {
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
            const SizedBox(height: 12),
            Text(
              l10n.songsAiCaptureTip,
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

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          leading: aiImportBackButton(
            context,
            enabled: !_busy,
          ),
          title: Text(l10n.songsImportWithAi),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Center(
                  child: Image.asset(
                    HosannaIllustrations.emptyImportSource,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: HosannaSpacing.md),
                Text(
                  l10n.songsImportSheetMusic,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: HosannaSpacing.xs),
                Text(
                  l10n.songsImportSheetMusicBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: HosannaSpacing.sm),
                HosannaSurface(
                  elevated: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: HosannaSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.songsAiCaptureTip,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: HosannaSpacing.sm),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: HosannaSpacing.xl),
                _SourceCard(
                  icon: Icons.photo_camera_outlined,
                  title: l10n.songsTakePhoto,
                  subtitle: l10n.songsImportWithAiDesc,
                  onTap: _busy ? null : _pickCamera,
                ),
                const SizedBox(height: HosannaSpacing.sm),
                _SourceCard(
                  icon: Icons.photo_library_outlined,
                  title: l10n.songsChooseGallery,
                  subtitle: l10n.songsImportWithAiDesc,
                  onTap: _busy ? null : _pickGallery,
                ),
                const SizedBox(height: HosannaSpacing.sm),
                _SourceCard(
                  icon: Icons.picture_as_pdf_outlined,
                  title: l10n.songsImportPdf,
                  subtitle: l10n.songsAiPdfMultiPageHint,
                  onTap: _busy ? null : _pickPdf,
                ),
                const SizedBox(height: HosannaSpacing.lg),
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
      ),
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
    return HosannaSurface(
      elevated: false,
      onTap: onTap,
      child: Row(
        children: [
          HosannaLeadingBadge(icon: icon),
          const SizedBox(width: HosannaSpacing.sm),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
