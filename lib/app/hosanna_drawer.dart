import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/auth_controller.dart';
import '../features/collections/data/collection_repository.dart';
import '../features/folders/data/folder_repository.dart';
import '../features/folders/domain/folder_explorer_controller.dart';
import '../features/songs/data/song_repository.dart';
import '../features/songs/domain/library_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/hosanna_logo.dart';
import '../shared/widgets/hosanna_surface.dart';
import '../shared/widgets/sync_status_banner.dart';
import 'design/tokens.dart';
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
    final tokens = HosannaTokens.of(context);
    final auth = ref.watch(authControllerProvider);
    final library = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);
    final songs = ref.watch(songsStreamProvider).valueOrNull ?? const [];
    final folders = ref.watch(foldersStreamProvider).valueOrNull ?? const [];
    final collections =
        ref.watch(collectionsStreamProvider).valueOrNull ?? const [];

    final user = auth.session?.user;
    final org = auth.organization;
    final imageUrl = user?.image;

    void selectSection(
      LibrarySection section, {
      String? folderId,
      String? collectionId,
    }) {
      switch (section) {
        case LibrarySection.all:
          libraryController.selectAll();
        case LibrarySection.favorites:
          libraryController.selectFavorites();
        case LibrarySection.recent:
          libraryController.selectRecent();
        case LibrarySection.folder:
          libraryController.selectFolder(folderId!);
        case LibrarySection.collection:
          libraryController.selectCollection(collectionId!);
      }
      onNavigate(0);
    }

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedPadding(
            duration: _kAnimDuration,
            curve: _kAnimCurve,
            padding: EdgeInsets.fromLTRB(
              collapsed ? 12 : 16,
              16,
              collapsed ? 12 : 16,
              8,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedAlign(
                          alignment: collapsed
                              ? Alignment.center
                              : Alignment.centerLeft,
                          duration: _kAnimDuration,
                          curve: _kAnimCurve,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: HosannaLogo(size: 44, borderRadius: 14),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 44,
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.subtleFill,
                      borderRadius: HosannaRadii.card,
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: SyncStatusBanner(compact: false),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedPadding(
              duration: _kAnimDuration,
              curve: _kAnimCurve,
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _RevealBlock(
                    visible: !collapsed,
                    child: HosannaSectionLabel(l10n.navLibrarySection),
                  ),
                  _NavItem(
                    icon: Icons.music_note_outlined,
                    label: l10n.navAllSongs,
                    count: songs.length,
                    selected: currentBranch == kSongsBranch &&
                        library.section == LibrarySection.all,
                    collapsed: collapsed,
                    onTap: () => selectSection(LibrarySection.all),
                  ),
                  _NavItem(
                    icon: Icons.favorite_outline,
                    label: l10n.navFavorites,
                    count: library.favoriteIds.length,
                    selected: currentBranch == kSongsBranch &&
                        library.section == LibrarySection.favorites,
                    collapsed: collapsed,
                    onTap: () => selectSection(LibrarySection.favorites),
                  ),
                  _NavItem(
                    icon: Icons.history,
                    label: l10n.navRecents,
                    count: library.recentIds.length,
                    selected: currentBranch == kSongsBranch &&
                        library.section == LibrarySection.recent,
                    collapsed: collapsed,
                    onTap: () => selectSection(LibrarySection.recent),
                  ),
                  _NavItem(
                    icon: Icons.folder_outlined,
                    label: l10n.navFolders,
                    count: folders.length,
                    selected: currentBranch == kFoldersBranch,
                    collapsed: collapsed,
                    onTap: () {
                      ref.read(folderExplorerProvider.notifier).open(null);
                      onNavigate(kFoldersBranch);
                    },
                  ),

                  _RevealBlock(
                    visible: !collapsed,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        HosannaSectionLabel(l10n.navCollections),
                        if (collections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            child: Text(
                              l10n.collectionsEmpty,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          for (final collection in collections)
                            _NavItem(
                              icon: Icons.collections_bookmark_outlined,
                              label: collection.name,
                              count: collection.songCount,
                              selected: currentBranch == kSongsBranch &&
                                  library.section ==
                                      LibrarySection.collection &&
                                  library.collectionId == collection.id,
                              collapsed: collapsed,
                              onTap: () => selectSection(
                                LibrarySection.collection,
                                collectionId: collection.id,
                              ),
                            ),
                      ],
                    ),
                  ),

                  _RevealBlock(
                    visible: !collapsed,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        HosannaSectionLabel(l10n.navToolsSection),
                      ],
                    ),
                  ),
                  _NavItem(
                    icon: Icons.speed,
                    label: l10n.navMetronome,
                    selected: currentBranch == kMetronomeBranch,
                    collapsed: collapsed,
                    onTap: () => onNavigate(kMetronomeBranch),
                  ),
                  _NavItem(
                    icon: Icons.donut_large,
                    label: l10n.navCircleOfFifths,
                    selected: currentBranch == kCircleOfFifthsBranch,
                    collapsed: collapsed,
                    onTap: () => onNavigate(kCircleOfFifthsBranch),
                  ),
                  _NavItem(
                    icon: Icons.event_outlined,
                    label: l10n.navAgenda,
                    selected: currentBranch == kAgendaBranch,
                    collapsed: collapsed,
                    onTap: () => onNavigate(kAgendaBranch),
                  ),
                ],
              ),
            ),
          ),

          if (user != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 8 : 12,
                4,
                collapsed ? 8 : 12,
                12,
              ),
              child: Material(
                color: currentBranch == kSettingsBranch
                    ? tokens.selectedNav
                    : tokens.subtleFill,
                borderRadius: BorderRadius.circular(HosannaRadii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(HosannaRadii.md),
                  onTap: () => onNavigate(kSettingsBranch),
                  child: AnimatedPadding(
                    duration: _kAnimDuration,
                    curve: _kAnimCurve,
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 0 : 12,
                      vertical: collapsed ? 8 : 10,
                    ),
                    child: Row(
                      mainAxisSize:
                          collapsed ? MainAxisSize.min : MainAxisSize.max,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: collapsed ? 18 : 18),
                          duration: _kAnimDuration,
                          curve: _kAnimCurve,
                          builder: (context, radius, _) {
                            final hasImage =
                                imageUrl != null && imageUrl.isNotEmpty;
                            return CircleAvatar(
                              radius: radius,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundImage: hasImage
                                  ? CachedNetworkImageProvider(imageUrl)
                                  : null,
                              onForegroundImageError: hasImage
                                  ? (exception, stackTrace) {
                                      debugPrint(
                                        'Failed to load avatar: $exception',
                                      );
                                    }
                                  : null,
                              child: Text(
                                _initials(user.name),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                        if (!collapsed) ...[
                          Expanded(
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
            Navigator.of(context).pop();
            onNavigate(branchIndex);
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? count;
  final bool selected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = HosannaTokens.of(context);
    final bg = selected ? tokens.selectedNav : Colors.transparent;
    final fg = selected
        ? tokens.selectedNavForeground
        : theme.colorScheme.onSurface;
    final iconColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(HosannaRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(HosannaRadii.sm),
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
                  mainAxisSize:
                      collapsed ? MainAxisSize.min : MainAxisSize.max,
                  children: [
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
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: fg,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _RevealBlock(
                      visible: !collapsed && count != null,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary
                                : tokens.subtleFill,
                            borderRadius: BorderRadius.circular(HosannaRadii.xs),
                          ),
                          child: Text(
                            '$count',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      ),
    );
  }
}
