import 'dart:async';
import 'dart:math' as math;

import 'package:fluera_canvas/fluera_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosanna/app/providers.dart';

import '../../../app/settings_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../metronome/data/metronome_click_player.dart';
import '../../input/pedal_navigator.dart';
import '../../services/data/service_annotation_repository.dart';
import '../domain/chordpro/parser.dart';
import '../domain/youtube.dart';
import 'chordpro/song_display_settings.dart';
import 'song_body_renderer.dart';
import 'youtube_mini_player.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    this.onToggleAnnotation,
    this.onPrev,
    this.onNext,
    this.canPrev = false,
    this.canNext = false,
    this.positionLabel,
    this.showYoutube = true,
  });

  final String content;

  /// Optional musician notes shown in a card below the song metadata header.
  final String? notes;

  /// Identifiers for saving/loading per-song, per-service annotations.
  final String? serviceId;
  final String? songId;

  /// Whether annotation mode is currently active.
  final bool isAnnotating;

  ///If set to true even with videoURL does not show the video button
  final bool showYoutube;

  /// When set (service song reader), shows a floating annotation toggle.
  final VoidCallback? onToggleAnnotation;

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isScrolling = false;
  final MetronomeClickPlayer _metronomePlayer = MetronomeClickPlayer();
  final ValueNotifier<_SongMetronomeState> _metronomeState = ValueNotifier(
    const _SongMetronomeState(),
  );
  late final AnimationController _metronomePulseController;
  Timer? _metronomeTimer;
  DateTime? _nextMetronomeBeat;
  int _metronomeTempo = 100;
  int _metronomeBeatsPerBar = 4;
  int _metronomeDenominator = 4;
  String _metronomeTime = '4/4';
  bool _metronomeInitialized = false;

  /// Video playing in the bottom mini player, or `null` when it is closed.
  String? _playerVideoId;

  late final AnimationController _swipeController;

  // --- Canvas Annotation state ---------------------------------------------
  AnnotationSyncHandle? _annotationSubscription;
  bool _hasPendingRemoteUpdate = false;
  Uint8List? _pendingRemoteBytes;

  GlobalKey<FlueraCanvasState> _canvasKey = GlobalKey<FlueraCanvasState>();
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
  int? _remoteRevision;

  /// Cached so dispose / post-await work never looks up ancestors via [ref].
  late final ServiceAnnotationRepository _annotationRepo;
  late final SongDisplaySettingsController _displaySettings;
  bool _syncAnnotations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _annotationRepo = ref.read(serviceAnnotationRepositoryProvider);
    _displaySettings = ref.read(songDisplaySettingsProvider.notifier);
    _syncAnnotations = ref.read(settingsControllerProvider).syncAnnotations;
    _swipeController = AnimationController(vsync: this);
    _metronomePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _canvasController = InfiniteCanvasController();
    _scrollController.addListener(_onScrollUpdated);
    _applyTranspositionScope();
    _loadAnnotationForCurrentSong();
  }

  /// Service songs restore their own transpose/capo; standalone songs seed from directives.
  void _applyTranspositionScope() {
    final serviceId = widget.serviceId;
    final songId = widget.songId;
    if (serviceId != null && songId != null) {
      _displaySettings.enterServiceSong(serviceId: serviceId, songId: songId);
    } else if (songId != null) {
      _displaySettings.enterSongStandalone(songId: songId);
    } else {
      _displaySettings.leaveTranspositionScope();
    }
  }

  Future<void> _loadAnnotationForCurrentSong() async {
    final serviceId = widget.serviceId;
    final songId = widget.songId;
    if (serviceId == null || songId == null) return;
    final key = '${serviceId}_$songId';
    _loadedSongKey = key;

    final syncEnabled = _syncAnnotations;
    final repo = _annotationRepo;

    Uint8List? bytes;
    _remoteUpdatedAt = null;
    _remoteRevision = null;

    if (syncEnabled) {
      final remote = await repo.fetchRemoteAnnotation(
        serviceId: serviceId,
        songId: songId,
        preferServer: true,
      );
      if (remote != null) {
        bytes = remote.bytes;
        _rememberRemote(remote);
      }
    }

    bytes ??= await repo.loadAnnotation(serviceId: serviceId, songId: songId);

    if (!context.mounted || _loadedSongKey != key) return;

    _applyLoadedBytes(bytes);
    if (!context.mounted || _loadedSongKey != key) return;
    _subscribeIfNeeded(
      serviceId: serviceId,
      songId: songId,
      syncEnabled: syncEnabled,
    );
  }

  void _applyLoadedBytes(Uint8List? bytes) {
    if (!context.mounted) return;
    final alreadyMounted = _canvasKey.currentState != null;
    setState(() {
      _initialBytes = bytes;
      // Only replace the key when a canvas already exists. Otherwise the first
      // build picks up initialBytes naturally. Replacing a GlobalKey forces a
      // new State so initState reloads initialBytes (needed for live sync;
      // loadFromBytes alone can leave Impeller layers stale).
      if (alreadyMounted) {
        _canvasKey = GlobalKey<FlueraCanvasState>();
      }
    });
  }

  void _rememberRemote(RemoteAnnotation remote) {
    _remoteUpdatedAt = remote.updatedAt.toUtc();
    if (remote.revision != null) {
      _remoteRevision = remote.revision;
    }
  }

  /// True when [remote] is strictly newer than what we already applied.
  bool _isNewerRemote(RemoteAnnotation remote) {
    final rev = remote.revision;
    if (rev != null && _remoteRevision != null) {
      return rev > _remoteRevision!;
    }
    if (rev != null && _remoteRevision == null && _remoteUpdatedAt == null) {
      return true;
    }
    final remoteAt = remote.updatedAt.toUtc();
    if (_remoteUpdatedAt == null) return true;
    return remoteAt.isAfter(_remoteUpdatedAt!);
  }

  void _subscribeIfNeeded({
    required String serviceId,
    required String songId,
    required bool syncEnabled,
  }) {
    _unsubscribeAnnotations();
    if (!syncEnabled) return;
    if (!context.mounted) return;

    _annotationSubscription = _annotationRepo.subscribeToAnnotationUpdates(
      serviceId: serviceId,
      songId: songId,
      onRemoteUpdate: (remote) => _handleRemoteUpdate(remote),
    );
  }

  void _handleRemoteUpdate(RemoteAnnotation remote) {
    if (!context.mounted) return;
    if (!_isNewerRemote(remote)) return;

    _rememberRemote(remote);

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
    final sub = _annotationSubscription;
    _annotationSubscription = null;
    if (sub != null) {
      unawaited(_annotationRepo.unsubscribe(sub));
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
        oldWidget.songId != widget.songId ||
        oldWidget.content != widget.content) {
      _stopSongMetronome();
      _metronomeInitialized = false;
      _playerVideoId = null;
      _saveAnnotation(oldWidget.serviceId, oldWidget.songId);
      _applyTranspositionScope();
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
      _playerVideoId = null;
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
  void deactivate() {
    _stopSongMetronome();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopSongMetronome();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSongMetronome();
    _metronomePulseController.dispose();
    unawaited(_metronomePlayer.dispose());
    _metronomeState.dispose();
    _playerVideoId = null;
    _saveAnnotation(widget.serviceId, widget.songId);
    // Drop scope so the next song (service or library) never inherits this
    // one's transpose/capo. Service values are already saved on each change.
    _displaySettings.leaveTranspositionScope();
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

    final repo = _annotationRepo;
    repo.saveAnnotation(serviceId: serviceId, songId: songId, bytes: bytes);

    if (!_syncAnnotations) return;

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
      final pushed = await repo.pushAnnotation(
        serviceId: serviceId,
        songId: songId,
        bytes: bytes,
      );
      _remoteUpdatedAt = pushed.updatedAt.toUtc();
      _remoteRevision = pushed.revision;
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
    _stopSongMetronome();
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

  void _closeYoutubePlayer() {
    if (_playerVideoId == null) return;
    setState(() => _playerVideoId = null);
  }

  void _goPrev() {
    if (!widget.canPrev || _swipeController.isAnimating) return;
    _stopSongMetronome();
    _stopAutoScroll();
    _closeYoutubePlayer();
    _completeSwipe(1);
  }

  void _goNext() {
    if (!widget.canNext || _swipeController.isAnimating) return;
    _stopSongMetronome();
    _stopAutoScroll();
    _closeYoutubePlayer();
    _completeSwipe(-1);
  }

  /// Scroll ~one viewport up; at the top edge, fall through to previous song.
  void _pedalScrollPrev() {
    if (_swipeController.isAnimating) return;
    if (!_scrollController.hasClients) {
      _stopSongMetronome();
      _goPrev();
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels > pos.minScrollExtent + 4) {
      _stopAutoScroll();
      final page = pos.viewportDimension * 0.9;
      _scrollController.animateTo(
        math.max(pos.minScrollExtent, pos.pixels - page),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    _stopSongMetronome();
    _goPrev();
  }

  /// Scroll ~one viewport down; at the bottom edge, fall through to next song.
  void _pedalScrollNext() {
    if (_swipeController.isAnimating) return;
    if (!_scrollController.hasClients) {
      _stopSongMetronome();
      _goNext();
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 4) {
      _stopAutoScroll();
      final page = pos.viewportDimension * 0.9;
      _scrollController.animateTo(
        math.min(pos.maxScrollExtent, pos.pixels + page),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    _stopSongMetronome();
    _goNext();
  }

  void _completeSwipe(int dir) {
    _stopSongMetronome();
    // Stop YouTube as soon as navigation starts (buttons or swipe).
    _closeYoutubePlayer();
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
                  goingNext ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
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
    ref.listen<int>(shellBranchIndexProvider, (prev, next) {
      if (prev != next) {
        _stopSongMetronome();
      }
    });

    ref.listen<bool>(
      settingsControllerProvider.select((s) => s.syncAnnotations),
      (previous, next) {
        if (previous == next) return;
        _syncAnnotations = next;
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

    final document = ref.watch(songCurrentDocumentProvider);
    final variantId = ref.watch(
      songDisplaySettingsProvider.select((s) => s.variantId),
    );
    final metadata = document == null
        ? null
        : selectVersion(document, variantId).metadata;
    final videoId = metadata == null
        ? null
        : youtubeVideoIdFromMetadata(metadata);
    final tempo = int.tryParse(metadata?['tempo']?.trim() ?? '');
    final timeSignature = _parseTimeSignature(metadata?['time'] ?? '');
    const defaultTimeSignature = (4, 4);
    const showSongMetronome = true;
    if (!_metronomeInitialized || !_metronomeState.value.playing) {
      _metronomeInitialized = true;
      _metronomeTempo = tempo != null && tempo > 0 ? tempo : 100;
      final signature = timeSignature ?? defaultTimeSignature;
      _metronomeBeatsPerBar = signature.$1;
      _metronomeDenominator = signature.$2;
      _metronomeTime = '${signature.$1}/${signature.$2}';
      unawaited(_metronomePlayer.init());
    }
    final playerVideoId = _playerVideoId == videoId ? videoId : null;

    // Approximate height of the bottom overlay (floating buttons, nav pill,
    // mini player) so the last lines can scroll clear of it.
    final bottomInset =
        (widget.isAnnotating ? 140.0 : 40.0) +
        (!widget.isAnnotating && videoId != null ? 52 : 0) +
        (!widget.isAnnotating && showNav ? 60 : 0) +
        (playerVideoId != null ? 124 : 0);

    return PedalNavigator(
      onPrev: widget.canPrev ? _goPrev : null,
      onNext: widget.canNext ? _goNext : null,
      onScrollPrev: _pedalScrollPrev,
      onScrollNext: _pedalScrollNext,
      child: Stack(
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
                            bottomInset: bottomInset,
                            onYoutubeTap: videoId == null
                                ? null
                                : () =>
                                      setState(() => _playerVideoId = videoId),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.refreshCw,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.annotationRemoteChanges,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: _dismissPendingRemoteUpdate,
                              child: Text(l10n.annotationKeepMine),
                            ),
                            FilledButton(
                              onPressed: _acceptPendingRemoteUpdate,
                              child: Text(l10n.annotationReload),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom overlay: annotation toolbar or floating controls, stacked
          // above the YouTube mini player when it is open.
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isAnnotating) ...[
                    if (widget.onToggleAnnotation != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 12),
                          child: _buildAnnotationFab(theme: theme, l10n: l10n),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ] else
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildFloatingControls(
                          theme: theme,
                          l10n: l10n,
                          showNav: showNav,
                          videoId: videoId,
                          playerOpen: playerVideoId != null,
                          showSongMetronome: showSongMetronome,
                        ),
                      ),
                    ),
                  if (playerVideoId != null) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: YoutubeMiniPlayer(
                        key: ValueKey(playerVideoId),
                        videoId: playerVideoId,
                        fallbackTitle: metadata?['title'],
                        onClose: _closeYoutubePlayer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (int, int)? _parseTimeSignature(String raw) {
    final match = RegExp(r'^\s*(\d+)\s*/\s*(\d+)\s*$').firstMatch(raw);
    if (match == null) return null;
    final numerator = int.tryParse(match.group(1)!);
    final denominator = int.tryParse(match.group(2)!);
    if (numerator == null ||
        numerator < 1 ||
        numerator > 16 ||
        denominator == null ||
        ![2, 4, 8, 16].contains(denominator)) {
      return null;
    }
    return (numerator, denominator);
  }

  Widget _buildSongMetronomeFab(ThemeData theme) {
    return ValueListenableBuilder<_SongMetronomeState>(
      valueListenable: _metronomeState,
      builder: (context, state, _) {
        final isPlaying = state.playing;
        final isAccent = state.beat == 0;

        final Color backgroundColor;
        final Color foregroundColor;
        if (!isPlaying) {
          backgroundColor = theme.colorScheme.surfaceContainerHighest;
          foregroundColor = theme.colorScheme.onSurfaceVariant;
        } else if (isAccent) {
          backgroundColor = theme.colorScheme.primary;
          foregroundColor = theme.colorScheme.onPrimary;
        } else {
          backgroundColor = theme.colorScheme.onSurface;
          foregroundColor = theme.colorScheme.surface;
        }

        return AnimatedBuilder(
          animation: _metronomePulseController,
          builder: (context, _) {
            final progress = _metronomePulseController.value;
            final pulseAmount = isPlaying ? math.sin(progress * math.pi) : 0.0;
            final maxBoost = isAccent ? 0.22 : 0.12;
            final scale = 1.0 + (maxBoost * pulseAmount);

            return Transform.scale(
              scale: scale,
              child: _SongReaderFab(
                onPressed: _openSongMetronome,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                tooltip: 'Metronome',
                child: const Icon(LucideIcons.metronome),
              ),
            );
          },
        );
      },
    );
  }

  void _openSongMetronome() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: ValueListenableBuilder<_SongMetronomeState>(
            valueListenable: _metronomeState,
            builder: (context, state, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_metronomeTempo BPM · $_metronomeTime',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _metronomeBeatsPerBar,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: state.playing && state.beat == i ? 18 : 12,
                      height: state.playing && state.beat == i ? 18 : 12,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.playing && state.beat == i
                            ? (i == 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary)
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: state.playing ? null : _startSongMetronome,
                      icon: const Icon(LucideIcons.play),
                      label: const Text('Play'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: state.playing ? _stopSongMetronome : null,
                      icon: const Icon(LucideIcons.square),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startSongMetronome() {
    _metronomeState.value = const _SongMetronomeState(playing: true, beat: -1);
    _nextMetronomeBeat = DateTime.now();
    _scheduleSongMetronomeBeat();
  }

  void _scheduleSongMetronomeBeat() {
    _metronomeTimer?.cancel();
    if (_nextMetronomeBeat == null || !_metronomeState.value.playing) return;
    final delay = _nextMetronomeBeat!.difference(DateTime.now());
    _metronomeTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted || !_metronomeState.value.playing) return;
      final nextBeat = (_metronomeState.value.beat + 1) % _metronomeBeatsPerBar;
      _metronomeState.value = _SongMetronomeState(
        playing: true,
        beat: nextBeat,
      );
      _metronomePulseController.forward(from: 0);
      unawaited(_metronomePlayer.click(accent: nextBeat == 0));
      final interval = Duration(
        milliseconds: (60000 * 4 / (_metronomeTempo * _metronomeDenominator))
            .round(),
      );
      _nextMetronomeBeat = _nextMetronomeBeat!.add(interval);
      while (_nextMetronomeBeat!.isBefore(DateTime.now())) {
        _nextMetronomeBeat = _nextMetronomeBeat!.add(interval);
      }
      _scheduleSongMetronomeBeat();
    });
  }

  void _stopSongMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _nextMetronomeBeat = null;
    if (_metronomePulseController.isAnimating) {
      _metronomePulseController.reset();
    }
    unawaited(_metronomePlayer.stop());
    if (_metronomeState.value.playing) {
      _metronomeState.value = const _SongMetronomeState();
    }
  }

  /// Right-side controls: YouTube toggle, auto-scroll, annotation, metronome and prev/next.
  Widget _buildFloatingControls({
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool showNav,
    required String? videoId,
    required bool playerOpen,
    required bool showSongMetronome,
  }) {
    final autoScrollFab = _SongReaderFab(
      onPressed: _toggleAutoScroll,
      backgroundColor: _isScrolling
          ? theme.colorScheme.onSurface
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: _isScrolling
          ? theme.colorScheme.surface
          : theme.colorScheme.onSurfaceVariant,
      tooltip: _isScrolling
          ? l10n.songAutoScrollPause
          : l10n.songAutoScrollStart,
      child: Icon(
        _isScrolling ? LucideIcons.pause : LucideIcons.chevronsDown,
      ),
    );

    final bool hasAnnotation = widget.onToggleAnnotation != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (videoId != null && widget.showYoutube) ...[
          _SongReaderFab(
            onPressed: () {
              if (playerOpen) {
                _closeYoutubePlayer();
              } else {
                setState(() => _playerVideoId = videoId);
              }
            },
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: playerOpen
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            tooltip: playerOpen
                ? l10n.songYoutubeClosePlayer
                : l10n.songYoutubeOpenPlayer,
            child: const Icon(LucideIcons.play),
          ),
          const SizedBox(height: 12),
        ],
        if (hasAnnotation) ...[
          autoScrollFab,
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSongMetronome) ...[
                _buildSongMetronomeFab(theme),
                const SizedBox(width: 12),
              ],
              _buildAnnotationFab(theme: theme, l10n: l10n),
            ],
          ),
        ] else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSongMetronome) ...[
                _buildSongMetronomeFab(theme),
                const SizedBox(width: 12),
              ],
              autoScrollFab,
            ],
          ),
        ],
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
    );
  }

  Widget _buildAnnotationFab({
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return _SongReaderFab(
      onPressed: widget.onToggleAnnotation!,
      backgroundColor: widget.isAnnotating
          ? theme.colorScheme.onSurface
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: widget.isAnnotating
          ? theme.colorScheme.surface
          : theme.colorScheme.onSurfaceVariant,
      tooltip: l10n.annotationModeTitle,
      child: Icon(widget.isAnnotating ? LucideIcons.pencil : LucideIcons.pencil),
    );
  }
}

/// Circular, semi-transparent song-reader floating action button.
class _SongReaderFab extends StatelessWidget {
  const _SongReaderFab({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.tooltip,
    required this.child,
  });

  static const double _size = 52;
  static const double _opacity = 0.5;

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: FloatingActionButton(
        heroTag: null,
        elevation: 1,
        highlightElevation: 2,
        shape: const CircleBorder(),
        backgroundColor: backgroundColor.withValues(alpha: _opacity),
        foregroundColor: foregroundColor,
        tooltip: tooltip,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class _SongMetronomeState {
  const _SongMetronomeState({this.playing = false, this.beat = 0});

  final bool playing;
  final int beat;
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
                            icon: LucideIcons.pencil,
                            tooltip: l10n.annotationPen,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.erase,
                            icon: LucideIcons.highlighter,
                            tooltip: l10n.annotationEraser,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.erasePixel,
                            icon: LucideIcons.eraser,
                            tooltip: l10n.annotationPixelEraser,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.line,
                            icon: LucideIcons.minus,
                            tooltip: l10n.annotationLine,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.rectangle,
                            icon: LucideIcons.square,
                            tooltip: l10n.annotationRectangle,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.ellipse,
                            icon: LucideIcons.circle,
                            tooltip: l10n.annotationEllipse,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.text,
                            icon: LucideIcons.type,
                            tooltip: l10n.annotationText,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.select,
                            icon: LucideIcons.mousePointer,
                            tooltip: l10n.annotationSelect,
                          ),
                          const SizedBox(width: 2),
                          _buildToolButton(
                            context: context,
                            targetTool: CanvasTool.lasso,
                            icon: LucideIcons.spline,
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
                            icon: const Icon(LucideIcons.layers, size: 20),
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
                            icon: const Icon(LucideIcons.undo2, size: 20),
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
                            icon: const Icon(LucideIcons.redo2, size: 20),
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
                              LucideIcons.trash2,
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
                          icon: const Icon(LucideIcons.undo2, size: 20),
                          tooltip: l10n.annotationUndo,
                          onPressed: null,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(LucideIcons.redo2, size: 20),
                          tooltip: l10n.annotationRedo,
                          onPressed: null,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            LucideIcons.trash2,
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
              // Row 2: Swatches + stroke width (stacked on narrow widths).
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 360;
                  final swatches = Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final c in _kAnnotationPalette)
                        Tooltip(
                          message: l10n.annotationPen,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                onColorChanged(c);
                                if (tool == CanvasTool.erase ||
                                    tool == CanvasTool.erasePixel) {
                                  onToolChanged(CanvasTool.draw);
                                }
                              },
                              child: Ink(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: c.toARGB32() == color.toARGB32()
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                  .withValues(alpha: 0.4),
                                        width: c.toARGB32() == color.toARGB32()
                                            ? 2.5
                                            : 1,
                                      ),
                                    ),
                                    child: c.toARGB32() == color.toARGB32()
                                        ? Center(
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    c.computeLuminance() > 0.5
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
                            ),
                          ),
                        ),
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
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(LucideIcons.pipette, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  final strokeSlider = SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 18,
                      ),
                    ),
                    child: Slider(
                      value: strokeWidth,
                      min: 1.0,
                      max: 16.0,
                      label: strokeWidth.toStringAsFixed(0),
                      onChanged: onStrokeWidthChanged,
                    ),
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [swatches, strokeSlider],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: swatches),
                      const SizedBox(width: 8),
                      Expanded(child: strokeSlider),
                    ],
                  );
                },
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
            icon: const Icon(LucideIcons.chevronLeft),
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
            icon: const Icon(LucideIcons.chevronRight),
            tooltip: l10n.songNext,
          ),
        ],
      ),
    );
  }
}
