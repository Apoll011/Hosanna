import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/click_synth.dart';

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

  late final AudioPlayer _accentPlayer;
  late final AudioPlayer _normalPlayer;
  bool _audioReady = false;

  @override
  void initState() {
    super.initState();
    _pendulumController = AnimationController(
      vsync: this,
      duration: _beatDuration,
    )..addStatusListener(_handlePendulumStatus);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _initAudio();
  }

  Future<void> _initAudio() async {
    _accentPlayer = AudioPlayer(playerId: 'metronome_accent');
    _normalPlayer = AudioPlayer(playerId: 'metronome_normal');

    // Low-latency mode is essential here — the default mode buffers/streams
    // and adds noticeable delay, which would drift the click out of sync
    // with the pendulum.
    await Future.wait([
      _accentPlayer.setPlayerMode(PlayerMode.lowLatency),
      _normalPlayer.setPlayerMode(PlayerMode.lowLatency),
    ]);
    await Future.wait([
      _accentPlayer.setSource(
        BytesSource(ClickSynth.generate(frequency: 1500)),
      ),
      _normalPlayer.setSource(BytesSource(ClickSynth.generate(frequency: 900))),
    ]);
    await Future.wait([
      _accentPlayer.setVolume(1.0),
      _normalPlayer.setVolume(0.85),
    ]);

    if (mounted) setState(() => _audioReady = true);
  }

  @override
  void dispose() {
    _pendulumController.dispose();
    _pulseController.dispose();
    _holdTimer?.cancel();
    _accentPlayer.dispose();
    _normalPlayer.dispose();
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
      final player = isAccent ? _accentPlayer : _normalPlayer;
      player.seek(Duration.zero).then((_) => player.resume());
    }

    _pulseController.forward(from: 0);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _currentBeat = _beatsPerBar - 1; // next tick lands on beat 0
        _pendulumController.duration = _beatDuration;
        _pendulumController.repeat(reverse: true);
      } else {
        _pendulumController.stop();
      }
    });
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(l10n.metronomeTitle), centerTitle: true),
      body: SafeArea(
        child: Stack(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildBeatDots(colors),
                    const Spacer(),
                    _buildPendulum(colors),
                    const SizedBox(height: 28),
                    _buildBpmDisplay(colors),
                    const SizedBox(height: 20),
                    _buildBpmStepper(colors),
                    const SizedBox(height: 28),
                    _buildTimeSignatureRow(colors, l10n),
                    const Spacer(),
                    _buildTransportRow(colors, l10n),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
    return Row(
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
    );
  }

  Widget _buildPendulum(ColorScheme colors) {
    const maxAngle = 26 * math.pi / 180;
    final weightFraction = (1 - (_bpm - _minBpm) / (_maxBpm - _minBpm)).clamp(
      0.12,
      0.82,
    );

    return SizedBox(
      height: 220,
      width: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Static body
          CustomPaint(
            size: const Size(180, 200),
            painter: _MetronomeBodyPainter(
              fill: colors.surfaceContainerHighest,
              outline: colors.outline.withValues(alpha: 0.3),
            ),
          ),
          // Swinging arm
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
                    size: const Size(14, 168),
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

  Widget _buildBpmDisplay(ColorScheme colors) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy.abs() < 1) return;
        _setBpm(_bpm - (details.delta.dy / 6).round());
      },
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
                style: TextStyle(
                  fontSize: 64,
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmStepper(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          icon: Icons.remove,
          colors: colors,
          onTapDown: () => _startHold(-1),
          onTapUp: _endHold,
        ),
        SizedBox(
          width: 180,
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
              onChanged: (v) => _setBpm(v.round()),
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          colors: colors,
          onTapDown: () => _startHold(1),
          onTapUp: _endHold,
        ),
      ],
    );
  }

  Widget _buildTimeSignatureRow(ColorScheme colors, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.metronomeTimeSignature,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.secondary,
              ),
            ),
            const Spacer(),
            Text(
              l10n.metronomeAccent,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            Switch(
              value: _accentFirstBeat,
              onChanged: (v) => setState(() => _accentFirstBeat = v),
              activeColor: colors.primary,
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
              labelStyle: TextStyle(
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
        GestureDetector(
          onTap: _togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: _isPlaying ? 2 : 0,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(_isPlaying),
                color: colors.onPrimary,
                size: 34,
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
    required this.colors,
    required this.onTapDown,
    required this.onTapUp,
  });

  final IconData icon;
  final ColorScheme colors;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outline.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 18, color: colors.onSurface),
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
