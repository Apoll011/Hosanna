import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/settings_controller.dart';
import '../../../app/theme.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_controller.dart';
import '../../services/data/service_repository.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';

enum SettingsTab { account, workspace, preferences }

/// Tabbed settings, mirroring the React `SettingsView` (Conta / Organização /
/// Preferências). Tools (metronome, circle of fifths, PDF export) live in the
/// navigation drawer, not here.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.initialTab = SettingsTab.account});

  final SettingsTab initialTab;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SettingsTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _TabBar(selected: _tab, onChanged: (t) => setState(() => _tab = t)),
          Expanded(
            child: switch (_tab) {
              SettingsTab.account => const _AccountTab(),
              SettingsTab.workspace => const _WorkspaceTab(),
              SettingsTab.preferences => const _PreferencesTab(),
            },
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});

  final SettingsTab selected;
  final ValueChanged<SettingsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final tabs = [
      (SettingsTab.account, l10n.settingsTabAccount, Icons.person_outline),
      (
        SettingsTab.workspace,
        l10n.settingsTabWorkspace,
        Icons.business_outlined,
      ),
      (SettingsTab.preferences, l10n.settingsTabPreferences, Icons.tune),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (tab, label, icon) in tabs)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == tab
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: selected == tab
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected == tab
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
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

// ── Account tab ─────────────────────────────────────────────────────────────

class _AccountTab extends ConsumerStatefulWidget {
  const _AccountTab();

  @override
  ConsumerState<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<_AccountTab> {
  bool _editingName = false;
  bool _editingEmail = false;
  bool _editingPassword = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveName() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast(l10n.settingsNameEmpty);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(name: name);
      setState(() => _editingName = false);
      _toast(l10n.authNameSaved);
    } catch (e) {
      _toast(l10n.commonError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      _toast(l10n.settingsEmailInvalid);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changeEmail(newEmail: email);
      setState(() => _editingEmail = false);
      _toast(l10n.settingsEmailChangeSent);
    } catch (e) {
      _toast(l10n.commonError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePassword() async {
    final l10n = AppLocalizations.of(context);
    if (_newPwdCtrl.text.length < 6) {
      setState(() => _error = l10n.authPasswordMinLength);
      return;
    }
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      setState(() => _error = l10n.authPasswordsDontMatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _oldPwdCtrl.text,
            newPassword: _newPwdCtrl.text,
          );
      setState(() => _editingPassword = false);
      _oldPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      _toast(l10n.authPasswordChanged);
    } catch (e) {
      setState(() => _error = l10n.authPasswordChangeError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth.session?.user;
    final org = auth.organization;

    final imageUrl = user?.image;

    debugPrint('User image: $imageUrl');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card.
        _Card(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow =
                  constraints.maxWidth < 360; // tweak breakpoint as needed

              final avatarAndInfo = Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    foregroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                    onForegroundImageError: (exception, stackTrace) {
                      debugPrint('Failed to load avatar: $exception');
                    },
                    child: Text(
                      _initials(user?.name ?? ''),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '—',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 16),
                    _signOutButton(theme, l10n),
                  ],
                ],
              );

              if (!isNarrow) return avatarAndInfo;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  avatarAndInfo,
                  const SizedBox(height: 12),
                  _signOutButton(theme, l10n),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Name.
        _Card(
          child: _EditableField(
            label: l10n.authName,
            editing: _editingName,
            value: user?.name ?? '—',
            onEdit: () {
              _nameCtrl.text = user?.name ?? '';
              setState(() => _editingName = true);
            },
            onCancel: () => setState(() => _editingName = false),
            onSave: _saveName,
            saving: _saving,
            editor: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.authName,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Email.
        _Card(
          child: _EditableField(
            label: l10n.authEmail,
            editing: _editingEmail,
            value: user?.email ?? '—',
            onEdit: () {
              _emailCtrl.text = user?.email ?? '';
              setState(() => _editingEmail = true);
            },
            onCancel: () => setState(() => _editingEmail = false),
            onSave: _saveEmail,
            saving: _saving,
            editor: TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.settingsNewEmail,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Password.
        _Card(
          child: _editingPassword
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(l10n.authChangePassword),
                    const SizedBox(height: 12),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _oldPwdCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.authCurrentPassword,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPwdCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.authNewPassword,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPwdCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.authConfirmPassword,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _editingPassword = false),
                          child: Text(l10n.settingsCancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _saving ? null : _savePassword,
                          child: Text(
                            _saving
                                ? l10n.settingsSaving
                                : l10n.authChangePassword,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : _ReadonlyRow(
                  label: l10n.authChangePassword,
                  value: '••••••••••••',
                  onEdit: () => setState(() => _editingPassword = true),
                ),
        ),
        const SizedBox(height: 16),

        // Account info.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(l10n.authAccount),
              const SizedBox(height: 12),
              _InfoRow(label: l10n.settingsUserId, value: user?.id ?? '—'),
              const SizedBox(height: 8),
              _InfoRow(
                label: l10n.settingsActiveOrg,
                value: org?.name ?? l10n.settingsNoActiveOrg,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signOutButton(ThemeData theme, AppLocalizations l10n) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
      icon: const Icon(Icons.logout, size: 16),
      label: Text(l10n.authSignOut),
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }
}

// ── Workspace tab ────────────────────────────────────────────────────────────

class _WorkspaceTab extends ConsumerStatefulWidget {
  const _WorkspaceTab();

  @override
  ConsumerState<_WorkspaceTab> createState() => _WorkspaceTabState();
}

class _WorkspaceTabState extends ConsumerState<_WorkspaceTab> {
  List<Organization> _orgs = const [];
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    try {
      final orgs = await ref
          .read(authControllerProvider.notifier)
          .listOrganizations();
      if (mounted) setState(() => _orgs = orgs);
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> _switchOrg(String slug) async {
    setState(() => _switching = true);
    try {
      await ref.read(authControllerProvider.notifier).switchOrganization(slug);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commonError)),
        );
      }
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final org = auth.organization;
    final sync = ref.watch(syncControllerProvider);
    final syncController = ref.read(syncControllerProvider.notifier);
    final songs = ref.watch(songsStreamProvider).valueOrNull ?? const [];
    final services = ref.watch(servicesStreamProvider).valueOrNull ?? const [];

    final lastSync = sync.lastSyncedAt == null
        ? l10n.syncNever
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .add_Hm()
              .format(sync.lastSyncedAt!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Organization overview.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org?.name ?? l10n.settingsOrganization,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Slug: ${org?.slug ?? '—'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (org != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        l10n.settingsActive,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              // Org switcher (only if user belongs to several).
              if (_orgs.length > 1) ...[
                const Divider(height: 24),
                _SectionLabel(l10n.settingsSwitchOrg),
                const SizedBox(height: 8),
                for (final o in _orgs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(o.name),
                    subtitle: Text(o.slug),
                    trailing: o.slug == org?.slug
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : const Icon(Icons.circle_outlined),
                    enabled: !_switching && o.slug != org?.slug,
                    onTap: () => _switchOrg(o.slug),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sync.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsSyncLibrary,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.settingsSyncLibraryDesc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: FilledButton.icon(
                  onPressed: sync.isSyncing
                      ? null
                      : () => syncController.syncAll(),
                  icon: sync.isSyncing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(l10n.settingsSyncNow),
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: l10n.settingsLastSync, value: lastSync),
              const SizedBox(height: 8),
              _InfoRow(
                label: l10n.settingsSyncState,
                value: switch (sync.status) {
                  SyncStatus.syncing => l10n.syncSyncing,
                  SyncStatus.synced => l10n.syncSynced,
                  SyncStatus.error => l10n.syncError,
                  SyncStatus.offline => l10n.syncOffline,
                  SyncStatus.idle => l10n.syncSynced,
                },
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: l10n.settingsLocalSongs,
                value: '${songs.length}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: l10n.settingsSavedServices,
                value: '${services.length}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preferences tab ─────────────────────────────────────────────────────────

class _PreferencesTab extends ConsumerWidget {
  const _PreferencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final display = ref.watch(songDisplaySettingsProvider);
    final displayController = ref.read(songDisplaySettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Musician mode.
        _Card(
          child: _SwitchRow(
            icon: Icons.music_note,
            iconColor: theme.colorScheme.primary,
            title: l10n.settingsMusicianMode,
            subtitle: l10n.settingsMusicianModeDesc,
            value: settings.musicianMode,
            onChanged: settingsController.setMusicianMode,
          ),
        ),
        const SizedBox(height: 12),

        // Theme.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(l10n.settingsTheme),
              const SizedBox(height: 12),
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
                onSelectionChanged: (s) =>
                    settingsController.setThemeMode(s.first),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsHighContrast),
                value: settings.highContrast,
                onChanged: settingsController.setHighContrast,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Language.
        _Card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguageLabel),
            trailing: DropdownButton<String?>(
              value: settings.localeCode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: null, child: Text('—')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
              ],
              onChanged: settingsController.setLocale,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Font size.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(
                    '${l10n.songFontSize} (${display.fontSize.toInt()}px)',
                  ),
                  Text(
                    'Exemplo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: display.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: display.fontSize.clamp(12, 28).toDouble(),
                min: 12,
                max: 28,
                divisions: 16,
                label: display.fontSize.toInt().toString(),
                onChanged: displayController.setFontSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Display toggles.
        _Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.songShowChords),
                value: display.showChords,
                onChanged: (_) => displayController.toggleShowChords(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.songShowDiagrams),
                value: display.showDiagrams,
                onChanged: (_) => displayController.toggleDiagrams(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.songTwoColumn),
                value: display.twoColumn,
                onChanged: (_) => displayController.toggleTwoColumn(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsKeepAwake),
                subtitle: Text(l10n.settingsKeepAwakeDesc),
                value: settings.keepScreenAwake,
                onChanged: settingsController.setKeepScreenAwake,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note),
                title: Text(l10n.songInstrument),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'guitar',
                      label: Text('Guitarra'),
                      icon: Icon(Icons.graphic_eq),
                    ),
                    ButtonSegment(
                      value: 'piano',
                      label: Text('Piano'),
                      icon: Icon(Icons.piano),
                    ),
                  ],
                  selected: {display.instrument},
                  onSelectionChanged: (s) =>
                      displayController.setInstrument(s.first),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyRow extends StatelessWidget {
  const _ReadonlyRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(l10n.settingsEdit),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.editing,
    required this.value,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.editor,
  });

  final String label;
  final bool editing;
  final String value;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final Widget editor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editor,
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: Text(l10n.settingsCancel)),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? l10n.settingsSaving : l10n.settingsSave),
              ),
            ],
          ),
        ],
      );
    }
    return _ReadonlyRow(label: label, value: value, onEdit: onEdit);
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
