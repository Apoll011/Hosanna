import 'package:flutter/material.dart';

import '../../../domain/chordpro/instruments/instruments.dart';
import 'diagram_colors.dart';
import 'fretted_diagram.dart';
import 'keyboard_diagram.dart';

export 'diagram_colors.dart';
export 'fretted_diagram.dart';
export 'fretted_diagram_layout.dart';
export 'keyboard_diagram.dart';

/// Renders a chord fingering with the diagram that matches its type.
///
/// Dispatching on the [InstrumentFingering] subtype means new fretted or
/// keyboard instruments render automatically; only a genuinely new fingering
/// family needs a case added here.
class InstrumentDiagram extends StatelessWidget {
  const InstrumentDiagram({
    super.key,
    required this.fingering,
    this.maxFrets = 4,
    this.capo = 0,
    this.showFingerNumbers = true,
    this.showCapoMarker = true,
    this.showStringLabels = true,
  });

  final InstrumentFingering? fingering;

  /// Fret rows drawn for fretted instruments.
  final int maxFrets;

  /// Capo fret for fretted diagrams (0 = none). Only drawn when
  /// [showCapoMarker] is true and the instrument supports capo.
  final int capo;

  /// Whether fretted dots show finger numbers.
  final bool showFingerNumbers;

  /// Whether to paint the capo clamp on fretted diagrams when [capo] > 0.
  final bool showCapoMarker;

  /// Whether fretted diagrams label open-string names.
  final bool showStringLabels;

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
          capo: showCapoMarker ? capo : 0,
          maxFrets: maxFrets,
          showFingerNumbers: showFingerNumbers,
          stringNames: fretted.stringNames,
          showStringLabels: showStringLabels,
          dotColor: colors.primary,
          lineColor: colors.line,
          textColor: colors.text,
          muteColor: colors.mute,
          openColor: colors.open,
          capoColor: colors.capo,
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
