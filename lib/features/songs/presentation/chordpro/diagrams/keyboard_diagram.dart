import 'package:flutter/material.dart';

/// Piano keyboard diagram highlighting the keys of the current voicing.
class KeyboardDiagram extends StatelessWidget {
  const KeyboardDiagram({
    super.key,
    required this.highlightKeys,
    required this.highlightColor,
    required this.whiteColor,
    required this.blackColor,
    required this.keyLineColor,
    required this.dotColor,
  });

  /// Semitone offsets from the leftmost drawn key (0 = C of the first octave).
  /// Keys outside the drawn range are ignored.
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

  /// Drawn size of the keyboard.
  static const Size size = Size(14 * _keyWidth + 2, _keyHeight + 4);

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
      size: size,
      painter: _KeyboardDiagramPainter(
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

class _KeyboardDiagramPainter extends CustomPainter {
  _KeyboardDiagramPainter({
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
    for (
      var idx = 0;
      idx < KeyboardDiagram._whiteKeySemitones.length;
      idx++
    ) {
      final semitone = KeyboardDiagram._whiteKeySemitones[idx];
      final highlighted = highlightKeys.contains(semitone);
      final x = idx * KeyboardDiagram._keyWidth + 1;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          2,
          KeyboardDiagram._keyWidth - 1,
          KeyboardDiagram._keyHeight,
        ),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = highlighted ? highlightColor : whiteColor,
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = keyLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      if (highlighted) {
        canvas.drawCircle(
          Offset(
            x + (KeyboardDiagram._keyWidth - 1) / 2,
            KeyboardDiagram._keyHeight - 8,
          ),
          2,
          Paint()..color = dotColor,
        );
      }
    }

    // Black keys.
    for (final semitone in KeyboardDiagram._blackKeySemitones) {
      final highlighted = highlightKeys.contains(semitone);
      final x = KeyboardDiagram._blackKeyX(semitone) + 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            2,
            KeyboardDiagram._blackWidth,
            KeyboardDiagram._blackHeight,
          ),
          const Radius.circular(1),
        ),
        Paint()
          ..color = highlighted ? highlightColor : blackColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardDiagramPainter old) =>
      old.highlightKeys != highlightKeys ||
      old.highlightColor != highlightColor ||
      old.whiteColor != whiteColor ||
      old.blackColor != blackColor ||
      old.keyLineColor != keyLineColor ||
      old.dotColor != dotColor;
}
