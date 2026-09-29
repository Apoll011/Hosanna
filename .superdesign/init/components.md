# Shared UI components — Hosanna

Framework: Flutter Material 3. Shared primitives live in `lib/shared/widgets/`.
Pages also use stock Material (`ListTile`, `AppBar`, `FilledButton`, `IconButton`).

## HosannaLogo
- Path: `lib/shared/widgets/hosanna_logo.dart`
- Description: Brand mark from `assets/logo.png` (rounded square); primary + music_note fallback
- Props: `size` (default 72), `borderRadius` (default 20)

```dart
import 'package:flutter/material.dart';

/// The Hosanna brand mark (rounded square logo) at a given [size].
class HosannaLogo extends StatelessWidget {
  const HosannaLogo({super.key, this.size = 72, this.borderRadius = 20});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // `Center` keeps the mark square even when a parent (e.g. a
    // `CrossAxisAlignment.stretch` Column) tries to stretch it horizontally.
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.music_note, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}

```

## EmptyState / ErrorState
- Path: `lib/shared/widgets/empty_state.dart`
- Description: Calm empty placeholder (primary tint) and error placeholder (error tint) with optional actions
- Props: icon, title, description?, primary/secondary labels+callbacks, scrollable

```dart
import 'package:flutter/material.dart';

/// Friendly empty / zero-data placeholder.
///
/// Visually distinct from [ErrorState]: soft primary tint, calm copy, and
/// optional actions that invite the next step (clear filters, sync) rather
/// than implying something broke.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.primaryIcon = Icons.filter_alt_off_outlined,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.scrollable = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final IconData primaryIcon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// When true, fills the parent and scrolls so it works inside a
  /// [RefreshIndicator] (always-scrollable physics).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = _EmptyStateBody(
      icon: icon,
      title: title,
      description: description,
      primaryIcon: primaryIcon,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
      tone: _EmptyTone.calm,
    );

    if (!scrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Failure placeholder — tinted with error colors and a clear retry path.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.description,
    this.retryLabel,
    this.onRetry,
    this.scrollable = false,
  });

  final String title;
  final String? description;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = _EmptyStateBody(
      icon: Icons.cloud_off_outlined,
      title: title,
      description: description,
      primaryIcon: Icons.refresh,
      primaryLabel: retryLabel,
      onPrimary: onRetry,
      tone: _EmptyTone.error,
    );

    if (!scrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: content),
        ),
      ),
    );
  }
}

enum _EmptyTone { calm, error }

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({
    required this.icon,
    required this.title,
    required this.tone,
    required this.primaryIcon,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? description;
  final IconData primaryIcon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final _EmptyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isError = tone == _EmptyTone.error;

    final circleColor = isError
        ? scheme.errorContainer
        : scheme.primaryContainer.withValues(alpha: 0.65);
    final iconColor =
        isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 24),
              if (isError)
                FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

```

## SyncStatusBanner
- Path: `lib/shared/widgets/sync_status_banner.dart`
- Description: Sync idle/syncing/synced/error/offline row with last-synced time
- Props: `compact` (bool)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/sync/sync_controller.dart';
import '../../l10n/generated/app_localizations.dart';

/// Compact sync status indicator: idle / syncing / synced / error / offline,
/// plus the last-synced timestamp and a manual sync affordance.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (IconData icon, Color color, String label) = switch (sync.status) {
      SyncStatus.syncing => (
          Icons.sync,
          theme.colorScheme.primary,
          l10n.syncSyncing
        ),
      SyncStatus.synced => (
          Icons.cloud_done_outlined,
          theme.colorScheme.primary,
          l10n.syncSynced
        ),
      SyncStatus.error => (
          Icons.cloud_off_outlined,
          theme.colorScheme.error,
          l10n.syncError
        ),
      SyncStatus.offline => (
          Icons.wifi_off,
          theme.colorScheme.tertiary,
          l10n.syncOffline
        ),
      SyncStatus.idle => (
          Icons.cloud_outlined,
          theme.colorScheme.onSurfaceVariant,
          l10n.syncSynced
        ),
    };

    final lastSynced = sync.lastSyncedAt == null
        ? l10n.syncNever
        : l10n.syncLastSynced(
            DateFormat.Hm(Localizations.localeOf(context).toString())
                .format(sync.lastSyncedAt!),
          );

    return Row(
      children: [
        if (sync.isSyncing)
          const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: compact ? 16 : 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            compact ? label : '$label · $lastSynced',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

```

## ShellLeadingButton
- Path: `lib/app/shell_leading_button.dart`
- Description: AppBar leading — opens drawer on phone; toggles sidebar collapse on tablet

```dart
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

```

## shellBottomContentPadding
- Path: `lib/shared/widgets/shell_insets.dart`
- Description: Bottom padding so lists clear the floating nav pill

```dart
import 'package:flutter/material.dart';

import '../../app/shell.dart';

/// Bottom padding so list/grid content clears the floating bottom nav.
///
/// The shell uses [Scaffold.extendBody] with a ~64px pill + SafeArea insets
/// (`shell.dart`). Without this padding, the last rows sit under the bar.
double shellBottomContentPadding(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  // Pill height (64) + outer SafeArea minimum bottom (12) + breathing room.
  const navClearance = 64.0 + 12.0 + 16.0;
  // On tablet the bar is overlaid the same way inside the content pane.
  final width = MediaQuery.sizeOf(context).width;
  final isPhone = width < kTabletBreakpoint;
  if (!isPhone) {
    return safeBottom + navClearance;
  }
  return safeBottom + navClearance;
}

```

## GoogleGLogo
- Path: `lib/shared/widgets/google_g_logo.dart`
- Description: Official multicolor Google G for social sign-in

```dart
import 'package:flutter/material.dart';

/// The multicolour Google "G" mark.
///
/// Drawn from Google's official 24×24 logo vectors so the mark keeps its
/// colours, shape and proportions (Google's branding guidelines forbid
/// recolouring, restyling or distorting it) without shipping a raster asset.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 18});

  /// Edge length of the (square) mark.
  final double size;

  /// Google brand colours.
  static const Color blue = Color(0xFF4285F4);
  static const Color green = Color(0xFF34A853);
  static const Color yellow = Color(0xFFFBBC05);
  static const Color red = Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _GoogleGPainter(),
        isComplex: false,
        size: Size.square(size),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  /// Coordinate space of the source logo.
  static const double _viewBox = 24;

  static final Path _bluePath = Path()
    ..moveTo(22.56, 12.25)
    ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.00)
    ..lineTo(12.00, 10.00)
    ..lineTo(12.00, 14.26)
    ..lineTo(17.92, 14.26)
    ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
    ..lineTo(15.71, 20.34)
    ..lineTo(19.28, 20.34)
    ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
    ..close();

  static final Path _greenPath = Path()
    ..moveTo(12.00, 23.00)
    ..cubicTo(14.97, 23.00, 17.46, 22.02, 19.28, 20.34)
    ..lineTo(15.71, 17.57)
    ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.00, 18.63)
    ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
    ..lineTo(2.18, 14.10)
    ..lineTo(2.18, 16.94)
    ..cubicTo(3.99, 20.53, 7.70, 23.00, 12.00, 23.00)
    ..close();

  static final Path _yellowPath = Path()
    ..moveTo(5.84, 14.09)
    ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.00)
    ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
    ..lineTo(5.84, 7.07)
    ..lineTo(2.18, 7.07)
    ..cubicTo(1.43, 8.55, 1.00, 10.22, 1.00, 12.00)
    ..cubicTo(1.00, 13.78, 1.43, 15.45, 2.18, 16.93)
    ..lineTo(5.03, 14.71)
    ..lineTo(5.84, 14.09)
    ..close();

  static final Path _redPath = Path()
    ..moveTo(12.00, 5.38)
    ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
    ..lineTo(19.36, 3.87)
    ..cubicTo(17.45, 2.09, 14.97, 1.00, 12.00, 1.00)
    ..cubicTo(7.70, 1.00, 3.99, 3.47, 2.18, 7.07)
    ..lineTo(5.84, 9.91)
    ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.00, 5.38)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox, size.height / _viewBox);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawPath(_bluePath, paint..color = GoogleGLogo.blue);
    canvas.drawPath(_greenPath, paint..color = GoogleGLogo.green);
    canvas.drawPath(_yellowPath, paint..color = GoogleGLogo.yellow);
    canvas.drawPath(_redPath, paint..color = GoogleGLogo.red);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}

```

## ComingSoonPage
- Path: `lib/shared/widgets/coming_soon_page.dart`
- Description: Legacy placeholder scaffold

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Placeholder screen for features whose logic ships in a later phase
/// (metronome, circle of fifths, PDF export).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(l10n.comingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```
