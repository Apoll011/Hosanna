import 'package:flutter/services.dart';

/// What a pedal Next/Prev press should do on the stage reader.
enum PedalActionMode {
  /// Same as the floating prev/next controls (songs / service items).
  navigateSongs,

  /// Scroll ~one viewport; advance song only at the top/bottom edge.
  scrollPage,
}

/// Named key layouts for common Bluetooth HID page-turners.
enum PedalPreset {
  /// Broad HID defaults used by many generic pedals.
  universal,

  /// AirTurn-style left/right + PageUp/PageDown.
  airTurn,

  /// iRig BlueTurn-style up/down arrows.
  blueTurn,

  /// Donner / generic dual-button left/right.
  donner,

  /// User-picked LogicalKeyboardKey ids.
  custom,
}

/// Resolved Next/Prev key sets for the active preset.
class PedalKeyBindings {
  const PedalKeyBindings({required this.next, required this.prev});

  final Set<LogicalKeyboardKey> next;
  final Set<LogicalKeyboardKey> prev;

  bool isNext(LogicalKeyboardKey key) => next.contains(key);
  bool isPrev(LogicalKeyboardKey key) => prev.contains(key);
}

PedalKeyBindings resolvePedalBindings({
  required PedalPreset preset,
  int? customNextKeyId,
  int? customPrevKeyId,
}) {
  switch (preset) {
    case PedalPreset.universal:
      return PedalKeyBindings(
        next: {
          LogicalKeyboardKey.pageDown,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.mediaTrackNext,
        },
        prev: {
          LogicalKeyboardKey.pageUp,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.mediaTrackPrevious,
        },
      );
    case PedalPreset.airTurn:
      return PedalKeyBindings(
        next: {
          LogicalKeyboardKey.pageDown,
          LogicalKeyboardKey.arrowRight,
        },
        prev: {
          LogicalKeyboardKey.pageUp,
          LogicalKeyboardKey.arrowLeft,
        },
      );
    case PedalPreset.blueTurn:
      return PedalKeyBindings(
        next: {LogicalKeyboardKey.arrowDown},
        prev: {LogicalKeyboardKey.arrowUp},
      );
    case PedalPreset.donner:
      return PedalKeyBindings(
        next: {
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.mediaTrackNext,
        },
        prev: {
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.mediaTrackPrevious,
        },
      );
    case PedalPreset.custom:
      return PedalKeyBindings(
        next: {
          if (customNextKeyId != null) LogicalKeyboardKey(customNextKeyId),
        },
        prev: {
          if (customPrevKeyId != null) LogicalKeyboardKey(customPrevKeyId),
        },
      );
  }
}

PedalPreset pedalPresetFromName(String? name) {
  return PedalPreset.values.firstWhere(
    (p) => p.name == name,
    orElse: () => PedalPreset.universal,
  );
}

PedalActionMode pedalActionModeFromName(String? name) {
  return PedalActionMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => PedalActionMode.navigateSongs,
  );
}

String describeLogicalKey(LogicalKeyboardKey key) {
  final label = key.keyLabel.trim();
  if (label.isNotEmpty) return label;
  final debug = key.debugName;
  if (debug != null && debug.isNotEmpty) return debug;
  return '0x${key.keyId.toRadixString(16)}';
}
