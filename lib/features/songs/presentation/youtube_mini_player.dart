import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Origin the embed page is served from. YouTube refuses to play embeds that
/// carry no referrer, so the HTML must be loaded with a real https base URL.
const String _kEmbedOrigin = 'https://www.youtube-nocookie.com';

/// YouTube embeds must have a viewport of at least 200×200 to play; the
/// WebView is laid out at this size and clipped behind the cover art.
const double _kEmbedViewport = 200;

const double _kCoverSize = 52;

// IFrame player API states.
const int _kStateEnded = 0;
const int _kStatePlaying = 1;
const int _kStateBuffering = 3;

/// Spotify-style mini player for a song's `{youtube: …}` link.
///
/// Playback runs in a WebView hosting the YouTube IFrame player, hidden behind
/// the video thumbnail; the transport controls drive it through JavaScript.
class YoutubeMiniPlayer extends StatefulWidget {
  const YoutubeMiniPlayer({
    super.key,
    required this.videoId,
    this.fallbackTitle,
    this.onClose,
  });

  final String videoId;

  /// Shown until the video's own title is known.
  final String? fallbackTitle;

  final VoidCallback? onClose;

  @override
  YoutubeMiniPlayerState createState() => YoutubeMiniPlayerState();
}

class YoutubeMiniPlayerState extends State<YoutubeMiniPlayer> {
  late final WebViewController _controller;

  bool _ready = false;
  int _state = -1;
  bool _hasError = false;
  double _position = 0;
  double _duration = 0;
  String? _videoTitle;

  /// Non-null while the user is dragging the progress thumb.
  double? _dragValue;

  bool get _isPlaying => _state == _kStatePlaying || _state == _kStateBuffering;

  @override
  void initState() {
    super.initState();
    _controller = _createController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('HosannaYoutube', onMessageReceived: _onMessage)
      ..loadHtmlString(_buildHtml(widget.videoId), baseUrl: _kEmbedOrigin);
  }

  WebViewController _createController() {
    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final controller = WebViewController.fromPlatformCreationParams(params);
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(message.message);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final data = decoded;

    setState(() {
      switch (data['event']) {
        case 'ready':
          _ready = true;
        case 'state':
          _state = (data['state'] as num?)?.toInt() ?? _state;
          if (_state == _kStatePlaying) _hasError = false;
        case 'progress':
          _position = (data['position'] as num?)?.toDouble() ?? _position;
          _duration = (data['duration'] as num?)?.toDouble() ?? _duration;
          final title = data['title'] as String?;
          if (title != null && title.isNotEmpty) _videoTitle = title;
        case 'error':
          _hasError = true;
      }
    });
  }

  Future<void> _call(String js) async {
    try {
      await _controller.runJavaScript(
        'if (window.player && player.getPlayerState) { $js }',
      );
    } catch (_) {
      // Page not ready yet; the next user action retries.
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      setState(() => _state = 2);
      _call('player.pauseVideo();');
    } else {
      if (_state == _kStateEnded) _seekTo(0);
      setState(() => _state = _kStateBuffering);
      _call('player.playVideo();');
    }
  }

  void _seekTo(double seconds) {
    final max = _duration > 0 ? _duration : seconds;
    final target = seconds.clamp(0.0, max).toDouble();
    setState(() => _position = target);
    _call('player.seekTo($target, true);');
  }

  void _skip(double delta) => _seekTo(_position + delta);

  static const String _kStopJs = '''
    if (window.player) {
      try { player.mute(); } catch (e) {}
      try { player.pauseVideo(); } catch (e) {}
      try { player.stopVideo(); } catch (e) {}
      try { player.destroy(); } catch (e) {}
      player = null;
    }
  ''';

  /// Stops the IFrame player so audio does not keep playing after this
  /// widget leaves the tree (back navigation, song change, close).
  Future<void> stopPlayback() async {
    try {
      await _controller.runJavaScript(_kStopJs);
    } catch (_) {
      // Controller may already be tearing down.
    }
    try {
      await _controller.loadHtmlString(
        '<html><body></body></html>',
        baseUrl: _kEmbedOrigin,
      );
    } catch (_) {
      // Best-effort; native view may already be gone.
    }
  }

  /// Kick off a synchronous stop while the platform WebView is still attached.
  ///
  /// [dispose] cannot await, and by then the native view may already be gone
  /// — so we must stop here (children deactivate before parents on route pop).
  void _stopPlaybackSync() {
    try {
      _controller.runJavaScript(_kStopJs);
    } catch (_) {}
    try {
      _controller.loadHtmlString(
        '<html><body></body></html>',
        baseUrl: _kEmbedOrigin,
      );
    } catch (_) {}
  }

  @override
  void deactivate() {
    _stopPlaybackSync();
    super.deactivate();
  }

  @override
  void dispose() {
    // Belt-and-suspenders if deactivate was skipped (e.g. hot reload).
    _stopPlaybackSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;

    final title = _videoTitle ?? widget.fallbackTitle ?? 'YouTube';
    final subtitle = _hasError ? l10n.songYoutubeError : 'YouTube';
    final maxValue = math.max(_duration, 1.0);
    final sliderValue = (_dragValue ?? _position).clamp(0.0, maxValue);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
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
              Row(
                children: [
                  _buildCover(scheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _hasError
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _ready ? () => _skip(-10) : null,
                    icon: const Icon(Icons.replay_10_rounded),
                    tooltip: l10n.songYoutubeRewind,
                  ),
                  _buildPlayButton(scheme, l10n),
                  IconButton(
                    onPressed: _ready ? () => _skip(30) : null,
                    icon: const Icon(Icons.forward_30_rounded),
                    tooltip: l10n.songYoutubeForward,
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: l10n.songYoutubeClosePlayer,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _buildProgress(theme, sliderValue, maxValue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: _kCoverSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OverflowBox(
              minWidth: _kEmbedViewport,
              maxWidth: _kEmbedViewport,
              minHeight: _kEmbedViewport,
              maxHeight: _kEmbedViewport,
              child: IgnorePointer(
                child: WebViewWidget(controller: _controller),
              ),
            ),
            CachedNetworkImage(
              imageUrl:
                  'https://i.ytimg.com/vi/${widget.videoId}/hqdefault.jpg',
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  ColoredBox(color: scheme.surfaceContainerHigh),
              errorWidget: (_, _, _) => ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(
                  Icons.music_note_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(ColorScheme scheme, AppLocalizations l10n) {
    final loading = !_ready || _state == _kStateBuffering;
    return Tooltip(
      message: _isPlaying ? l10n.songYoutubePause : l10n.songYoutubePlay,
      child: Material(
        color: scheme.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _ready ? _togglePlay : null,
          child: SizedBox.square(
            dimension: 44,
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: scheme.onPrimary,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme, double value, double maxValue) {
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            _formatTime(value),
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.15),
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.12),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: _dragValue != null ? 7 : 5,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              max: maxValue,
              onChangeStart: _duration > 0
                  ? (v) => setState(() => _dragValue = v)
                  : null,
              onChanged: _duration > 0
                  ? (v) => setState(() => _dragValue = v)
                  : null,
              onChangeEnd: _duration > 0
                  ? (v) {
                      setState(() => _dragValue = null);
                      _seekTo(v);
                    }
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            _formatTime(_duration),
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

String _formatTime(double seconds) {
  final total = seconds.isFinite ? seconds.floor() : 0;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
  return '$m:$s';
}

String _buildHtml(String videoId) =>
    '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
  #player { width: 100%; height: 100%; }
</style>
</head>
<body>
<div id="player"></div>
<script>
  var player;
  function send(o) { HosannaYoutube.postMessage(JSON.stringify(o)); }
  function tick() {
    if (!player || !player.getCurrentTime) return;
    var data = player.getVideoData ? player.getVideoData() : null;
    send({
      event: 'progress',
      position: player.getCurrentTime() || 0,
      duration: player.getDuration() || 0,
      title: (data && data.title) || ''
    });
  }
  function onYouTubeIframeAPIReady() {
    player = new YT.Player('player', {
      host: '$_kEmbedOrigin',
      videoId: '$videoId',
      playerVars: {
        autoplay: 1,
        playsinline: 1,
        controls: 0,
        disablekb: 1,
        rel: 0,
        origin: '$_kEmbedOrigin'
      },
      events: {
        onReady: function (e) {
          send({ event: 'ready' });
          e.target.playVideo();
          tick();
          setInterval(tick, 500);
        },
        onStateChange: function (e) {
          send({ event: 'state', state: e.data });
          tick();
        },
        onError: function (e) { send({ event: 'error', code: e.data }); }
      }
    });
  }
</script>
<script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';
