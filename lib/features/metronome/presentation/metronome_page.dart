import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/shell_leading_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/click_source.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with TickerProviderStateMixin {
  static const int _minBpm = 30;
  static const int _maxBpm = 240;
  static const List<int> _timeSignatures = [2, 3, 4, 5, 6, 7, 9, 12];

  int _bpm = 100;
  int _beatsPerBar = 4;
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _accentFirstBeat = true;

  late final AnimationController _pendulumController;
  late final AnimationController _pulseController;
  Timer? _holdTimer;
  final List<DateTime> _tapTimes = [];

  Duration get _beatDuration => Duration(milliseconds: (60000 / _bpm).round());

  AudioPlayer? _accentPlayer;
  AudioPlayer? _normalPlayer;
  Source? _accentSource;
  Source? _normalSource;
  bool _audioReady = false;
  bool _audioInitFailed = false;

  /// Android SoundPool needs stop()+resume(); other backends need a fresh
  /// [AudioPlayer.play] because [AudioPlayer.resume] is a no-op until the
  /// player has been started at least once (which was the silent-metronome bug).
  static final bool _usesAndroidSoundPool =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _pendulumController = AnimationController(
      vsync: this,
      duration: _beatDuration,
    )..addStatusListener(_handlePendulumStatus);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    unawaited(_initAudio());
  }

  Future<void> _initAudio() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );

      final accentPlayer = AudioPlayer();
      final normalPlayer = AudioPlayer();
      final accentSource = await createClickSource(frequency: 1500);
      final normalSource = await createClickSource(frequency: 1000);

      // Prefer low-latency; fall back silently if the platform rejects it.
      try {
        await Future.wait([
          accentPlayer.setPlayerMode(PlayerMode.lowLatency),
          normalPlayer.setPlayerMode(PlayerMode.lowLatency),
        ]);
      } catch (error) {
        debugPrint('Metronome lowLatency unavailable, using mediaPlayer: $error');
      }

      await Future.wait([
        accentPlayer.setReleaseMode(ReleaseMode.stop),
        normalPlayer.setReleaseMode(ReleaseMode.stop),
        accentPlayer.setVolume(1.0),
        normalPlayer.setVolume(0.8),
      ]);

      if (_usesAndroidSoundPool) {
        // Preload into SoundPool so the first resume() is instant.
        await Future.wait([
          accentPlayer.setSource(accentSource),
          normalPlayer.setSource(normalSource),
        ]);
      }

      if (!mounted) {
        await accentPlayer.dispose();
        await normalPlayer.dispose();
        return;
      }

      _accentPlayer = accentPlayer;
      _normalPlayer = normalPlayer;
      _accentSource = accentSource;
      _normalSource = normalSource;
      setState(() {
        _audioReady = true;
        _audioInitFailed = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Metronome audio init failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _audioReady = false;
          _audioInitFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pendulumController.dispose();
    _pulseController.dispose();
    _holdTimer?.cancel();
    unawaited(_accentPlayer?.dispose() ?? Future<void>.value());
    unawaited(_normalPlayer?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  void _handlePendulumStatus(AnimationStatus status) {
    if (!_isPlaying) return;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _onBeat();
    }
  }

  void _onBeat() {
    setState(() => _currentBeat = (_currentBeat + 1) % _beatsPerBar);
    final isAccent = _currentBeat == 0 && _accentFirstBeat;

    isAccent ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();

    if (_audioReady) {
      unawaited(_triggerClick(accent: isAccent));
    }

    _pulseController.forward(from: 0);
  }

  Future<void> _triggerClick({required bool accent}) async {
    final player = accent ? _accentPlayer : _normalPlayer;
    final source = accent ? _accentSource : _normalSource;
    if (player == null || source == null) return;

    try {
      if (_usesAndroidSoundPool) {
        // SoundPool: stop resets the stream id; resume fires soundPool.play().
        await player.stop();
        await player.resume();
      } else {
        // MediaPlayer-style backends: resume() is a no-op until play() has
        // run once, so always play the source from the start.
        await player.stop();
        await player.play(source);
      }
    } catch (error) {
      debugPrint('Metronome click trigger failed: $error');
      // One-shot recovery: rebuild sources and retry once.
      try {
        final rebuilt = await createClickSource(
          frequency: accent ? 1500 : 1000,
        );
        if (accent) {
          _accentSource = rebuilt;
        } else {
          _normalSource = rebuilt;
        }
        await player.stop();
        await player.play(rebuilt);
      } catch (retryError) {
        debugPrint('Metronome click retry failed: $retryError');
      }
    }
  }

  void _togglePlay() {
    final starting = !_isPlaying;
    setState(() {
      _isPlaying = starting;
      if (starting) {
        _currentBeat = _beatsPerBar - 1; // next tick lands on beat 0
        _pendulumController.duration = _beatDuration;
        _pendulumController.value = 0;
        _pendulumController.repeat(reverse: true);
      } else {
        _pendulumController.stop();
        _pendulumController.value = 0;
      }
    });
    // Fire the downbeat immediately so the first click isn't one full swing late.
    if (starting) _onBeat();
  }

  void _setBpm(int value) {
    final clamped = value.clamp(_minBpm, _maxBpm);
    if (clamped == _bpm) return;
    setState(() => _bpm = clamped);
    _pendulumController.duration = _beatDuration;
  }

  void _startHold(int direction) {
    _setBpm(_bpm + direction);
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _setBpm(_bpm + direction);
    });
  }

  void _endHold() => _holdTimer?.cancel();

  void _handleTapTempo() {
    final now = DateTime.now();
    if (_tapTimes.isNotEmpty &&
        now.difference(_tapTimes.last) > const Duration(seconds: 2)) {
      _tapTimes.clear();
    }
    _tapTimes.add(now);
    if (_tapTimes.length > 5) _tapTimes.removeAt(0);
    if (_tapTimes.length >= 2) {
      final gaps = <int>[
        for (var i = 1; i < _tapTimes.length; i++)
          _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds,
      ];
      final avg = gaps.reduce((a, b) => a + b) / gaps.length;
      _setBpm((60000 / avg).round());
    }
    HapticFeedback.lightImpact();
  }

  String _tempoMarking(int bpm) {
    if (bpm < 40) return 'Grave';
    if (bpm < 60) return 'Largo';
    if (bpm < 66) return 'Lento';
    if (bpm < 76) return 'Adagio';
    if (bpm < 108) return 'Andante';
    if (bpm < 120) return 'Moderato';
    if (bpm < 168) return 'Allegro';
    if (bpm < 200) return 'Presto';
    return 'Prestissimo';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(l10n.metronomeTitle),
        centerTitle: true,
        leading: const ShellLeadingButton(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 640;
            return Stack(
              children: [
                _buildAura(colors),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 16),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: compact ? 8 : 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (compact ? 16 : 32),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              _buildBeatDots(colors),
                              if (_audioInitFailed) ...[
                                const SizedBox(height: 12),
                                Text(
                                  l10n.metronomeAudioUnavailable,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                          _buildPendulum(colors, compact: compact),
                          Column(
                            children: [
                              _buildBpmDisplay(theme, colors),
                              SizedBox(height: compact ? 12 : 20),
                              _buildBpmStepper(colors),
                              SizedBox(height: compact ? 16 : 28),
                              _buildTimeSignatureRow(theme, colors, l10n),
                              SizedBox(height: compact ? 16 : 24),
                              _buildTransportRow(colors, l10n),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAura(ColorScheme colors) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final v = _isPlaying ? (1 - _pulseController.value) * 0.18 : 0.0;
        return IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: v),
                    colors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeatDots(ColorScheme colors) {
    return Semantics(
      liveRegion: true,
      label: _isPlaying
          ? 'Beat ${_currentBeat + 1} of $_beatsPerBar'
          : 'Metronome stopped',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_beatsPerBar, (i) {
          final active = _isPlaying && i == _currentBeat;
          final isFirst = i == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 20 : 9,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: active
                  ? (isFirst && _accentFirstBeat
                        ? colors.primary
                        : colors.secondary)
                  : colors.outline.withValues(alpha: 0.25),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPendulum(ColorScheme colors, {required bool compact}) {
    const maxAngle = 26 * math.pi / 180;
    final weightFraction = (1 - (_bpm - _minBpm) / (_maxBpm - _minBpm)).clamp(
      0.12,
      0.82,
    );
    final height = compact ? 160.0 : 220.0;
    final armHeight = compact ? 120.0 : 168.0;

    return SizedBox(
      height: height,
      width: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(180, height - 20),
            painter: _MetronomeBodyPainter(
              fill: colors.surfaceContainerHighest,
              outline: colors.outline.withValues(alpha: 0.3),
            ),
          ),
          AnimatedBuilder(
            animation: _pendulumController,
            builder: (context, _) {
              final angle = _isPlaying
                  ? (-maxAngle + _pendulumController.value * 2 * maxAngle)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.bottomCenter,
                  child: CustomPaint(
                    size: Size(14, armHeight),
                    painter: _MetronomeArmPainter(
                      armColor: colors.onSurfaceVariant,
                      weightColor: colors.primary,
                      weightFraction: weightFraction,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmDisplay(ThemeData theme, ColorScheme colors) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy.abs() < 1) return;
        _setBpm(_bpm - (details.delta.dy / 6).round());
      },
      child: Semantics(
        label: '$_bpm BPM, ${_tempoMarking(_bpm)}',
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isPlaying
                    ? 1 + (0.06 * (1 - _pulseController.value))
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$_bpm',
                  key: ValueKey(_bpm),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'BPM · ${_tempoMarking(_bpm)}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBpmStepper(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          icon: Icons.remove,
          tooltip: 'Decrease tempo',
          colors: colors,
          onTapDown: () => _startHold(-1),
          onTapUp: _endHold,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _bpm.toDouble(),
              min: _minBpm.toDouble(),
              max: _maxBpm.toDouble(),
              activeColor: colors.primary,
              inactiveColor: colors.outline.withValues(alpha: 0.25),
              label: '$_bpm',
              onChanged: (v) => _setBpm(v.round()),
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          tooltip: 'Increase tempo',
          colors: colors,
          onTapDown: () => _startHold(1),
          onTapUp: _endHold,
        ),
      ],
    );
  }

  Widget _buildTimeSignatureRow(
    ThemeData theme,
    ColorScheme colors,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.metronomeTimeSignature,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.secondary,
              ),
            ),
            const Spacer(),
            Text(
              l10n.metronomeAccent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Switch(
              value: _accentFirstBeat,
              onChanged: (v) => setState(() => _accentFirstBeat = v),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _timeSignatures.map((n) {
            final selected = n == _beatsPerBar;
            return ChoiceChip(
              label: Text('$n/4'),
              selected: selected,
              showCheckmark: false,
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              side: BorderSide(color: colors.outline.withValues(alpha: 0.25)),
              onSelected: (_) => setState(() {
                _beatsPerBar = n;
                _currentBeat = 0;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransportRow(ColorScheme colors, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: _handleTapTempo,
          icon: const Icon(Icons.touch_app_rounded, size: 18),
          label: Text(l10n.metronomeTapTempo),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outline.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: _isPlaying ? l10n.metronomePause : l10n.metronomePlay,
          child: Material(
            color: colors.primary,
            shape: const CircleBorder(),
            elevation: _isPlaying ? 6 : 2,
            shadowColor: colors.primary.withValues(alpha: 0.45),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePlay,
              child: SizedBox(
                width: 76,
                height: 76,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(_isPlaying),
                    color: colors.onPrimary,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onTapDown,
    required this.onTapUp,
  });

  final IconData icon;
  final String tooltip;
  final ColorScheme colors;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: colors.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTapDown: (_) => onTapDown(),
            onTapUp: (_) => onTapUp(),
            onTapCancel: onTapUp,
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, size: 20, color: colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetronomeBodyPainter extends CustomPainter {
  _MetronomeBodyPainter({required this.fill, required this.outline});

  final Color fill;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.88, size.height)
      ..lineTo(size.width * 0.12, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MetronomeBodyPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.outline != outline;
}

class _MetronomeArmPainter extends CustomPainter {
  _MetronomeArmPainter({
    required this.armColor,
    required this.weightColor,
    required this.weightFraction,
  });

  final Color armColor;
  final Color weightColor;
  final double weightFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final armRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 2, 0, 4, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(armRect, Paint()..color = armColor);

    final weightY = size.height * (1 - weightFraction);
    canvas.drawCircle(
      Offset(size.width / 2, weightY),
      9,
      Paint()..color = weightColor,
    );
    canvas.drawCircle(
      Offset(size.width / 2, weightY),
      9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MetronomeArmPainter oldDelegate) =>
      oldDelegate.weightFraction != weightFraction ||
      oldDelegate.armColor != armColor ||
      oldDelegate.weightColor != weightColor;
}
