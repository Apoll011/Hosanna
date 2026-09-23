import 'package:flutter/material.dart';

/// The multicolour Google "G" mark.
///
/// Drawn from Google's official 24×24 logo vectors so the mark keeps its
/// colours, shape and proportions (Google's branding guidelines forbid
/// recolouring, restyling or distorting it) without shipping a raster asset.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 18});

  /// Edge length of the (square) mark.
  final double size;

  /// Google brand colours.
  static const Color blue = Color(0xFF4285F4);
  static const Color green = Color(0xFF34A853);
  static const Color yellow = Color(0xFFFBBC05);
  static const Color red = Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _GoogleGPainter(),
        isComplex: false,
        size: Size.square(size),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  /// Coordinate space of the source logo.
  static const double _viewBox = 24;

  static final Path _bluePath = Path()
    ..moveTo(22.56, 12.25)
    ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.00)
    ..lineTo(12.00, 10.00)
    ..lineTo(12.00, 14.26)
    ..lineTo(17.92, 14.26)
    ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
    ..lineTo(15.71, 20.34)
    ..lineTo(19.28, 20.34)
    ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
    ..close();

  static final Path _greenPath = Path()
    ..moveTo(12.00, 23.00)
    ..cubicTo(14.97, 23.00, 17.46, 22.02, 19.28, 20.34)
    ..lineTo(15.71, 17.57)
    ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.00, 18.63)
    ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
    ..lineTo(2.18, 14.10)
    ..lineTo(2.18, 16.94)
    ..cubicTo(3.99, 20.53, 7.70, 23.00, 12.00, 23.00)
    ..close();

  static final Path _yellowPath = Path()
    ..moveTo(5.84, 14.09)
    ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.00)
    ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
    ..lineTo(5.84, 7.07)
    ..lineTo(2.18, 7.07)
    ..cubicTo(1.43, 8.55, 1.00, 10.22, 1.00, 12.00)
    ..cubicTo(1.00, 13.78, 1.43, 15.45, 2.18, 16.93)
    ..lineTo(5.03, 14.71)
    ..lineTo(5.84, 14.09)
    ..close();

  static final Path _redPath = Path()
    ..moveTo(12.00, 5.38)
    ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
    ..lineTo(19.36, 3.87)
    ..cubicTo(17.45, 2.09, 14.97, 1.00, 12.00, 1.00)
    ..cubicTo(7.70, 1.00, 3.99, 3.47, 2.18, 7.07)
    ..lineTo(5.84, 9.91)
    ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.00, 5.38)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox, size.height / _viewBox);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawPath(_bluePath, paint..color = GoogleGLogo.blue);
    canvas.drawPath(_greenPath, paint..color = GoogleGLogo.green);
    canvas.drawPath(_yellowPath, paint..color = GoogleGLogo.yellow);
    canvas.drawPath(_redPath, paint..color = GoogleGLogo.red);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
