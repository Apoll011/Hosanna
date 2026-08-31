import 'dart:async';
import 'dart:math' as math;

import 'package:fluera_canvas/fluera_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosanna/app/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../../app/settings_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../services/data/service_annotation_repository.dart';
import 'chordpro/song_display_settings.dart';
import 'song_body_renderer.dart';

/// Tuning for the swipe-to-navigate gesture.
const double _kMaxOverscroll = 48.0;
const double _kFlingVelocity = 700.0;

/// Default preset palette for Hosanna annotations.
const List<Color> _kAnnotationPalette = <Color>[
  Color(0xFFE53935), // Red
  Color(0xFFFB8C00), // Orange
  Color(0xFFFDD835), // Yellow
  Color(0xFF43A047), // Green
  Color(0xFF1E88E5), // Blue
  Color(0xFF8E24AA), // Purple
  Color(0xFFFFFFFF), // White
  Color(0xFF212121), // Dark
];

/// Renders a song body with a floating auto-scroll control and, when in a
/// service, previous/next navigation and synchronized FlueraCanvas annotations.
class SongReader extends ConsumerStatefulWidget {
  const SongReader({
    super.key,
    required this.content,
    this.notes,
    this.serviceId,
    this.songId,
    this.isAnnotating = false,
    this.onPrev,
    this.onNext,
    this.canPrev = false,
    this.canNext = false,
    this.positionLabel,
  });

  final String content;

  /// Optional musician notes shown in a card below the song metadata header.
  final String? notes;

  /// Identifiers for saving/loading per-song, per-service annotations.
  final String? serviceId;
  final String? songId;

  /// Whether annotation mode is currently active.
  final bool isAnnotating;

  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool canPrev;
  final bool canNext;

  /// e.g. "2 / 5" — shown between the prev/next buttons when navigating a service.
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

  // --- Canvas Annotation state ---------------------------------------------
  RealtimeChannel? _annotationChannel;
  bool _hasPendingRemoteUpdate = false;
  Uint8List? _pendingRemoteBytes;

  final GlobalKey<FlueraCanvasState> _canvasKey =
      GlobalKey<FlueraCanvasState>();
  late final InfiniteCanvasController _canvasController;
  CanvasTool _canvasTool = CanvasTool.draw;
  Color _canvasColor = const Color(0xFFE53935);
  double _canvasStrokeWidth = 3.5;
  final double _canvasEraserRadius = 28.0;
  bool _isPointerActive = false;
  Uint8List? _initialBytes;
  String? _loadedSongKey;

  // --- Swipe gesture state -------------------------------------------------
  bool _dragActive = false;
  double _dragTotalDx = 0;
  double _offset = 0;
  bool _hapticFired = false;
  int? _pendingEnterDirection;

  bool get _swipeEnabled =>
      !widget.isAnnotating && (widget.onPrev != null || widget.onNext != null);

  double get _viewportWidth {
    final width = MediaQuery.sizeOf(context).width;
    return width > 0 ? width : 360;
  }

  double get _swipeThreshold => math.max(88.0, _viewportWidth * 0.18);

  DateTime? _remoteUpdatedAt;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(vsync: this);
    _canvasController = InfiniteCanvasController();
    _scrollController.addListener(_onScrollUpdated);
    _loadAnnotationForCurrentSong();
  }

  Future<void> _loadAnnotationForCurrentSong() async {
    final serviceId = widget.serviceId;
    final songId = widget.songId;
    if (serviceId == null || songId == null) return;
    final key = '${serviceId}_$songId';
    _loadedSongKey = key;

    final repo = ref.read(serviceAnnotationRepositoryProvider);
    final syncEnabled = ref.read(settingsControllerProvider).syncAnnotations;

    Uint8List? bytes;
    _remoteUpdatedAt = null;

    if (syncEnabled) {
      final remote = await repo.fetchRemoteAnnotation(
        serviceId: serviceId,
        songId: songId,
      );
      if (remote != null) {
        bytes = remote.bytes;
        _remoteUpdatedAt = remote.updatedAt;
      }
    }

    bytes ??= await repo.loadAnnotation(serviceId: serviceId, songId: songId);

    if (!mounted || _loadedSongKey != key) return;

    _applyLoadedBytes(bytes);
    _subscribeIfNeeded(
      serviceId: serviceId,
      songId: songId,
      syncEnabled: syncEnabled,
    );
  }

  void _applyLoadedBytes(Uint8List? bytes) {
    final canvasState = _canvasKey.currentState;
    if (canvasState != null) {
      if (bytes != null && bytes.isNotEmpty) {
        try {
          canvasState.loadFromBytes(bytes);
        } catch (_) {
          canvasState.clear();
        }
      } else {
        canvasState.clear();
      }
    } else {
      setState(() {
        _initialBytes = bytes;
      });
    }
  }

  void _subscribeIfNeeded({
    required String serviceId,
    required String songId,
    required bool syncEnabled,
  }) {
    _unsubscribeAnnotations();
    if (!syncEnabled) return;

    final repo = ref.read(serviceAnnotationRepositoryProvider);
    _annotationChannel = repo.subscribeToAnnotationUpdates(
      serviceId: serviceId,
      songId: songId,
      onRemoteChange: () => _handleRemoteChange(serviceId, songId),
    );
  }

  Future<void> _handleRemoteChange(String serviceId, String songId) async {
    final repo = ref.read(serviceAnnotationRepositoryProvider);
    final remote = await repo.fetchRemoteAnnotation(
      serviceId: serviceId,
      songId: songId,
    );
    if (remote == null || !mounted) return;
    debugPrint("$_remoteUpdatedAt");
    // Stale event (arrived out of order) or our own echo — ignore.
    if (_remoteUpdatedAt != null &&
        !remote.updatedAt.isAfter(_remoteUpdatedAt!)) {
      return;
    }
    _remoteUpdatedAt = remote.updatedAt;

    if (widget.isAnnotating) {
      setState(() {
        _hasPendingRemoteUpdate = true;
        _pendingRemoteBytes = remote.bytes;
      });
    } else {
      _applyLoadedBytes(remote.bytes);
    }
  }

  void _unsubscribeAnnotations() {
    final channel = _annotationChannel;
    _annotationChannel = null;
    if (channel != null) {
      ref.read(serviceAnnotationRepositoryProvider).unsubscribe(channel);
    }
  }

  void _acceptPendingRemoteUpdate() {
    final bytes = _pendingRemoteBytes;
    setState(() {
      _hasPendingRemoteUpdate = false;
      _pendingRemoteBytes = null;
    });
    if (bytes != null) _applyLoadedBytes(bytes);
  }

  void _dismissPendingRemoteUpdate() {
    setState(() {
      _hasPendingRemoteUpdate = false;
      _pendingRemoteBytes = null;
    });
  }

  void _onScrollUpdated() {
    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      final max = pos.hasContentDimensions
          ? pos.maxScrollExtent
          : double.infinity;
      final clamped = _scrollController.offset.clamp(
        0.0,
        math.max<double>(0.0, max),
      );
      _canvasController.setOffset(Offset(0, -clamped));
    }
  }

  @override
  void didUpdateWidget(covariant SongReader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.serviceId != widget.serviceId ||
        oldWidget.songId != widget.songId) {
      _saveAnnotation(oldWidget.serviceId, oldWidget.songId);
      _canvasKey.currentState?.clear();
      _loadAnnotationForCurrentSong();
    } else if (oldWidget.isAnnotating && !widget.isAnnotating) {
      _saveCurrentAnnotation();
      if (_hasPendingRemoteUpdate) {
        setState(() {
          _hasPendingRemoteUpdate = false;
          _pendingRemoteBytes = null;
        });
      }
    }
    if (oldWidget.content != widget.content) {
      if (_pendingEnterDirection != null) {
        final dir = _pendingEnterDirection!;
        _pendingEnterDirection = null;
        _offset = -dir * _viewportWidth;
        _animateOffsetTo(0);
      } else {
        _swipeController.stop();
        _offset = 0;
      }
    }
  }

  @override
  void dispose() {
    _saveAnnotation(widget.serviceId, widget.songId);
    _unsubscribeAnnotations();
    _scrollController.removeListener(_onScrollUpdated);
    _stopAutoScroll();
    _scrollController.dispose();
    _swipeController.dispose();
    _canvasController.dispose();
    super.dispose();
  }

  void _saveAnnotation(String? serviceId, String? songId) {
    if (serviceId == null || songId == null) return;
    final canvasState = _canvasKey.currentState;
    if (canvasState == null) return;

    final Uint8List bytes;
    try {
      bytes = canvasState.toBytes();
    } catch (_) {
      return;
    }

    final repo = ref.read(serviceAnnotationRepositoryProvider);
    repo.saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

    final syncEnabled = ref.read(settingsControllerProvider).syncAnnotations;
    if (!syncEnabled) return;

    _pushAnnotationSafely(
      repo: repo,
      serviceId: serviceId,
      songId: songId,
      bytes: bytes,
    );
  }

  Future<void> _pushAnnotationSafely({
    required ServiceAnnotationRepository repo,
    required String serviceId,
    required String songId,
    required Uint8List bytes,
  }) async {
    try {
      final updatedAt = await repo.pushAnnotation(
        serviceId: serviceId,
        songId: songId,
        bytes: bytes,
      );
      _remoteUpdatedAt = updatedAt;
    } catch (_) {
      // Offline or push failed — local cache already has the latest bytes;
      // the next successful save retries the sync.
    }
  }

  void _saveCurrentAnnotation() {
    _saveAnnotation(widget.serviceId, widget.songId);
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
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= max) {
        _stopAutoScroll();
        if (mounted) setState(() {});
        return;
      }
      _scrollController.jumpTo(
        (_scrollController.offset + speed * (16.0 / 250.0)).clamp(0, max),
      );
    });
  }

  // --- Swipe gesture handling ----------------------------------------------

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_swipeController.isAnimating) return;
    _dragTotalDx = 0;
    _hapticFired = false;
    _stopAutoScroll();
    setState(() => _dragActive = true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_dragActive) return;
    _dragTotalDx += details.delta.dx;
    final wantsNext = _dragTotalDx < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    final double dx;
    if (allowed) {
      dx = _dragTotalDx;
    } else {
      dx = (_dragTotalDx / 3.5).clamp(-_kMaxOverscroll, _kMaxOverscroll);
    }

    if (!_hapticFired && allowed && dx.abs() >= _swipeThreshold) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    }

    setState(() => _offset = dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_dragActive) return;
    _dragActive = false;
    _dragTotalDx = 0;

    final finalOffset = _offset;
    final wantsNext = finalOffset < 0;
    final allowed = wantsNext ? widget.canNext : widget.canPrev;
    final velocityDx = details.primaryVelocity ?? 0;
    final isFling =
        velocityDx.abs() > _kFlingVelocity && (velocityDx < 0) == wantsNext;

    if (allowed && (finalOffset.abs() >= _swipeThreshold || isFling)) {
      _completeSwipe(wantsNext ? -1 : 1);
    } else {
      _animateOffsetTo(0);
    }
  }

  void _onHorizontalDragCancel() {
    if (!_dragActive) return;
    _dragActive = false;
    _dragTotalDx = 0;
    _animateOffsetTo(0);
  }

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

  Widget _buildCanvasOverlay() {
    return Listener(
      onPointerDown: (_) {
        if (!_isPointerActive) {
          setState(() => _isPointerActive = true);
        }
      },
      onPointerUp: (_) {
        if (_isPointerActive) {
          setState(() => _isPointerActive = false);
        }
      },
      onPointerCancel: (_) {
        if (_isPointerActive) {
          setState(() => _isPointerActive = false);
        }
      },
      child: FlueraCanvas(
        key: _canvasKey,
        controller: _canvasController,
        tool: widget.isAnnotating ? _canvasTool : CanvasTool.draw,
        strokeColor: _canvasColor,
        strokeWidth: _canvasStrokeWidth,
        eraserRadius: _canvasEraserRadius,
        showEraserPreview: widget.isAnnotating && _isPointerActive,
        background: const CanvasBackground.solid(Colors.transparent),
        initialBytes: _initialBytes,
        onStrokeCommitted: (_) => _saveCurrentAnnotation(),
        onStrokesErased: (_) => _saveCurrentAnnotation(),
        onNodesDeleted: (_) => _saveCurrentAnnotation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      settingsControllerProvider.select((s) => s.syncAnnotations),
      (previous, next) {
        if (previous == next) return;
        final serviceId = widget.serviceId;
        final songId = widget.songId;
        if (serviceId == null || songId == null) return;
        if (next) {
          _loadAnnotationForCurrentSong(); // pulls remote + resubscribes
        } else {
          _unsubscribeAnnotations();
        }
      },
    );

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final showNav = widget.onPrev != null || widget.onNext != null;
    final hasServiceSong = widget.serviceId != null && widget.songId != null;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _swipeEnabled
                ? _onHorizontalDragStart
                : null,
            onHorizontalDragUpdate: _swipeEnabled
                ? _onHorizontalDragUpdate
                : null,
            onHorizontalDragEnd: _swipeEnabled ? _onHorizontalDragEnd : null,
            onHorizontalDragCancel: _swipeEnabled
                ? _onHorizontalDragCancel
                : null,
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(_offset, 0),
                  child: Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          _onScrollUpdated();
                          return false;
                        },
                        child: SongBodyRenderer(
                          content: widget.content,
                          notes: widget.notes,
                          scrollController: _scrollController,
                        ),
                      ),
                      if (hasServiceSong)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !widget.isAnnotating,
                            child: _buildCanvasOverlay(),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_dragActive) _buildSwipeEdgeIndicator(theme, l10n),
              ],
            ),
          ),
        ),

        if (widget.isAnnotating && _hasPendingRemoteUpdate)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('New changes from another device'),
                      ),
                      TextButton(
                        onPressed: _dismissPendingRemoteUpdate,
                        child: const Text('Keep mine'),
                      ),
                      FilledButton(
                        onPressed: _acceptPendingRemoteUpdate,
                        child: const Text('Reload'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Elegant floating annotation toolbar with all tools
        if (widget.isAnnotating)
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: _HosannaAnnotationToolbar(
                canvasKey: _canvasKey,
                tool: _canvasTool,
                onToolChanged: (t) => setState(() => _canvasTool = t),
                color: _canvasColor,
                onColorChanged: (c) => setState(() => _canvasColor = c),
                strokeWidth: _canvasStrokeWidth,
                onStrokeWidthChanged: (w) =>
                    setState(() => _canvasStrokeWidth = w),
                onStrokeCommitted: _saveCurrentAnnotation,
                onClearAll: () {
                  setState(() {});
                  _saveCurrentAnnotation();
                },
              ),
            ),
          ),

        // Floating right-side controls: auto-scroll + prev/next (hidden during annotation).
        if (!widget.isAnnotating)
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
                    _isScrolling
                        ? Icons.pause
                        : Icons.keyboard_double_arrow_down,
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

/// Custom sleek toolbar for annotations supporting all tools.
class _HosannaAnnotationToolbar extends StatelessWidget {
  const _HosannaAnnotationToolbar({
    required this.canvasKey,
    required this.tool,
    required this.onToolChanged,
    required this.color,
    required this.onColorChanged,
    required this.strokeWidth,
    required this.onStrokeWidthChanged,
    required this.onStrokeCommitted,
    required this.onClearAll,
  });

  final GlobalKey<FlueraCanvasState> canvasKey;
  final CanvasTool tool;
  final ValueChanged<CanvasTool> onToolChanged;
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double strokeWidth;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onStrokeCommitted;
  final VoidCallback onClearAll;

  void _showClearConfirm(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.annotationClear),
        content: Text(l10n.annotationClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              final state = canvasKey.currentState;
              if (state != null) {
                state.clear();
              }
              onClearAll();
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _openLayersSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.annotationLayers,
                  style: Theme.of(sheetCtx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(child: FlueraLayerPanel(canvasKey: canvasKey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required CanvasTool targetTool,
    required IconData icon,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final isSelected = tool == targetTool;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onToolChanged(targetTool),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final state = canvasKey.currentState;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.97,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: All Drawing Tools (Pen, Stroke Eraser, Pixel Eraser, Shapes, Text, Select, Lasso) + Layers + History Actions
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.draw,
                            icon: Icons.edit_outlined,
                            tooltip: l10n.annotationPen,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.erase,
                            icon: Icons.auto_fix_normal_outlined,
                            tooltip: l10n.annotationEraser,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.erasePixel,
                            icon: Icons.cleaning_services_outlined,
                            tooltip: l10n.annotationPixelEraser,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.line,
                            icon: Icons.horizontal_rule_rounded,
                            tooltip: l10n.annotationLine,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.rectangle,
                            icon: Icons.crop_square_rounded,
                            tooltip: l10n.annotationRectangle,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.ellipse,
                            icon: Icons.circle_outlined,
                            tooltip: l10n.annotationEllipse,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.text,
                            icon: Icons.text_fields_rounded,
                            tooltip: l10n.annotationText,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.select,
                            icon: Icons.touch_app_outlined,
                            tooltip: l10n.annotationSelect,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.lasso,
                            icon: Icons.gesture_rounded,
                            tooltip: l10n.annotationLasso,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 20,
                            width: 1,
                            color: theme.colorScheme.outlineVariant,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.layers_outlined, size: 20),
                            tooltip: l10n.annotationLayers,
                            onPressed: () => _openLayersSheet(context, l10n),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // History Actions
                  if (state != null)
                    ListenableBuilder(
                      listenable: state.historyListenable,
                      builder: (ctx, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.undo_rounded, size: 20),
                            tooltip: l10n.annotationUndo,
                            onPressed: state.canUndo
                                ? () {
                                    state.undo();
                                    onStrokeCommitted();
                                  }
                                : null,
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.redo_rounded, size: 20),
                            tooltip: l10n.annotationRedo,
                            onPressed: state.canRedo
                                ? () {
                                    state.redo();
                                    onStrokeCommitted();
                                  }
                                : null,
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                              size: 20,
                            ),
                            tooltip: l10n.annotationClear,
                            onPressed: () => _showClearConfirm(context, l10n),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.undo_rounded, size: 20),
                          tooltip: l10n.annotationUndo,
                          onPressed: null,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.redo_rounded, size: 20),
                          tooltip: l10n.annotationRedo,
                          onPressed: null,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 20,
                          ),
                          tooltip: l10n.annotationClear,
                          onPressed: () => _showClearConfirm(context, l10n),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Swatches, Prominent Color Picker Button & Stroke Width Slider
              Row(
                children: [
                  for (final c in _kAnnotationPalette)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          onColorChanged(c);
                          if (tool == CanvasTool.erase ||
                              tool == CanvasTool.erasePixel) {
                            onToolChanged(CanvasTool.draw);
                          }
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.toARGB32() == color.toARGB32()
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(
                                      alpha: 0.4,
                                    ),
                              width: c.toARGB32() == color.toARGB32() ? 2.5 : 1,
                            ),
                          ),
                          child: c.toARGB32() == color.toARGB32()
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: c.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  // Prominent & comfortable Color Picker button
                  Tooltip(
                    message: l10n.annotationColorPicker,
                    child: Material(
                      color: theme.colorScheme.surfaceContainer,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          final picked = await showFlueraColorPicker(
                            context: context,
                            initial: color,
                            title: l10n.annotationColorPicker,
                          );
                          if (picked != null) {
                            onColorChanged(picked);
                            if (tool == CanvasTool.erase ||
                                tool == CanvasTool.erasePixel) {
                              onToolChanged(CanvasTool.draw);
                            }
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.colorize_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: strokeWidth,
                        min: 1.0,
                        max: 16.0,
                        onChanged: onStrokeWidthChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
