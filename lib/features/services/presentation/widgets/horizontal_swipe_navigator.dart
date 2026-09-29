import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Horizontal drag navigation used for service elements (songs and non-songs).
class HorizontalSwipeNavigator extends StatefulWidget {
  const HorizontalSwipeNavigator({
    super.key,
    required this.child,
    required this.canPrev,
    required this.canNext,
    this.onPrev,
    this.onNext,
    this.positionLabel,
    this.showFloatingNav = true,
  });

  final Widget child;
  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final String? positionLabel;
  final bool showFloatingNav;

  @override
  State<HorizontalSwipeNavigator> createState() =>
      _HorizontalSwipeNavigatorState();
}

class _HorizontalSwipeNavigatorState extends State<HorizontalSwipeNavigator>
    with SingleTickerProviderStateMixin {
  static const _kMaxOverscroll = 48.0;
  static const _kFlingVelocity = 700.0;

  late final AnimationController _controller;
  bool _dragActive = false;
  double _offset = 0;
  bool _hapticFired = false;

  bool get _enabled => widget.onPrev != null || widget.onNext != null;

  double get _viewportWidth {
    final width = MediaQuery.sizeOf(context).width;
    return width > 0 ? width : 360;
  }

  double get _swipeThreshold => math.max(88.0, _viewportWidth * 0.18);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    if (!_enabled || _controller.isAnimating) return;
    _controller.stop();
    setState(() {
      _dragActive = true;
      _hapticFired = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragActive) return;
    final dx = details.primaryDelta ?? 0;
    final wantsNext = dx < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    var next = _offset + dx;
    if (!allowed) {
      next = next.clamp(-_kMaxOverscroll, _kMaxOverscroll);
    } else {
      next = next.clamp(-_viewportWidth, _viewportWidth);
    }
    if (!_hapticFired && allowed && next.abs() >= _swipeThreshold) {
      HapticFeedback.selectionClick();
      _hapticFired = true;
    }
    setState(() => _offset = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragActive) return;
    final wantsNext = _offset < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    final velocity = details.primaryVelocity ?? 0;
    final isFling = wantsNext
        ? velocity < -_kFlingVelocity
        : velocity > _kFlingVelocity;
    final commit =
        allowed && (_offset.abs() >= _swipeThreshold || isFling);
    if (commit) {
      _animateOut(wantsNext: wantsNext);
    } else {
      _animateBack();
    }
  }

  void _onDragCancel() {
    if (!_dragActive) return;
    _animateBack();
  }

  void _animateBack() {
    final start = _offset;
    _controller
      ..duration = const Duration(milliseconds: 180)
      ..reset();
    void listener() {
      setState(() {
        _offset = start * (1 - Curves.easeOut.transform(_controller.value));
      });
    }

    _controller.addListener(listener);
    _controller.forward().whenCompleteOrCancel(() {
      _controller.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _offset = 0;
        _dragActive = false;
      });
    });
  }

  void _animateOut({required bool wantsNext}) {
    final start = _offset;
    final end = wantsNext ? -_viewportWidth : _viewportWidth;
    _controller
      ..duration = const Duration(milliseconds: 200)
      ..reset();
    final tween = Tween<double>(begin: start, end: end);
    void listener() {
      setState(() {
        _offset = tween.transform(Curves.easeIn.transform(_controller.value));
      });
    }

    _controller.addListener(listener);
    _controller.forward().whenCompleteOrCancel(() {
      _controller.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _offset = 0;
        _dragActive = false;
      });
      if (wantsNext) {
        widget.onNext?.call();
      } else {
        widget.onPrev?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showNav = widget.showFloatingNav && _enabled;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _enabled ? _onDragStart : null,
            onHorizontalDragUpdate: _enabled ? _onDragUpdate : null,
            onHorizontalDragEnd: _enabled ? _onDragEnd : null,
            onHorizontalDragCancel: _enabled ? _onDragCancel : null,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: widget.child,
            ),
          ),
        ),
        if (showNav)
          Positioned(
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 2,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.canPrev ? widget.onPrev : null,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: l10n.commonBack,
                      ),
                      if (widget.positionLabel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            widget.positionLabel!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: widget.canNext ? widget.onNext : null,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: l10n.commonNext,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
