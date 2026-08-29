import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'shell.dart';

/// AppBar leading action for shell branch pages.
///
/// On phones it opens the navigation drawer (hamburger); on tablets it
/// collapses/expands the persistent sidebar, replacing the toggle button that
/// used to live inside the sidebar header.
class ShellLeadingButton extends ConsumerWidget {
  const ShellLeadingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isTablet = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;

    if (!isTablet) {
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: l10n.commonOpenDrawer,
        onPressed: () =>
            ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
      );
    }

    final collapsed = ref.watch(sidebarCollapsedProvider);
    return IconButton(
      icon: Icon(collapsed ? Icons.menu : Icons.menu_open),
      tooltip: collapsed ? l10n.commonOpenDrawer : l10n.commonCloseDrawer,
      onPressed: () =>
          ref.read(sidebarCollapsedProvider.notifier).state = !collapsed,
    );
  }
}
