import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'chordpro/song_display_settings.dart';
import 'song_body_renderer.dart';

/// Tuning for the swipe-to-navigate gesture. Kept as top-level consts so
/// they're easy to tweak without hunting through the state class.
const double _kAxisLockDeadzone = 10.0;
const double _kHorizontalDominance =
    2.0; // dx must be >= 2x dy to lock horizontal
const double _kMaxOverscroll =
    48.0; // resistance cap when a direction is disabled
const double _kFlingVelocity = 700.0; // px/s to count a quick flick as a commit

/// Renders a song body with a floating auto-scroll control and, when in a
/// service, previous/next navigation — mirroring the React `SongView` reader.
///
/// Also supports swiping the song body left/right to move between songs in
/// a service, with a PowerPoint-style push transition.
class SongReader extends ConsumerStatefulWidget {
  const SongReader({
    super.key,
    required this.content,
    this.notes,
    this.onPrev,
    this.onNext,
    this.canPrev = false,
    this.canNext = false,
    this.positionLabel,
  });

  final String content;

  /// Optional musician notes shown in a card below the song metadata header.
  final String? notes;

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

  late final AnimationController _swipeController;

  // --- Swipe gesture state -------------------------------------------------
  Offset? _dragStart;
  bool?
  _horizontalLock; // null = undecided, true = horizontal, false = vertical
  double _offset = 0; // current horizontal translation of the song body
  VelocityTracker? _velocityTracker;
  bool _hapticFired = false;
  int?
  _pendingEnterDirection; // -1 = entering from the right, 1 = from the left

  bool get _swipeEnabled => widget.onPrev != null || widget.onNext != null;

  double get _viewportWidth {
    final width = MediaQuery.sizeOf(context).width;
    return width > 0 ? width : 360;
  }

  double get _swipeThreshold => math.max(88.0, _viewportWidth * 0.18);

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant SongReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content == widget.content) return;

    if (_pendingEnterDirection != null) {
      // We just navigated (via swipe or button) and the new song has
      // arrived — slide it in from the opposite edge to finish the push.
      final dir = _pendingEnterDirection!;
      _pendingEnterDirection = null;
      _offset = -dir * _viewportWidth;
      _animateOffsetTo(0);
    } else {
      // Content changed for some other reason — just snap, no transition.
      _swipeController.stop();
      _offset = 0;
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    _swipeController.dispose();
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
      // speed 1..10 → ~4..40 px/s.
      _scrollController.jumpTo(
        (_scrollController.offset + speed * 0.2).clamp(0, max),
      );
    });
  }

  // --- Swipe gesture handling ----------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (!_swipeEnabled || _swipeController.isAnimating) return;
    _dragStart = event.position;
    _horizontalLock = null;
    _hapticFired = false;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragStart == null) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final delta = event.position - _dragStart!;

    if (_horizontalLock == null) {
      if (delta.dx.abs() < _kAxisLockDeadzone &&
          delta.dy.abs() < _kAxisLockDeadzone) {
        return; // too small to tell intent yet
      }
      final isHorizontal =
          delta.dx.abs() > delta.dy.abs() * _kHorizontalDominance;
      setState(() => _horizontalLock = isHorizontal);
      if (isHorizontal) _stopAutoScroll();
    }

    if (_horizontalLock != true) return; // vertical drag: let the list scroll

    var dx = delta.dx;
    final wantsNext = dx < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    if (!allowed) {
      dx = (dx / 3.5).clamp(-_kMaxOverscroll, _kMaxOverscroll);
    }

    if (!_hapticFired && allowed && dx.abs() >= _swipeThreshold) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    }

    setState(() => _offset = dx);
  }

  void _onPointerUp(PointerUpEvent event) => _finishDrag();
  void _onPointerCancel(PointerCancelEvent event) => _finishDrag();

  void _finishDrag() {
    if (_dragStart == null) return;
    final wasHorizontal = _horizontalLock == true;
    final finalOffset = _offset;
    final tracker = _velocityTracker;

    _dragStart = null;
    _horizontalLock = null;
    _velocityTracker = null;

    if (!wasHorizontal) return;

    final wantsNext = finalOffset < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    final velocityDx = tracker?.getVelocity().pixelsPerSecond.dx ?? 0;
    final isFling =
        velocityDx.abs() > _kFlingVelocity && (velocityDx < 0) == wantsNext;

    if (allowed && (finalOffset.abs() >= _swipeThreshold || isFling)) {
      _completeSwipe(wantsNext ? -1 : 1);
    } else {
      _animateOffsetTo(0);
    }
  }

  /// Programmatically triggers the same push transition as a completed
  /// swipe — used by the prev/next buttons so both paths feel consistent.
  void _goPrev() {
    if (!widget.canPrev || _swipeController.isAnimating) return;
    _stopAutoScroll();
    _completeSwipe(1);
  }

  void _goNext() {
    if (!widget.canNext || _swipeController.isAnimating) return;
    _stopAutoScroll();
    _completeSwipe(-1);
  }

  /// dir: -1 pushes the current song out to the left (going to "next"),
  ///       1 pushes it out to the right (going to "previous").
  void _completeSwipe(int dir) {
    final target = dir * _viewportWidth;
    _animateOffsetTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeIn,
      onComplete: () {
        _pendingEnterDirection = dir;
        if (dir < 0) {
          widget.onNext?.call();
        } else {
          widget.onPrev?.call();
        }
      },
    );
  }

  void _animateOffsetTo(
    double target, {
    Duration duration = const Duration(milliseconds: 240),
    Curve curve = Curves.easeOutCubic,
    VoidCallback? onComplete,
  }) {
    final tween = Tween<double>(begin: _offset, end: target);
    _swipeController
      ..stop()
      ..reset()
      ..duration = duration;

    void listener() {
      if (!mounted) return;
      setState(
        () =>
            _offset = tween.transform(curve.transform(_swipeController.value)),
      );
    }

    _swipeController.addListener(listener);
    _swipeController.forward().whenCompleteOrCancel(() {
      _swipeController.removeListener(listener);
      onComplete?.call();
    });
  }

  Widget _buildSwipeEdgeIndicator(ThemeData theme, AppLocalizations l10n) {
    final goingNext = _offset < 0;
    final progress = (_offset.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final revealWidth = _offset.abs().clamp(0.0, _viewportWidth);
    final allowed = goingNext ? widget.canNext : widget.canPrev;

    return Positioned(
      top: 0,
      bottom: 0,
      right: goingNext ? 0 : null,
      left: goingNext ? null : 0,
      width: revealWidth,
      child: IgnorePointer(
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          alignment: Alignment.center,
          child: Opacity(
            opacity: allowed ? progress : progress * 0.35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  goingNext ? Icons.chevron_left : Icons.chevron_right,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  goingNext ? l10n.songNext : l10n.songPrevious,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showNav = widget.onPrev != null || widget.onNext != null;

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(_offset, 0),
                  child: IgnorePointer(
                    // Disable the song body's own scroll gesture while a
                    // horizontal swipe is locked in, so it can't also try
                    // to scroll vertically at the same time.
                    ignoring: _horizontalLock == true,
                    child: SongBodyRenderer(
                      content: widget.content,
                      notes: widget.notes,
                      scrollController: _scrollController,
                    ),
                  ),
                ),
                if (_dragStart != null && _horizontalLock == true)
                  _buildSwipeEdgeIndicator(theme, l10n),
              ],
            ),
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
                  onPrev: _goPrev,
                  onNext: _goNext,
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
