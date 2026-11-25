import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _stability.reset();
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
        .map((string) => '${string.name}:${string.frequency}')
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
          : Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
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
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                20,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    isActive
                                        ? l10n.tunerListening
                                        : l10n.tunerStopped,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    cents == null ? '—' : _detectedNote!,
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 88,
                                        ),
                                  ),
                                  Text(
                                    status,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _TuningMeter(
                                    cents: cents,
                                    color: statusColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    cents == null
                                        ? l10n.tunerWaitForStablePitch
                                        : '${cents > 0 ? '+' : ''}${cents.toStringAsFixed(1)} cents',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.music_note),
                                  title: Text(l10n.tunerTarget),
                                  subtitle: Text(
                                    match == null
                                        ? l10n.tunerNone
                                        : '${match.string.name} · ${match.string.frequency.toStringAsFixed(2)} Hz',
                                  ),
                                  trailing: match == null
                                      ? null
                                      : Text(
                                          '${match.string.frequency.toStringAsFixed(2)} Hz',
                                        ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.graphic_eq),
                                  title: Text(l10n.tunerDetectedFrequency),
                                  subtitle: Text(
                                    _frequency == null
                                        ? l10n.tunerNone
                                        : '${_frequency!.toStringAsFixed(2)} Hz',
                                  ),
                                ),
                              ],
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
                          FilledButton.icon(
                            onPressed: isActive ? _stop : _start,
                            icon: Icon(isActive ? Icons.stop : Icons.mic),
                            label: Text(
                              isActive ? l10n.tunerStop : l10n.tunerStart,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
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
                      color: cents == null
                          ? Theme.of(context).disabledColor
                          : color,
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
            children: [Text('-50'), Text('0'), Text('+50')],
          ),
        ],
      ),
    );
  }
}
