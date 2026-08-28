import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_controller.dart';
import '../features/folders/data/folder_repository.dart';
import '../features/songs/data/song_repository.dart';
import '../features/songs/domain/library_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/hosanna_logo.dart';

/// Slide-in navigation drawer mirroring the React app's `NavigationDrawer`:
/// library sections (all / favorites / recent), folders, tools (metronome,
/// circle of fifths) and settings.
class HosannaDrawer extends ConsumerWidget {
  const HosannaDrawer({super.key, required this.onNavigate});

  /// Called with the target shell branch index (0 = songs, 1 = services) when a
  /// library item is chosen, so the shell can switch branches and close itself.
  final void Function(int branchIndex) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);
    final songs = ref.watch(songsStreamProvider).valueOrNull ?? const [];
    final folders = ref.watch(foldersStreamProvider).valueOrNull ?? const [];

    final user = auth.session?.user;
    final org = auth.organization;

    void selectSection(LibrarySection section, {String? folderId}) {
      switch (section) {
        case LibrarySection.all:
          libraryController.selectAll();
        case LibrarySection.favorites:
          libraryController.selectFavorites();
        case LibrarySection.recent:
          libraryController.selectRecent();
        case LibrarySection.folder:
          libraryController.selectFolder(folderId!);
      }
      onNavigate(0);
    }

    void pushTool(String location) {
      Navigator.of(context).pop(); // close the drawer
      context.push(location);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const HosannaLogo(size: 40, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (org != null)
                          Text(
                            org.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (user != null)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(_initials(user.name)),
                ),
                title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => pushTool('/settings?tab=account'),
              ),
            const Divider(),

            // Scrollable content.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SectionLabel(l10n.navLibrarySection),
                  _DrawerItem(
                    icon: Icons.music_note_outlined,
                    iconColor: theme.colorScheme.primary,
                    label: l10n.navAllSongs,
                    count: songs.length,
                    selected: library.section == LibrarySection.all,
                    onTap: () => selectSection(LibrarySection.all),
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_outline,
                    iconColor: Colors.pink,
                    label: l10n.navFavorites,
                    count: library.favoriteIds.length,
                    selected: library.section == LibrarySection.favorites,
                    onTap: () => selectSection(LibrarySection.favorites),
                  ),
                  _DrawerItem(
                    icon: Icons.history,
                    iconColor: Colors.amber,
                    label: l10n.navRecents,
                    count: library.recentIds.length,
                    selected: library.section == LibrarySection.recent,
                    onTap: () => selectSection(LibrarySection.recent),
                  ),

                  const SizedBox(height: 8),
                  _SectionLabel(l10n.navFolders),
                  if (folders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.foldersEmpty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    for (final folder in folders)
                      _DrawerItem(
                        icon: Icons.folder_outlined,
                        iconColor: theme.colorScheme.primary,
                        label: folder.name,
                        count: folder.songCount,
                        selected: library.section == LibrarySection.folder &&
                            library.folderId == folder.id,
                        onTap: () =>
                            selectSection(LibrarySection.folder, folderId: folder.id),
                      ),

                  const SizedBox(height: 8),
                  _SectionLabel(l10n.navToolsSection),
                  _DrawerItem(
                    icon: Icons.speed,
                    iconColor: Colors.teal,
                    label: l10n.navMetronome,
                    onTap: () => pushTool('/metronome'),
                  ),
                  _DrawerItem(
                    icon: Icons.donut_large,
                    iconColor: Colors.green,
                    label: l10n.navCircleOfFifths,
                    onTap: () => pushTool('/circle-of-fifths'),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    iconColor: Colors.blueGrey,
                    label: l10n.navSettings,
                    onTap: () => pushTool('/settings'),
                  ),
                ],
              ),
            ),

            // Footer.
            if (auth.isAuthenticated)
              const Divider(height: 1),
            if (auth.isAuthenticated)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.authSignOut),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final int? count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
