import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings_controller.dart';
import '../../../app/theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsAppearance),
          SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => controller.setThemeMode(s.first),
          ),
          SwitchListTile(
            title: Text(l10n.settingsHighContrast),
            value: settings.highContrast,
            onChanged: controller.setHighContrast,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsLanguage),
          _LanguageTile(
            value: settings.localeCode,
            onChanged: controller.setLocale,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAccount),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.authAccount),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/account'),
          ),
          const Divider(),
          _SectionHeader(title: l10n.appTitle),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(l10n.navMetronome),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/metronome'),
          ),
          ListTile(
            leading: const Icon(Icons.donut_large),
            title: Text(l10n.navCircleOfFifths),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/circle-of-fifths'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.navExportPdf),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/export-pdf'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const options = {'pt': 'Português', 'en': 'English', 'es': 'Español'};

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguageLabel),
      trailing: DropdownButton<String?>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: null, child: Text('—')),
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
