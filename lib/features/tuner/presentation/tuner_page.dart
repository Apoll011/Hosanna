import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pitch_kit/pitch_kit.dart';

import '../../../app/design/tokens.dart';
import '../../../app/nav_branches.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../domain/tuning_profile.dart';

class TunerPage extends ConsumerStatefulWidget {
  const TunerPage({super.key});

  @override
  ConsumerState<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends ConsumerState<TunerPage> {
  final PitchStabilityFilter _stability = PitchStabilityFilter();
  bool _listening = false;
  bool _uncertain = true;
  Object? _error;
  String? _detectedNote;
  double? _frequency;
  MatchedString? _match;

  void _start() {
    _stability.reset();
    setState(() {
      _listening = true;
      _uncertain = true;
      _frequency = null;
      _detectedNote = null;
      _match = null;
      _error = null;
    });
  }

  void _stop() {
    _stability.reset();
    setState(() {
      _listening = false;
      _uncertain = true;
      _frequency = null;
      _detectedNote = null;
      _match = null;
      _error = null;
    });
  }

  void _onResult(TuningResult result, TuningProfile profile) {
    if (result is! NoteTuningResult) {
      if (mounted) setState(() => _uncertain = true);
      return;
    }
    final stableFrequency = _stability.add(result.freq);
    if (!mounted) return;
    setState(() {
      if (stableFrequency == null) {
        _uncertain = true;
        _frequency = null;
        _detectedNote = null;
        _match = null;
        return;
      }
      _uncertain = false;
      _frequency = stableFrequency;
      _detectedNote = result.name;
      _match = matchString(stableFrequency, profile.strings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = ref.watch(songDisplaySettingsProvider);
    final profile = TuningProfileResolver.resolve(
      instrumentId: display.instrument,
      preference: display.currentInstrumentPreference,
    );
    final onTunerBranch = ref.watch(shellBranchIndexProvider) == kTunerBranch;
    final profileKey = profile?.strings
        .map((s) => '${s.name}:${s.frequency}')
        .join('|');
    final theme = Theme.of(context);
    final isActive = _listening && onTunerBranch && profile != null;
    final match = _match;
    final cents = isActive && !_uncertain ? match?.cents : null;
    final inTune = cents != null && cents.abs() <= 5;
    final status = cents == null
        ? l10n.tunerSearching
        : inTune
        ? l10n.tunerInTune
        : cents < 0
        ? l10n.tunerFlat
        : l10n.tunerSharp;
    final statusColor = cents == null
        ? theme.colorScheme.onSurfaceVariant
        : inTune
        ? HosannaColors.success
        : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTuner)),
      body: profile == null
          ? Center(child: Text(l10n.tunerUnavailable))
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  final details = _TunerDetails(
                    targetLabel: l10n.tunerTarget,
                    target: match == null
                        ? l10n.tunerNone
                        : '${match.string.name} · ${match.string.frequency.toStringAsFixed(2)} Hz',
                    detectedLabel: l10n.tunerDetectedFrequency,
                    detected: _frequency == null
                        ? l10n.tunerNone
                        : '${_frequency!.toStringAsFixed(2)} Hz',
                  );
                  final gauge = _TunerGauge(
                    listening: isActive,
                    note: cents == null ? '—' : _detectedNote!,
                    status: status,
                    statusColor: statusColor,
                    cents: cents,
                    playString: l10n.tunerPlayString,
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (isActive)
                            PitchKitListener(
                              key: ValueKey(profileKey),
                              profile: profile.profile,
                              titleText: l10n.tunerMicrophoneTitle,
                              rationaleText: l10n.tunerMicrophoneRationale,
                              permanentlyDeniedText: l10n.tunerMicrophoneDenied,
                              allowText: l10n.tunerAllow,
                              openSettingsText: l10n.tunerOpenSettings,
                              dismissText: l10n.tunerNotNow,
                              onResult: (result) => _onResult(result, profile),
                              onError: (error) {
                                if (mounted) {
                                  setState(() {
                                    _error = error;
                                    _uncertain = true;
                                  });
                                }
                              },
                              child: const SizedBox.shrink(),
                            ),
                          Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: wide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(flex: 3, child: gauge),
                                        const SizedBox(width: 28),
                                        Expanded(flex: 2, child: details),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        gauge,
                                        const SizedBox(height: 24),
                                        details,
                                      ],
                                    ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              l10n.tunerMicrophoneError,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: isActive ? _stop : _start,
                              icon: Icon(
                                isActive ? LucideIcons.square : LucideIcons.mic,
                              ),
                              label: Text(
                                isActive ? l10n.tunerStop : l10n.tunerStart,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _TunerGauge extends StatelessWidget {
  const _TunerGauge({
    required this.listening,
    required this.note,
    required this.status,
    required this.statusColor,
    required this.cents,
    required this.playString,
  });

  final bool listening;
  final String note;
  final String status;
  final Color statusColor;
  final double? cents;
  final String playString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centsValue = cents;
    return Column(
      children: [
        Text(
          listening
              ? AppLocalizations.of(context).tunerListening
              : AppLocalizations.of(context).tunerStopped,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          note,
          style: theme.textTheme.displayLarge?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 80,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          status,
          style: theme.textTheme.titleMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        _TuningMeter(cents: centsValue, color: statusColor),
        const SizedBox(height: 12),
        Text(
          centsValue == null
              ? playString
              : '${centsValue > 0 ? '+' : ''}${centsValue.toStringAsFixed(1)} cents',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TunerDetails extends StatelessWidget {
  const _TunerDetails({
    required this.targetLabel,
    required this.target,
    required this.detectedLabel,
    required this.detected,
  });

  final String targetLabel;
  final String target;
  final String detectedLabel;
  final String detected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _TunerDetailRow(
          icon: LucideIcons.music2,
          label: targetLabel,
          value: target,
        ),
        Divider(height: 24, color: theme.colorScheme.outlineVariant),
        _TunerDetailRow(
          icon: LucideIcons.audioLines,
          label: detectedLabel,
          value: detected,
        ),
      ],
    );
  }
}

class _TunerDetailRow extends StatelessWidget {
  const _TunerDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TuningMeter extends StatelessWidget {
  const _TuningMeter({required this.cents, required this.color});

  final double? cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (cents ?? 0).clamp(-50, 50).toDouble();
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 90,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(value / 50, 1),
                  child: Container(
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cents == null ? scheme.onSurfaceVariant : color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text('-50'), Text('0'), Text('+50')],
          ),
        ],
      ),
    );
  }
}
