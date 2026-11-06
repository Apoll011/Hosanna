import 'package:flutter/material.dart';

/// Bottom padding so list/grid content clears the floating bottom nav.
///
/// The shell uses [Scaffold.extendBody] with a ~64px pill + SafeArea insets
/// (`shell.dart`). Without this padding, the last rows sit under the bar.
double shellBottomContentPadding(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  // Pill height (64) + outer SafeArea minimum bottom (12) + breathing room.
  // Matches [kTabletBreakpoint] in shell.dart (kept local to avoid cycles).
  const navClearance = 64.0 + 12.0 + 16.0;
  return safeBottom + navClearance;
}

/// Reports how much of the shell body is covered by the floating nav pill.
///
/// Empty/error states read this so they can optically center in the visible
/// area above the pill (geometric center looks too low to the eye).
class ShellOpticalInsets extends InheritedWidget {
  const ShellOpticalInsets({
    super.key,
    required this.bottomNavOverlay,
    required super.child,
  });

  /// Extra bottom inset occupied/overlaid by the floating nav, or 0 when hidden.
  final double bottomNavOverlay;

  static double bottomOverlayOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ShellOpticalInsets>();
    return scope?.bottomNavOverlay ?? 0;
  }

  @override
  bool updateShouldNotify(ShellOpticalInsets oldWidget) =>
      bottomNavOverlay != oldWidget.bottomNavOverlay;
}
