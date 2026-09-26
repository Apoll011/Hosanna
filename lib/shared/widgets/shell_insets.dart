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
