import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'chordpro/song_display_settings.dart';
import 'song_body_renderer.dart';

/// Renders a song body with a floating auto-scroll control and, when in a
/// service, previous/next navigation — mirroring the React `SongView` reader.
class SongReader extends ConsumerStatefulWidget {
  const SongReader({
    super.key,
    required this.content,
    this.onPrev,
    this.onNext,
    this.canPrev = false,
    this.canNext = false,
    this.positionLabel,
  });

  final String content;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool canPrev;
  final bool canNext;

  /// e.g. "2 / 5" — shown between the prev/next buttons when navigating a
  /// service. When null, the prev/next controls are hidden.
  final String? positionLabel;

  @override
  ConsumerState<SongReader> createState() => _SongReaderState();
}

class _SongReaderState extends ConsumerState<SongReader>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _isScrolling = false;
  }

  void _toggleAutoScroll() {
    if (_isScrolling) {
      setState(_stopAutoScroll);
      return;
    }

    final speed = ref.read(songDisplaySettingsProvider).autoScrollSpeed;
    setState(() => _isScrolling = true);
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= max) {
        _stopAutoScroll();
        if (mounted) setState(() {});
        return;
      }
      // speed 1..10 → ~12..120 px/s.
      _scrollController.jumpTo(
        (_scrollController.offset + speed * 0.6).clamp(0, max),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showNav = widget.onPrev != null || widget.onNext != null;

    return Stack(
      children: [
        Positioned.fill(
          child: SongBodyRenderer(
            content: widget.content,
            scrollController: _scrollController,
          ),
        ),

        // Floating right-side controls: auto-scroll + prev/next.
        Positioned(
          right: 16,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: null,
                onPressed: _toggleAutoScroll,
                backgroundColor: _isScrolling
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
                foregroundColor: _isScrolling
                    ? theme.colorScheme.surface
                    : theme.colorScheme.onPrimary,
                tooltip: _isScrolling
                    ? l10n.songAutoScrollPause
                    : l10n.songAutoScrollStart,
                child: Icon(
                  _isScrolling ? Icons.pause : Icons.keyboard_double_arrow_down,
                ),
              ),
              if (showNav) const SizedBox(height: 12),
              if (showNav)
                _ReaderNav(
                  positionLabel: widget.positionLabel,
                  canPrev: widget.canPrev,
                  canNext: widget.canNext,
                  onPrev: widget.onPrev!,
                  onNext: widget.onNext!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReaderNav extends StatelessWidget {
  const _ReaderNav({
    required this.positionLabel,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final String? positionLabel;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = positionLabel ?? '';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.songPrevious,
          ),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.songNext,
          ),
        ],
      ),
    );
  }
}
