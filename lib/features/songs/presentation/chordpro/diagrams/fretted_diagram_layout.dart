/// Geometry for a fretted chord diagram that adapts to string count.
///
/// Four-string (ukulele) diagrams get slightly wider spacing; seven-string
/// packs a bit tighter so the chord roll still fits.
class FrettedDiagramLayout {
  const FrettedDiagramLayout({
    required this.stringCount,
    required this.maxFrets,
    required this.showStringLabels,
  });

  final int stringCount;
  final int maxFrets;
  final bool showStringLabels;

  double get stringSpacing {
    if (stringCount <= 4) return 16;
    if (stringCount >= 7) return 12;
    return 14;
  }

  double get fretSpacing => stringCount <= 4 ? 22.0 : 20.0;

  double get topMargin => 22;

  double get leftMargin => 18;

  double get rightMargin => 16;

  double get bottomMargin => showStringLabels ? 16.0 : 8.0;

  double get width =>
      leftMargin + (stringCount - 1).clamp(0, 12) * stringSpacing + rightMargin;

  double get height => topMargin + maxFrets * fretSpacing + bottomMargin;

  double stringX(int index) => leftMargin + index * stringSpacing;

  double fretY(int index) => topMargin + index * fretSpacing;
}
