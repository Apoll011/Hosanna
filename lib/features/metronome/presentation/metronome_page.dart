import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/nav_branches.dart';
import '../../../app/providers.dart';
import '../../../app/shell_leading_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/metronome_click_player.dart';

class MetronomePage extends ConsumerStatefulWidget {
  const MetronomePage({super.key});

  @override
  ConsumerState<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends ConsumerState<MetronomePage>
    with SingleTickerProviderStateMixin {
  static const int _minBpm = 30;
  static const int _maxBpm = 240;
  static const List<int> _timeSignatures = [2, 3, 4, 5, 6, 7, 9, 12];

  int _bpm = 100;
  int _beatsPerBar = 4;
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _accentFirstBeat = true;

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
    _pulseController.dispose();
    unawaited(_clickPlayer.dispose());
    super.dispose();
  }

  void _stopBeats() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _nextBeatAt = null;
  }

  /// Drift-corrected beat scheduler.
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
    if (_isPlaying) {
      _nextBeatAt = DateTime.now().add(_beatDuration);
      _armNextBeat();
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
    // IndexedStack keeps this page alive — pause when the user leaves the tab.
    ref.listen<int>(shellBranchIndexProvider, (prev, next) {
      if (next != kMetronomeBranch && _isPlaying) {
        setState(() => _isPlaying = false);
        _stopBeats();
      }
    });

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.metronomeTitle),
        centerTitle: true,
        leading: const ShellLeadingButton(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _buildAura(colors),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBeatStrip(theme, colors),
                            if (_clickPlayer.failed) ...[
                              const SizedBox(height: 12),
                              Text(
                                l10n.metronomeAudioUnavailable,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 36),
                            _buildBpmDisplay(theme, colors),
                            const SizedBox(height: 28),
                            _buildBpmSlider(colors),
                            const SizedBox(height: 28),
                            _buildTimeSignature(theme, colors, l10n),
                            const SizedBox(height: 36),
                            _buildTransport(colors, l10n),
                          ],
                        ),
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
        final v = _isPlaying ? (1 - _pulseController.value) * 0.18 : 0.03;
        return IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.15),
            child: Container(
              width: 280,
              height: 280,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_beatsPerBar, (i) {
          final active = _isPlaying && i == _currentBeat;
          final accent = i == 0 && _accentFirstBeat;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            width: active ? 14 : 10,
            height: active ? 14 : 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? (accent ? colors.primary : colors.secondary)
                  : colors.outlineVariant.withValues(alpha: 0.55),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (accent ? colors.primary : colors.secondary)
                            .withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          );
        }),
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
                duration: const Duration(milliseconds: 140),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$_bpm',
                  key: ValueKey(_bpm),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    height: 0.9,
                    letterSpacing: -3,
                    fontSize: 96,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tempoMarking(_bpm),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBpmSlider(ColorScheme colors) {
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
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.outline.withValues(alpha: 0.18),
              thumbColor: colors.primary,
              overlayColor: colors.primary.withValues(alpha: 0.12),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: _bpm.toDouble(),
              min: _minBpm.toDouble(),
              max: _maxBpm.toDouble(),
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

  Widget _buildTimeSignature(
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
              l10n.metronomeAccent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(
              value: _accentFirstBeat,
              onChanged: (v) => setState(() => _accentFirstBeat = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              backgroundColor: colors.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              side: BorderSide(
                color: selected
                    ? colors.primary
                    : colors.outline.withValues(alpha: 0.22),
              ),
              onSelected: (_) => setState(() {
                _beatsPerBar = n;
                if (!_isPlaying) _currentBeat = 0;
              }),
            );
          }).toList(),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
