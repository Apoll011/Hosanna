import 'package:flutter/material.dart';

import '../../../domain/chordpro/instruments/instruments.dart';
import 'fretted_diagram.dart';
import 'keyboard_diagram.dart';

/// Theme-derived colors shared by every chord diagram.
class DiagramColors {
  const DiagramColors({
    required this.primary,
    required this.line,
    required this.text,
    required this.white,
    required this.black,
    required this.open,
    required this.mute,
  });

  final Color primary;
  final Color line;
  final Color text;
  final Color white;
  final Color black;
  final Color open;
  final Color mute;

  static DiagramColors of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DiagramColors(
      primary: theme.colorScheme.primary,
      line: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
      text: theme.colorScheme.onSurface,
      white: isDark ? const Color(0xFF27272A) : Colors.white,
      black: isDark ? const Color(0xFF09090B) : const Color(0xFF27272A),
      open: const Color(0xFF10B981),
      mute: theme.colorScheme.error,
    );
  }
}

/// Renders a chord fingering with the diagram that matches its type.
///
/// Dispatching on the [InstrumentFingering] subtype means new fretted or
/// keyboard instruments render automatically; only a genuinely new fingering
/// family needs a case added here.
class InstrumentDiagram extends StatelessWidget {
  const InstrumentDiagram({super.key, required this.fingering, this.maxFrets = 4});

  final InstrumentFingering? fingering;

  /// Fret rows drawn for fretted instruments.
  final int maxFrets;

  @override
  Widget build(BuildContext context) {
    final fingering = this.fingering;
    if (fingering == null) {
      // Plain text rather than a centered box: the diagram is often placed in
      // horizontally-unbounded rows where an expanding widget cannot lay out.
      return Text(
        '—',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }

    final colors = DiagramColors.of(context);
    return switch (fingering) {
      FrettedFingering fretted => FrettedDiagram(
        frets: fretted.frets,
        fingers: fretted.fingers,
        barre: fretted.barre,
        maxFrets: maxFrets,
        dotColor: colors.primary,
        lineColor: colors.line,
        textColor: colors.text,
        muteColor: colors.mute,
        openColor: colors.open,
      ),
      KeyboardFingering keyboard => KeyboardDiagram(
        highlightKeys: keyboard.highlightKeys,
        highlightColor: colors.primary,
        whiteColor: colors.white,
        blackColor: colors.black,
        keyLineColor: colors.line,
        dotColor: colors.primary,
      ),
    };
  }
}
