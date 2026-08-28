import 'package:flutter/material.dart';

/// Guitar fretboard diagram (ported from the SVG in `@hosanna/shared`).
class GuitarDiagram extends StatelessWidget {
  const GuitarDiagram({
    super.key,
    required this.frets,
    this.fingers,
    this.barre,
    required this.dotColor,
    required this.lineColor,
    required this.textColor,
    required this.muteColor,
    required this.openColor,
  });

  final List<int> frets; // low-E to high-E; -1 = muted.
  final List<int>? fingers;
  final int? barre;
  final Color dotColor;
  final Color lineColor;
  final Color textColor;
  final Color muteColor;
  final Color openColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 110),
      painter: _GuitarDiagramPainter(
        frets: frets,
        fingers: fingers,
        barre: barre,
        dotColor: dotColor,
        lineColor: lineColor,
        textColor: textColor,
        muteColor: muteColor,
        openColor: openColor,
      ),
    );
  }
}

class _GuitarDiagramPainter extends CustomPainter {
  _GuitarDiagramPainter({
    required this.frets,
    required this.fingers,
    required this.barre,
    required this.dotColor,
    required this.lineColor,
    required this.textColor,
    required this.muteColor,
    required this.openColor,
  });

  final List<int> frets;
  final List<int>? fingers;
  final int? barre;
  final Color dotColor;
  final Color lineColor;
  final Color textColor;
  final Color muteColor;
  final Color openColor;

  static const int _numFrets = 4;

  double _stringX(int index) => 14 + index * 14;
  double _fretY(int index) => 22 + index * 20;

  int get _startFret {
    final max = frets.fold<int>(0, (a, b) => b > a ? b : a);
    if (max <= 4) return 1;
    final positive = frets.where((f) => f > 0);
    return positive.isEmpty ? 1 : positive.reduce((a, b) => a < b ? a : b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final startFret = _startFret;

    final nutPaint = Paint()
      ..color = lineColor
      ..strokeWidth = startFret == 1 ? 3.5 : 1.5;
    canvas.drawLine(
      Offset(_stringX(0), _fretY(0) - (startFret == 1 ? 3 : 0)),
      Offset(_stringX(5), _fretY(0) - (startFret == 1 ? 3 : 0)),
      nutPaint,
    );

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
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(_stringX(i), _fretY(0)),
        Offset(_stringX(i), _fretY(_numFrets)),
        stringPaint,
      );
    }

    final fretPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i <= _numFrets; i++) {
      canvas.drawLine(
        Offset(_stringX(0), _fretY(i)),
        Offset(_stringX(5), _fretY(i)),
        fretPaint,
      );
    }

    // Barre indicator.
    final barreFret = barre;
    if (barreFret != null) {
      final inWindow = barreFret - startFret;
      if (inWindow >= 0 && inWindow < _numFrets) {
        final y = _fretY(inWindow) + 10;
        final startStr = frets.indexOf(barreFret);
        if (startStr != -1) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              _stringX(startStr) - 4,
              y - 4,
              _stringX(5) - _stringX(startStr) + 8,
              8,
            ),
            const Radius.circular(4),
          );
          canvas.drawRRect(
            rect,
            Paint()..color = dotColor.withValues(alpha: 0.8),
          );
        }
      }
    }

    for (var stringIdx = 0; stringIdx < frets.length; stringIdx++) {
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
        continue;
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
        continue;
      }

      final inWindow = fret - startFret;
      if (inWindow >= 0 && inWindow < _numFrets) {
        final cx = _stringX(stringIdx);
        final cy = _fretY(inWindow) + 10;
        final finger = fingers != null && stringIdx < fingers!.length
            ? fingers![stringIdx]
            : 0;

        final barreFret = barre;
        final isBarred = barreFret != null &&
            fret == barreFret &&
            stringIdx >= frets.indexOf(barreFret);
        if (!isBarred) {
          canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = dotColor);
        }
        if (finger > 0) {
          _drawText(
            canvas,
            '$finger',
            Offset(cx, cy + 2.5),
            color: Colors.white,
            fontSize: 6.5,
            alignCenter: true,
            bold: true,
          );
        }
      }
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
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = alignEnd
        ? offset.dx - tp.width
        : alignCenter
            ? offset.dx - tp.width / 2
            : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GuitarDiagramPainter old) =>
      old.frets != frets ||
      old.barre != barre ||
      old.dotColor != dotColor ||
      old.lineColor != lineColor;
}

/// Piano keyboard diagram (ported from the SVG in `@hosanna/shared`).
class PianoDiagram extends StatelessWidget {
  const PianoDiagram({
    super.key,
    required this.highlightKeys,
    required this.highlightColor,
    required this.whiteColor,
    required this.blackColor,
    required this.keyLineColor,
    required this.dotColor,
  });

  final List<int> highlightKeys;
  final Color highlightColor;
  final Color whiteColor;
  final Color blackColor;
  final Color keyLineColor;
  final Color dotColor;

  static const List<int> _whiteKeySemitones = [
    0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23,
  ];
  static const List<int> _blackKeySemitones = [
    1, 3, 6, 8, 10, 13, 15, 18, 20, 22,
  ];

  static const double _keyWidth = 14;
  static const double _keyHeight = 56;
  static const double _blackWidth = 9;
  static const double _blackHeight = 34;

  static double _blackKeyX(int semitone) {
    final octave = semitone ~/ 12;
    final inOctave = semitone % 12;
    var whiteBefore = 0;
    if (inOctave == 1) {
      whiteBefore = 1;
    } else if (inOctave == 3) {
      whiteBefore = 2;
    } else if (inOctave == 6) {
      whiteBefore = 4;
    } else if (inOctave == 8) {
      whiteBefore = 5;
    } else if (inOctave == 10) {
      whiteBefore = 6;
    }
    final absoluteWhiteIndex = octave * 7 + whiteBefore;
    return absoluteWhiteIndex * _keyWidth - _blackWidth / 2;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(14 * _keyWidth + 2, _keyHeight + 4),
      painter: _PianoDiagramPainter(
        highlightKeys: highlightKeys,
        highlightColor: highlightColor,
        whiteColor: whiteColor,
        blackColor: blackColor,
        keyLineColor: keyLineColor,
        dotColor: dotColor,
      ),
    );
  }
}

class _PianoDiagramPainter extends CustomPainter {
  _PianoDiagramPainter({
    required this.highlightKeys,
    required this.highlightColor,
    required this.whiteColor,
    required this.blackColor,
    required this.keyLineColor,
    required this.dotColor,
  });

  final List<int> highlightKeys;
  final Color highlightColor;
  final Color whiteColor;
  final Color blackColor;
  final Color keyLineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    // White keys.
    for (var idx = 0; idx < PianoDiagram._whiteKeySemitones.length; idx++) {
      final st = PianoDiagram._whiteKeySemitones[idx];
      final highlighted = highlightKeys.contains(st);
      final x = idx * PianoDiagram._keyWidth + 1;
      final fill = highlighted ? highlightColor : whiteColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 2, PianoDiagram._keyWidth - 1, PianoDiagram._keyHeight),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 2, PianoDiagram._keyWidth - 1, PianoDiagram._keyHeight),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = keyLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      if (highlighted) {
        canvas.drawCircle(
          Offset(x + (PianoDiagram._keyWidth - 1) / 2, PianoDiagram._keyHeight - 8),
          2,
          Paint()..color = dotColor,
        );
      }
    }

    // Black keys.
    for (final st in PianoDiagram._blackKeySemitones) {
      final highlighted = highlightKeys.contains(st);
      final x = PianoDiagram._blackKeyX(st) + 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 2, PianoDiagram._blackWidth, PianoDiagram._blackHeight),
          const Radius.circular(1),
        ),
        Paint()
          ..color = highlighted ? highlightColor : blackColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PianoDiagramPainter old) =>
      old.highlightKeys != highlightKeys ||
      old.highlightColor != highlightColor;
}
