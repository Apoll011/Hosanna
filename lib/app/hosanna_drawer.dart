import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/sync_status_banner.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/folders/data/folder_repository.dart';
import '../features/songs/data/song_repository.dart';
import '../features/songs/domain/library_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/hosanna_logo.dart';
import 'nav_branches.dart';

/// Duration for every collapse/expand transition in the nav content. Kept in
/// sync with the sidebar's own width animation (see shell.dart) so the drawer
/// frame and its contents move together.
const Duration _kAnimDuration = Duration(milliseconds: 250);

/// Curve for every collapse/expand transition in the nav content.
const Curve _kAnimCurve = Curves.easeOutCubic;

/// Cross-fades and size-animates [child] in/out when [visible] flips, so
/// blocks like section labels and the sync banner collapse/expand smoothly
/// instead of popping in and out of existence.
class _RevealBlock extends StatelessWidget {
  const _RevealBlock({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedCrossFade(
        duration: _kAnimDuration,
        reverseDuration: _kAnimDuration,
        sizeCurve: _kAnimCurve,
        firstCurve: _kAnimCurve,
        secondCurve: _kAnimCurve,
        firstChild: child,
        secondChild: const SizedBox.shrink(),
        crossFadeState: visible
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
      ),
    );
  }
}

/// The reusable navigation body (header + user card + sections + footer),
/// shared by the mobile [HosannaDrawer] and the tablet persistent sidebar.
class HosannaNavContent extends ConsumerWidget {
  const HosannaNavContent({
    super.key,
    required this.onNavigate,
    this.collapsed = false,
    this.currentBranch = kSongsBranch,
  });

  /// Called with the target shell branch index (see [nav_branches]).
  final void Function(int branchIndex) onNavigate;

  /// When true, renders icon-only rows (tablet collapsed sidebar).
  final bool collapsed;

  /// The currently active shell branch, used to highlight the matching row.
  final int currentBranch;

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
    final imageUrl = user?.image;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header.
        AnimatedPadding(
          duration: _kAnimDuration,
          curve: _kAnimCurve,
          padding: EdgeInsets.fromLTRB(
            collapsed ? 12 : 16,
            16,
            collapsed ? 12 : 16,
            2,
          ),
          child: Column(
            children: [
              // The logo is the same element in both states; when the
              // sidebar collapses it glides from the leading edge to the
              // center of the header.
              SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedAlign(
                        alignment: collapsed
                            ? Alignment.center
                            : Alignment.centerLeft,
                        duration: _kAnimDuration,
                        curve: _kAnimCurve,
                        // HosannaLogo centers itself internally (see
                        // hosanna_logo.dart), so pin it to a fixed 40x40 box
                        // here — otherwise it would fill the whole header and
                        // ignore this alignment, staying centered in both
                        // states.
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: HosannaLogo(size: 40, borderRadius: 12),
                        ),
                      ),
                    ),
                    // Title/org text, revealed only when expanded. Left edge
                    // matches the logo width; the 12px gap lives in the
                    // padding below.
                    Positioned(
                      left: 40,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: _RevealBlock(
                        visible: !collapsed,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _RevealBlock(
                visible: !collapsed,
                child: SyncStatusBanner(compact: false),
              ),
            ],
          ),
        ),
        const Divider(),

        // Scrollable content.
        Expanded(
          child: AnimatedPadding(
            duration: _kAnimDuration,
            curve: _kAnimCurve,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _RevealBlock(
                  visible: !collapsed,
                  child: _SectionLabel(l10n.navLibrarySection),
                ),
                _NavItem(
                  icon: Icons.music_note_outlined,
                  iconColor: theme.colorScheme.primary,
                  label: l10n.navAllSongs,
                  count: songs.length,
                  // Library rows only highlight while the Songs branch is
                  // active; on the tools/services branches the current branch
                  // highlight belongs to that row alone.
                  selected:
                      currentBranch == kSongsBranch &&
                      library.section == LibrarySection.all,
                  collapsed: collapsed,
                  onTap: () => selectSection(LibrarySection.all),
                ),
                _NavItem(
                  icon: Icons.favorite_outline,
                  iconColor: theme.colorScheme.primary,
                  label: l10n.navFavorites,
                  count: library.favoriteIds.length,
                  selected:
                      currentBranch == kSongsBranch &&
                      library.section == LibrarySection.favorites,
                  collapsed: collapsed,
                  onTap: () => selectSection(LibrarySection.favorites),
                ),
                _NavItem(
                  icon: Icons.history,
                  iconColor: Colors.amber,
                  label: l10n.navRecents,
                  count: library.recentIds.length,
                  selected:
                      currentBranch == kSongsBranch &&
                      library.section == LibrarySection.recent,
                  collapsed: collapsed,
                  onTap: () => selectSection(LibrarySection.recent),
                ),

                _RevealBlock(
                  visible: !collapsed,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      _SectionLabel(l10n.navToolsSection),
                    ],
                  ),
                ),
                _NavItem(
                  icon: Icons.speed,
                  iconColor: Colors.teal,
                  label: l10n.navMetronome,
                  selected: currentBranch == kMetronomeBranch,
                  collapsed: collapsed,
                  onTap: () => onNavigate(kMetronomeBranch),
                ),
                _NavItem(
                  icon: Icons.donut_large,
                  iconColor: theme.colorScheme.primary,
                  label: l10n.navCircleOfFifths,
                  selected: currentBranch == kCircleOfFifthsBranch,
                  collapsed: collapsed,
                  onTap: () => onNavigate(kCircleOfFifthsBranch),
                ),

                _RevealBlock(
                  visible: !collapsed,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        alignment: .centerStart,
                        child: _SectionLabel(l10n.navFolders),
                      ),
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
                          _NavItem(
                            icon: Icons.folder_outlined,
                            iconColor: theme.colorScheme.primary,
                            label: folder.name,
                            count: folder.songCount,
                            selected:
                                currentBranch == kSongsBranch &&
                                library.section == LibrarySection.folder &&
                                library.folderId == folder.id,
                            collapsed: collapsed,
                            onTap: () => selectSection(
                              LibrarySection.folder,
                              folderId: folder.id,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer — the user card doubles as the Settings entry point.
        if (user != null) const Divider(height: 1),
        if (collapsed) const SizedBox(height: 6),
        if (user != null)
          Center(
            child: Material(
              color: currentBranch == kSettingsBranch
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onNavigate(kSettingsBranch),
                child: AnimatedPadding(
                  duration: _kAnimDuration,
                  curve: _kAnimCurve,
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed ? 0 : 16,
                    vertical: collapsed ? 0 : 8,
                  ),
                  child: Row(
                    // Icon-only mode centers the avatar; expanded mode fills the
                    // width like the ListTile it replaces.
                    mainAxisSize: collapsed
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    children: [
                      // The avatar is the same widget in both states, so it
                      // morphs its radius instead of popping between sizes.
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: collapsed ? 18 : 16),
                        duration: _kAnimDuration,
                        curve: _kAnimCurve,
                        builder: (context, radius, _) => CircleAvatar(
                          radius: radius,
                          foregroundImage:
                              imageUrl != null && imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(imageUrl)
                              : null,
                          onForegroundImageError: (exception, stackTrace) {
                            debugPrint('Failed to load avatar: $exception');
                          },
                          child: Text(
                            _initials(user.name),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ),
                      Flexible(
                        child: _RevealBlock(
                          visible: !collapsed,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _RevealBlock(
                        visible: !collapsed,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }
}

/// Slide-in navigation drawer for phones.
class HosannaDrawer extends StatelessWidget {
  const HosannaDrawer({
    super.key,
    required this.onNavigate,
    this.currentBranch = kSongsBranch,
  });

  final void Function(int branchIndex) onNavigate;
  final int currentBranch;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: HosannaNavContent(
          currentBranch: currentBranch,
          onNavigate: (branchIndex) {
            Navigator.of(context).pop(); // close the drawer
            onNavigate(branchIndex);
          },
        ),
      ),
    );
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
    this.collapsed = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final int? count;
  final bool selected;
  final bool collapsed;

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
        child: AnimatedPadding(
          duration: _kAnimDuration,
          curve: _kAnimCurve,
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 12,
            vertical: collapsed ? 12 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                // Icon-only rows stay centered; expanded rows fill the width.
                mainAxisSize: collapsed ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  // The icon is the same widget in both states, so it morphs
                  // its size instead of popping between 20 and 22.
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: collapsed ? 22 : 20),
                    duration: _kAnimDuration,
                    curve: _kAnimCurve,
                    builder: (context, size, _) =>
                        Icon(icon, size: size, color: iconColor),
                  ),
                  Flexible(
                    child: _RevealBlock(
                      visible: !collapsed,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _RevealBlock(
                    visible: !collapsed && count != null,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
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
                    ),
                  ),
                ],
              ),
              // Icon-only rows put the count underneath the icon.
              _RevealBlock(
                visible: collapsed && count != null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}
