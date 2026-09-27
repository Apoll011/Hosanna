import 'package:flutter/material.dart';

/// Fretboard diagram for any fretted instrument (guitar, ukulele, …).
///
/// The diagram adapts to [frets]`.length` strings, so supporting a new fretted
/// instrument needs no widget changes.
class FrettedDiagram extends StatelessWidget {
  const FrettedDiagram({
    super.key,
    required this.frets,
    this.fingers,
    this.barre,
    this.capo = 0,
    this.maxFrets = 4,
    this.showFingerNumbers = true,
    required this.dotColor,
    required this.lineColor,
    required this.textColor,
    required this.muteColor,
    required this.openColor,
    this.capoColor = const Color(0xFFB45309),
  });

  /// Per-string frets in diagram order (leftmost string first).
  /// `-1` = muted, `0` = open.
  final List<int> frets;
  final List<int>? fingers;

  /// Fret number the barre sits on, when any.
  final int? barre;

  /// Capo fret (0 = none). When set, the nut is drawn as a capo clamp with the
  /// fret number — shapes are already relative to the capo as nut.
  final int capo;

  /// Number of fret rows drawn.
  final int maxFrets;

  /// Whether to paint finger numbers inside the fretting dots.
  final bool showFingerNumbers;

  final Color dotColor;
  final Color lineColor;
  final Color textColor;
  final Color muteColor;
  final Color openColor;
  final Color capoColor;

  static const double _stringSpacing = 14;
  static const double _fretSpacing = 20;
  static const double _topMargin = 22;
  static const double _leftMargin = 18;
  static const double _rightMargin = 16;

  /// Width needed to draw [stringCount] strings.
  static double widthFor(int stringCount) =>
      _leftMargin + (stringCount - 1).clamp(0, 12) * _stringSpacing + _rightMargin;

  /// Height needed to draw [maxFrets] fret rows.
  static double heightFor(int maxFrets) =>
      _topMargin + maxFrets * _fretSpacing + 8;

  @override
  Widget build(BuildContext context) {
    final stringCount = frets.isEmpty ? 6 : frets.length;
    return CustomPaint(
      size: Size(widthFor(stringCount), heightFor(maxFrets)),
      painter: _FrettedDiagramPainter(
        frets: frets,
        fingers: fingers,
        barre: barre,
        capo: capo,
        maxFrets: maxFrets,
        showFingerNumbers: showFingerNumbers,
        dotColor: dotColor,
        lineColor: lineColor,
        textColor: textColor,
        muteColor: muteColor,
        openColor: openColor,
        capoColor: capoColor,
      ),
    );
  }
}

class _FrettedDiagramPainter extends CustomPainter {
  _FrettedDiagramPainter({
    required this.frets,
    required this.fingers,
    required this.barre,
    required this.capo,
    required this.maxFrets,
    required this.showFingerNumbers,
    required this.dotColor,
    required this.lineColor,
    required this.textColor,
    required this.muteColor,
    required this.openColor,
    required this.capoColor,
  });

  final List<int> frets;
  final List<int>? fingers;
  final int? barre;
  final int capo;
  final int maxFrets;
  final bool showFingerNumbers;
  final Color dotColor;
  final Color lineColor;
  final Color textColor;
  final Color muteColor;
  final Color openColor;
  final Color capoColor;

  int get _stringCount => frets.length;

  double _stringX(int index) =>
      FrettedDiagram._leftMargin + index * FrettedDiagram._stringSpacing;

  double _fretY(int index) =>
      FrettedDiagram._topMargin + index * FrettedDiagram._fretSpacing;

  /// First fret shown: 1 for open-position shapes, otherwise the lowest
  /// fingered fret so the shape fits the window.
  int get _startFret {
    var max = 0;
    for (final fret in frets) {
      if (fret > max) max = fret;
    }
    if (max <= maxFrets) return 1;

    var lowest = max;
    for (final fret in frets) {
      if (fret > 0 && fret < lowest) lowest = fret;
    }
    return lowest < 1 ? 1 : lowest;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_stringCount == 0) return;
    final lastString = _stringCount - 1;
    final startFret = _startFret;
    final hasCapo = capo > 0 && startFret == 1;

    // Nut — when a capo is active the nut becomes the capo clamp (CifraClub).
    if (hasCapo) {
      _paintCapo(canvas, lastString);
    } else {
      final nutOffset = startFret == 1 ? 3.0 : 0.0;
      canvas.drawLine(
        Offset(_stringX(0), _fretY(0) - nutOffset),
        Offset(_stringX(lastString), _fretY(0) - nutOffset),
        Paint()
          ..color = lineColor
          ..strokeWidth = startFret == 1 ? 3.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    if (startFret > 1) {
      _drawText(
        canvas,
        '$startFretª',
        Offset(_stringX(0) - 4, _fretY(0) + 12),
        color: textColor,
        fontSize: 8,
        alignEnd: true,
      );
    }

    final stringPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var i = 0; i < _stringCount; i++) {
      canvas.drawLine(
        Offset(_stringX(i), _fretY(0)),
        Offset(_stringX(i), _fretY(maxFrets)),
        stringPaint,
      );
    }

    final fretPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i <= maxFrets; i++) {
      canvas.drawLine(
        Offset(_stringX(0), _fretY(i)),
        Offset(_stringX(lastString), _fretY(i)),
        fretPaint,
      );
    }

    _paintBarre(canvas, startFret);

    for (var stringIdx = 0; stringIdx < _stringCount; stringIdx++) {
      _paintStringMarker(canvas, stringIdx, startFret);
    }
  }

  /// Capo clamp across the nut with the fret number centred on the bar.
  void _paintCapo(Canvas canvas, int lastString) {
    final left = _stringX(0) - 5;
    final right = _stringX(lastString) + 5;
    final cy = _fretY(0) - 3;
    const height = 7.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, cy - height / 2, right, cy + height / 2),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(rect, Paint()..color = capoColor);

    // Small "wing" notches at each end (suggests a capo clamp).
    final wingPaint = Paint()..color = capoColor.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(left + 1, cy), 3.5, wingPaint);
    canvas.drawCircle(Offset(right - 1, cy), 3.5, wingPaint);

    _drawText(
      canvas,
      '$capo',
      Offset((left + right) / 2, cy),
      color: Colors.white,
      fontSize: 7,
      alignCenter: true,
      bold: true,
    );

    // Capo fret label to the left of the clamp.
    _drawText(
      canvas,
      'C$capo',
      Offset(_stringX(0) - 5, cy - 10),
      color: capoColor,
      fontSize: 7,
      alignEnd: true,
      bold: true,
    );
  }

  void _paintBarre(Canvas canvas, int startFret) {
    final barreFret = barre;
    if (barreFret == null) return;

    final row = barreFret - startFret;
    if (row < 0 || row >= maxFrets) return;

    final startString = frets.indexOf(barreFret);
    if (startString == -1) return;

    final y = _fretY(row) + FrettedDiagram._fretSpacing / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _stringX(startString) - 4,
        y - 4,
        _stringX(_stringCount - 1) - _stringX(startString) + 8,
        8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = dotColor.withValues(alpha: 0.8));
  }

  void _paintStringMarker(Canvas canvas, int stringIdx, int startFret) {
    final fret = frets[stringIdx];

    if (fret == -1) {
      _drawText(
        canvas,
        '×',
        Offset(_stringX(stringIdx), 12),
        color: muteColor,
        fontSize: 10,
        alignCenter: true,
      );
      return;
    }

    if (fret == 0) {
      canvas.drawCircle(
        Offset(_stringX(stringIdx), 10),
        2,
        Paint()
          ..color = openColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      return;
    }

    final row = fret - startFret;
    if (row < 0 || row >= maxFrets) return;

    final cx = _stringX(stringIdx);
    final cy = _fretY(row) + FrettedDiagram._fretSpacing / 2;
    final finger =
        fingers != null && stringIdx < fingers!.length ? fingers![stringIdx] : 0;

    final barreFret = barre;
    final isBarred =
        barreFret != null &&
        fret == barreFret &&
        stringIdx >= frets.indexOf(barreFret);
    if (!isBarred) {
      canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = dotColor);
    }
    if (showFingerNumbers && finger > 0) {
      // Centre the digit in the bubble (no vertical nudge).
      _drawText(
        canvas,
        '$finger',
        Offset(cx, cy),
        color: Colors.white,
        fontSize: 7,
        alignCenter: true,
        bold: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    bool alignCenter = false,
    bool alignEnd = false,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = alignEnd
        ? offset.dx - tp.width
        : alignCenter
            ? offset.dx - tp.width / 2
            : offset.dx;
    final dy = offset.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _FrettedDiagramPainter old) =>
      old.frets != frets ||
      old.fingers != fingers ||
      old.barre != barre ||
      old.capo != capo ||
      old.maxFrets != maxFrets ||
      old.showFingerNumbers != showFingerNumbers ||
      old.dotColor != dotColor ||
      old.lineColor != lineColor ||
      old.textColor != textColor ||
      old.muteColor != muteColor ||
      old.openColor != openColor ||
      old.capoColor != capoColor;
}
