import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/shell_leading_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/metronome_click_player.dart';

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
  Timer? _beatTimer;
  DateTime? _nextBeatAt;
  final List<DateTime> _tapTimes = [];
  final MetronomeClickPlayer _clickPlayer = MetronomeClickPlayer();

  Duration get _beatDuration => Duration(milliseconds: (60000 / _bpm).round());

  @override
  void initState() {
    super.initState();
    _pendulumController = AnimationController(
      vsync: this,
      duration: _beatDuration,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    unawaited(_initAudio());
  }

  Future<void> _initAudio() async {
    await _clickPlayer.init();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopBeats();
    _holdTimer?.cancel();
    _pendulumController.dispose();
    _pulseController.dispose();
    unawaited(_clickPlayer.dispose());
    super.dispose();
  }

  void _stopBeats() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _nextBeatAt = null;
    _pendulumController.stop();
    _pendulumController.value = 0;
  }

  /// Drift-corrected beat scheduler.
  ///
  /// Important: do NOT drive beats from [AnimationController.repeat] status.
  /// With `reverse: true`, status only toggles forward/reverse and never
  /// reaches completed/dismissed — which previously caused a single click.
  void _armNextBeat() {
    _beatTimer?.cancel();
    if (!_isPlaying || _nextBeatAt == null) return;

    final delay = _nextBeatAt!.difference(DateTime.now());
    _beatTimer = Timer(delay.isNegative ? Duration.zero : delay, _fireBeat);
  }

  void _fireBeat() {
    if (!_isPlaying || !mounted) return;

    setState(() => _currentBeat = (_currentBeat + 1) % _beatsPerBar);
    final isAccent = _currentBeat == 0 && _accentFirstBeat;

    if (isAccent) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    if (_clickPlayer.isReady) {
      unawaited(_clickPlayer.click(accent: isAccent));
    }

    _pulseController.forward(from: 0);

    final interval = _beatDuration;
    _nextBeatAt = (_nextBeatAt ?? DateTime.now()).add(interval);
    // If we fell more than one beat behind (e.g. app suspended), catch up.
    final now = DateTime.now();
    while (_nextBeatAt!.isBefore(now)) {
      _nextBeatAt = _nextBeatAt!.add(interval);
    }
    _armNextBeat();
  }

  void _togglePlay() {
    final starting = !_isPlaying;
    if (starting) {
      setState(() {
        _isPlaying = true;
        _currentBeat = _beatsPerBar - 1; // next fire lands on beat 0
      });
      _pendulumController.duration = _beatDuration;
      _pendulumController.repeat(reverse: true);
      _nextBeatAt = DateTime.now();
      _fireBeat();
    } else {
      setState(() => _isPlaying = false);
      _stopBeats();
    }
  }

  void _setBpm(int value) {
    final clamped = value.clamp(_minBpm, _maxBpm);
    if (clamped == _bpm) return;
    setState(() => _bpm = clamped);
    _pendulumController.duration = _beatDuration;
    if (_isPlaying) {
      // Re-anchor from "now" so tempo changes feel immediate.
      _nextBeatAt = DateTime.now().add(_beatDuration);
      _armNextBeat();
      if (!_pendulumController.isAnimating) {
        _pendulumController.repeat(reverse: true);
      }
    }
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
            final compact = constraints.maxHeight < 680;
            return Stack(
              children: [
                _buildAura(colors),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, compact ? 8 : 16, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 16 : 36),
                    ),
                    child: Column(
                      children: [
                        _buildBeatStrip(theme, colors),
                        if (_clickPlayer.failed) ...[
                          const SizedBox(height: 10),
                          Text(
                            l10n.metronomeAudioUnavailable,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: compact ? 12 : 20),
                        _buildPendulum(colors, compact: compact),
                        SizedBox(height: compact ? 8 : 16),
                        _buildBpmDisplay(theme, colors),
                        SizedBox(height: compact ? 8 : 14),
                        _buildBpmStepper(colors),
                        SizedBox(height: compact ? 16 : 24),
                        _buildTimeSignatureCard(theme, colors, l10n),
                        SizedBox(height: compact ? 20 : 28),
                        _buildTransport(colors, l10n),
                      ],
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
      animation: Listenable.merge([_pulseController, _pendulumController]),
      builder: (context, _) {
        final v = _isPlaying ? (1 - _pulseController.value) * 0.22 : 0.04;
        return IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.55),
            child: Container(
              width: 320,
              height: 320,
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

  Widget _buildBeatStrip(ThemeData theme, ColorScheme colors) {
    return Semantics(
      liveRegion: true,
      label: _isPlaying
          ? 'Beat ${_currentBeat + 1} of $_beatsPerBar'
          : 'Metronome stopped',
      child: Column(
        children: [
          Text(
            _isPlaying ? '${_currentBeat + 1} / $_beatsPerBar' : '— / $_beatsPerBar',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_beatsPerBar, (i) {
              final active = _isPlaying && i == _currentBeat;
              final isFirst = i == 0;
              final accent = isFirst && _accentFirstBeat;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  height: active ? 14 : 8,
                  margin: EdgeInsets.symmetric(
                    horizontal: _beatsPerBar > 7 ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: active
                        ? (accent ? colors.primary : colors.secondary)
                        : colors.outlineVariant.withValues(alpha: 0.55),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: (accent ? colors.primary : colors.secondary)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPendulum(ColorScheme colors, {required bool compact}) {
    const maxAngle = 24 * math.pi / 180;
    final weightFraction = (1 - (_bpm - _minBpm) / (_maxBpm - _minBpm)).clamp(
      0.14,
      0.8,
    );
    final height = compact ? 148.0 : 200.0;
    final armHeight = compact ? 108.0 : 152.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: SizedBox(
          height: height,
          width: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                size: Size(168, height - 16),
                painter: _MetronomeBodyPainter(
                  fill: colors.surfaceContainerHighest,
                  outline: colors.outline.withValues(alpha: 0.28),
                  accent: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              AnimatedBuilder(
                animation: _pendulumController,
                builder: (context, _) {
                  final angle = _isPlaying
                      ? (-maxAngle + _pendulumController.value * 2 * maxAngle)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                bottom: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    ? 1 + (0.05 * (1 - _pulseController.value))
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$_bpm',
                  key: ValueKey(_bpm),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    height: 0.95,
                    letterSpacing: -1.5,
                    fontSize: 72,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'BPM  ·  ${_tempoMarking(_bpm)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
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
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          tooltip: 'Decrease tempo',
          colors: colors,
          onTapDown: () => _startHold(-1),
          onTapUp: _endHold,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _bpm.toDouble(),
              min: _minBpm.toDouble(),
              max: _maxBpm.toDouble(),
              activeColor: colors.primary,
              inactiveColor: colors.outline.withValues(alpha: 0.22),
              label: '$_bpm',
              onChanged: (v) => _setBpm(v.round()),
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          tooltip: 'Increase tempo',
          colors: colors,
          onTapDown: () => _startHold(1),
          onTapUp: _endHold,
        ),
      ],
    );
  }

  Widget _buildTimeSignatureCard(
    ThemeData theme,
    ColorScheme colors,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.metronomeTimeSignature,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
              const SizedBox(width: 4),
              Switch.adaptive(
                value: _accentFirstBeat,
                onChanged: (v) => setState(() => _accentFirstBeat = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSignatures.map((n) {
              final selected = n == _beatsPerBar;
              return ChoiceChip(
                label: Text('$n/4'),
                selected: selected,
                showCheckmark: false,
                selectedColor: colors.primary,
                backgroundColor: colors.surface,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: selected
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.28),
                ),
                onSelected: (_) => setState(() {
                  _beatsPerBar = n;
                  if (!_isPlaying) _currentBeat = 0;
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransport(ColorScheme colors, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleTapTempo,
            icon: const Icon(Icons.touch_app_rounded, size: 18),
            label: Text(l10n.metronomeTapTempo),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outline.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          label: _isPlaying ? l10n.metronomePause : l10n.metronomePlay,
          child: Material(
            color: colors.primary,
            shape: const CircleBorder(),
            elevation: _isPlaying ? 8 : 3,
            shadowColor: colors.primary.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePlay,
              child: SizedBox(
                width: 84,
                height: 84,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(_isPlaying),
                    color: colors.onPrimary,
                    size: 38,
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
              child: Icon(icon, size: 22, color: colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetronomeBodyPainter extends CustomPainter {
  _MetronomeBodyPainter({
    required this.fill,
    required this.outline,
    required this.accent,
  });

  final Color fill;
  final Color outline;
  final Color accent;

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
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, fill],
        ).createShader(Offset.zero & size),
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
      oldDelegate.fill != fill ||
      oldDelegate.outline != outline ||
      oldDelegate.accent != accent;
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
      10,
      Paint()..color = weightColor,
    );
    canvas.drawCircle(
      Offset(size.width / 2, weightY),
      10,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
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
