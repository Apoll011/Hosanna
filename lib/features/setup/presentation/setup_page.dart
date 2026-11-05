import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/settings_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../data/setup_controller.dart';
import '../domain/setup_draft.dart';

/// Post-login preference wizard (role, instrument, stage defaults, language).
///
/// Shown after the user has an organization and before the main shell, until
/// [SetupController] marks setup complete.
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

enum _Step { welcome, role, focus, prefs, language, done }

class _SetupPageState extends ConsumerState<SetupPage> {
  final _pageController = PageController();
  SetupDraft _draft = const SetupDraft();
  var _stepIndex = 0;
  var _finishing = false;

  List<_Step> get _steps {
    final steps = <_Step>[_Step.welcome, _Step.role];
    // Instrument choice is only for musicians.
    if (_draft.role == SetupRole.musician) {
      steps.add(_Step.focus);
    }
    steps.addAll([_Step.prefs, _Step.language, _Step.done]);
    return steps;
  }

  _Step get _currentStep => _steps[_stepIndex.clamp(0, _steps.length - 1)];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    setState(() => _stepIndex = index);
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_stepIndex >= _steps.length - 1) {
      await _finish();
      return;
    }
    await _goTo(_stepIndex + 1);
  }

  Future<void> _back() async {
    if (_stepIndex <= 0) return;
    await _goTo(_stepIndex - 1);
  }

  bool get _canContinue => switch (_currentStep) {
        _Step.welcome || _Step.prefs || _Step.language || _Step.done => true,
        _Step.role => _draft.role != null,
        _Step.focus => _draft.focus != null,
      };

  Future<void> _finish({bool skipped = false}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final role = skipped
        ? SetupRole.musician
        : (_draft.role ?? SetupRole.musician);
    final draft = skipped
        ? const SetupDraft(
            role: SetupRole.musician,
            focus: SetupPrimaryFocus.guitar,
          )
        : _draft.copyWith(
            role: role,
            // Leaders keep a harmless default instrument for song charts.
            focus: role == SetupRole.leader
                ? SetupPrimaryFocus.guitar
                : (_draft.focus ?? SetupPrimaryFocus.guitar),
          );

    await ref.read(setupControllerProvider.notifier).apply(
          draft,
          settings: ref.read(settingsControllerProvider.notifier),
          display: ref.read(songDisplaySettingsProvider.notifier),
        );
    if (!mounted) return;
    context.go('/songs');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _steps.length;
    final progress = (_stepIndex + 1) / total;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.38, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    if (_stepIndex > 0 && _currentStep != _Step.done)
                      IconButton(
                        tooltip: l10n.commonBack,
                        onPressed: _finishing ? null : _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor:
                                  scheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.setupStepOf(_stepIndex + 1, total),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentStep != _Step.done)
                      TextButton(
                        onPressed: _finishing ? null : () => _finish(skipped: true),
                        child: Text(l10n.setupSkip),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final step in _steps) _buildStep(step, l10n),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !_canContinue || _finishing
                        ? null
                        : () {
                            if (_currentStep == _Step.done) {
                              _finish();
                            } else {
                              _next();
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _finishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _Step.welcome
                                ? l10n.setupWelcomeCta
                                : _currentStep == _Step.done
                                    ? l10n.setupDoneCta
                                    : l10n.commonNext,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_Step step, AppLocalizations l10n) {
    return switch (step) {
      _Step.welcome => _WelcomeStep(l10n: l10n),
      _Step.role => _RoleStep(
          l10n: l10n,
          selected: _draft.role,
          onSelect: (role) => setState(() {
            _draft = _draft.copyWith(
              role: role,
              clearFocus: role != SetupRole.musician,
              showDiagrams: role == SetupRole.musician,
            );
          }),
        ),
      _Step.focus => _FocusStep(
          l10n: l10n,
          selected: _draft.focus,
          onSelect: (focus) => setState(() {
            _draft = _draft.copyWith(
              focus: focus,
              showDiagrams: focus == SetupPrimaryFocus.vocals
                  ? false
                  : _draft.showDiagrams,
            );
          }),
        ),
      _Step.prefs => _PrefsStep(
          l10n: l10n,
          draft: _draft,
          showDiagramsToggle: _draft.role == SetupRole.musician,
          onChanged: (next) => setState(() => _draft = next),
        ),
      _Step.language => _LanguageStep(
          l10n: l10n,
          selected: _draft.localeCode,
          onSelect: (code) {
            setState(() {
              _draft = code == null
                  ? _draft.copyWith(clearLocale: true)
                  : _draft.copyWith(localeCode: code);
            });
            ref.read(settingsControllerProvider.notifier).setLocale(code);
          },
        ),
      _Step.done => _DoneStep(l10n: l10n, draft: _draft),
    };
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      imageAsset: HosannaIllustrations.setupWelcome,
      fallbackIcon: Icons.auto_awesome_rounded,
      title: l10n.setupWelcomeTitle,
      subtitle: l10n.setupWelcomeSubtitle,
      child: const SizedBox.shrink(),
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    required this.l10n,
    required this.selected,
    required this.onSelect,
  });

  final AppLocalizations l10n;
  final SetupRole? selected;
  final ValueChanged<SetupRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      title: l10n.setupRoleTitle,
      subtitle: l10n.setupRoleSubtitle,
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              child: _ChoiceTile(
                asset: HosannaIllustrations.setupRoleMusician,
                fallbackIcon: Icons.music_note_rounded,
                title: l10n.setupRoleMusician,
                selected: selected == SetupRole.musician,
                onTap: () => onSelect(SetupRole.musician),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceTile(
                asset: HosannaIllustrations.setupRoleLeader,
                fallbackIcon: Icons.groups_rounded,
                title: l10n.setupRoleLeader,
                selected: selected == SetupRole.leader,
                onTap: () => onSelect(SetupRole.leader),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.asset,
    required this.fallbackIcon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final IconData fallbackIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.75)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.55),
          width: selected ? 2.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    fallbackIcon,
                    size: 48,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusStep extends StatelessWidget {
  const _FocusStep({
    required this.l10n,
    required this.selected,
    required this.onSelect,
  });

  final AppLocalizations l10n;
  final SetupPrimaryFocus? selected;
  final ValueChanged<SetupPrimaryFocus> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(SetupPrimaryFocus, String, String, IconData)>[
      (
        SetupPrimaryFocus.guitar,
        l10n.setupFocusGuitar,
        HosannaIllustrations.setupInstrumentGuitar,
        Icons.graphic_eq_rounded,
      ),
      (
        SetupPrimaryFocus.ukulele,
        l10n.setupFocusUkulele,
        HosannaIllustrations.setupInstrumentUkulele,
        Icons.music_note_rounded,
      ),
      (
        SetupPrimaryFocus.piano,
        l10n.setupFocusPiano,
        HosannaIllustrations.setupInstrumentPiano,
        Icons.piano_rounded,
      ),
      (
        SetupPrimaryFocus.vocals,
        l10n.setupFocusVocals,
        HosannaIllustrations.setupInstrumentVocals,
        Icons.mic_rounded,
      ),
    ];

    Widget row(int start) {
      return SizedBox(
        height: 168,
        child: Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _ChoiceTile(
                  asset: options[start + i].$3,
                  fallbackIcon: options[start + i].$4,
                  title: options[start + i].$2,
                  selected: selected == options[start + i].$1,
                  onTap: () => onSelect(options[start + i].$1),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return _StepBody(
      title: l10n.setupFocusTitle,
      subtitle: l10n.setupFocusSubtitle,
      child: Column(
        children: [
          row(0),
          const SizedBox(height: 12),
          row(2),
        ],
      ),
    );
  }
}

class _PrefsStep extends StatelessWidget {
  const _PrefsStep({
    required this.l10n,
    required this.draft,
    required this.showDiagramsToggle,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final SetupDraft draft;
  final bool showDiagramsToggle;
  final ValueChanged<SetupDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      imageAsset: HosannaIllustrations.setupPrefs,
      fallbackIcon: Icons.tune_rounded,
      title: l10n.setupPrefsTitle,
      subtitle: l10n.setupPrefsSubtitle,
      child: Column(
        children: [
          if (showDiagramsToggle) ...[
            _ToggleCard(
              icon: Icons.grid_view_rounded,
              title: l10n.setupPrefDiagrams,
              subtitle: l10n.setupPrefDiagramsDesc,
              value: draft.showDiagrams,
              onChanged: (v) => onChanged(draft.copyWith(showDiagrams: v)),
            ),
            const SizedBox(height: 10),
          ],
          _ToggleCard(
            icon: Icons.phonelink_lock_rounded,
            title: l10n.setupPrefAwake,
            subtitle: l10n.setupPrefAwakeDesc,
            value: draft.keepScreenAwake,
            onChanged: (v) => onChanged(draft.copyWith(keepScreenAwake: v)),
          ),
        ],
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.l10n,
    required this.selected,
    required this.onSelect,
  });

  final AppLocalizations l10n;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String?, String)>[
      (null, l10n.setupLanguageSystem),
      ('pt', 'Português'),
      ('en', 'English'),
      ('es', 'Español'),
    ];

    return _StepBody(
      imageAsset: HosannaIllustrations.setupLanguage,
      fallbackIcon: Icons.language_rounded,
      title: l10n.setupLanguageTitle,
      subtitle: l10n.setupLanguageSubtitle,
      child: Column(
        children: [
          for (final option in options) ...[
            _SimpleChoiceCard(
              title: option.$2,
              selected: selected == option.$1,
              onTap: () => onSelect(option.$1),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.l10n, required this.draft});

  final AppLocalizations l10n;
  final SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMusician = draft.role != SetupRole.leader;
    final roleLabel =
        isMusician ? l10n.setupRoleMusician : l10n.setupRoleLeader;
    final focusLabel = switch (draft.focus) {
      SetupPrimaryFocus.guitar => l10n.setupFocusGuitar,
      SetupPrimaryFocus.ukulele => l10n.setupFocusUkulele,
      SetupPrimaryFocus.piano => l10n.setupFocusPiano,
      SetupPrimaryFocus.vocals => l10n.setupFocusVocals,
      null => '—',
    };

    return _StepBody(
      imageAsset: HosannaIllustrations.setupDone,
      fallbackIcon: Icons.check_circle_rounded,
      title: l10n.setupDoneTitle,
      subtitle: l10n.setupDoneSubtitle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: l10n.setupRoleTitle, value: roleLabel),
            if (isMusician) ...[
              const SizedBox(height: 10),
              _SummaryRow(label: l10n.setupFocusTitle, value: focusLabel),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.title,
    required this.subtitle,
    required this.child,
    this.imageAsset,
    this.fallbackIcon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? imageAsset;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          children: [
            if (imageAsset != null) ...[
              _HeroImage(
                asset: imageAsset!,
                fallbackIcon: fallbackIcon ?? Icons.music_note_rounded,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}

/// Full-width hero that keeps the image's aspect ratio (no vertical crop).
class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.asset,
    required this.fallbackIcon,
  });

  final String asset;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => SizedBox(
          height: 160,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.22),
                  scheme.tertiary.withValues(alpha: 0.14),
                  scheme.surfaceContainerHighest,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                fallbackIcon,
                size: 56,
                color: scheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleChoiceCard extends StatelessWidget {
  const _SimpleChoiceCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.65)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.55),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
