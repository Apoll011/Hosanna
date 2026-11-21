import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServiceElementMeta {
  const ServiceElementMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

ServiceElementMeta serviceElementMeta(
  AppLocalizations l10n,
  ColorScheme colors,
  String type,
) {
  return switch (type) {
    'song' => ServiceElementMeta(
      l10n.servicesElementSong,
      LucideIcons.music,
      colors.primary,
    ),
    'welcome' => ServiceElementMeta(
      l10n.servicesElementWelcome,
      LucideIcons.hand,
      colors.secondary,
    ),
    'scripture' => ServiceElementMeta(
      l10n.servicesElementScripture,
      LucideIcons.bookOpen,
      colors.tertiary,
    ),
    'message' => ServiceElementMeta(
      l10n.servicesElementMessage,
      LucideIcons.messageSquare,
      colors.error,
    ),
    'announcement' => ServiceElementMeta(
      l10n.servicesElementAnnouncement,
      LucideIcons.megaphone,
      colors.primary,
    ),
    _ => ServiceElementMeta(
      l10n.servicesElementDefault,
      LucideIcons.tag,
      colors.onSurfaceVariant,
    ),
  };
}

/// Formats a duration in seconds as `MM:SS` (hours fold into minutes).
String formatServiceDuration(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Cumulative start/end windows for each element, treating [ServiceElement.duration]
/// as seconds. Missing or zero duration contributes 0 length.
class ElementTimeWindow {
  const ElementTimeWindow({
    required this.startSeconds,
    required this.endSeconds,
    required this.hasDuration,
  });

  final int startSeconds;
  final int endSeconds;
  final bool hasDuration;

  String get label =>
      '${formatServiceDuration(startSeconds)} - ${formatServiceDuration(endSeconds)}';
}

List<ElementTimeWindow> computeElementTimeWindows(
  Iterable<int?> durations,
) {
  var cursor = 0;
  final out = <ElementTimeWindow>[];
  for (final raw in durations) {
    final has = raw != null && raw > 0;
    final length = has ? raw : 0;
    final start = cursor;
    final end = cursor + length;
    out.add(
      ElementTimeWindow(
        startSeconds: start,
        endSeconds: end,
        hasDuration: has,
      ),
    );
    cursor = end;
  }
  return out;
}
