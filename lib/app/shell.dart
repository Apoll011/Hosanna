import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'hosanna_drawer.dart';
import 'nav_branches.dart';
import 'providers.dart';

/// Breakpoint (logical pixels) at which the app switches to the tablet layout
/// (persistent sidebar instead of a drawer + floating bottom bar).
const double kTabletBreakpoint = 750;

/// Branches that hide the floating bottom nav bar.
///
/// The bar only ever links to the Songs and Services branches, so on the tools
/// (metronome, circle of fifths) and Settings it would just cover content
/// without showing a selected destination. Those branches are reached through
/// the drawer/sidebar instead.
const Set<int> kBranchesWithoutNavBar = {
  kMetronomeBranch,
  kCircleOfFifthsBranch,
  kSettingsBranch,
};

/// Responsive shell: phones get a slide-in drawer + floating bottom bar;
/// tablets get a persistent, retractable sidebar (mirroring the React app's
/// tablet sidebar).
class HosannaShell extends ConsumerStatefulWidget {
  const HosannaShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HosannaShell> createState() => _HosannaShellState();
}

class _HosannaShellState extends ConsumerState<HosannaShell> {
  void _goBranch(int index) {
    // Guard against a stale route table (e.g. hot reload keeping the old
    // GoRouter with fewer branches) — goBranch asserts on out-of-range
    // indices, so ignore them instead of crashing.
    final shell = widget.navigationShell;
    if (index < 0 || index >= shell.route.branches.length) return;
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final currentBranch = widget.navigationShell.currentIndex;
    // Order must match the shell branches in router.dart (see nav_branches.dart).
    // Note: only songs/services appear in the Floating Nav Bar; the tools
    // (metronome, circle of fifths) live in the sidebar/drawer only.
    final destinations = [
      _NavItem(
        branch: kSongsBranch,
        icon: Icons.music_note_outlined,
        selectedIcon: Icons.music_note,
        label: l10n.navSongs,
      ),
      _NavItem(
        branch: kServicesBranch,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n.navServices,
      ),
    ];
    final selectedDestination = destinations.indexWhere(
      (d) => d.branch == currentBranch,
    );
    final showNavBar = !kBranchesWithoutNavBar.contains(currentBranch);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= kTabletBreakpoint;

        if (isTablet) {
          return Scaffold(
            key: ref.watch(shellScaffoldKeyProvider),
            body: Row(
              children: [
                _TabletSidebar(
                  collapsed: sidebarCollapsed,
                  currentBranch: widget.navigationShell.currentIndex,
                  onNavigate: _goBranch,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.navigationShell),
                      if (showNavBar)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _FloatingNavBar(
                            selectedIndex: selectedDestination,
                            onSelected: (index) =>
                                _goBranch(destinations[index].branch),
                            destinations: destinations,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: ref.watch(shellScaffoldKeyProvider),
          body: widget.navigationShell,
          drawer: HosannaDrawer(
            currentBranch: widget.navigationShell.currentIndex,
            onNavigate: _goBranch,
          ),
          extendBody: true,
          bottomNavigationBar: showNavBar
              ? _FloatingNavBar(
                  selectedIndex: selectedDestination,
                  onSelected: (index) =>
                      _goBranch(destinations[index].branch),
                  destinations: destinations,
                )
              : null,
        );
      },
    );
  }
}

class _TabletSidebar extends StatelessWidget {
  const _TabletSidebar({
    required this.collapsed,
    required this.currentBranch,
    required this.onNavigate,
  });

  final bool collapsed;
  final int currentBranch;
  final void Function(int branchIndex) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = collapsed ? 76.0 : 288.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: HosannaNavContent(
          collapsed: collapsed,
          currentBranch: currentBranch,
          onNavigate: onNavigate,
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavItem> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(56, 0, 56, 12),
      child: Container(
        height: 64,
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(42),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavButton(
                  item: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.selectedIcon : item.icon, color: color),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.branch,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Shell branch this destination navigates to (see [nav_branches]).
  final int branch;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
