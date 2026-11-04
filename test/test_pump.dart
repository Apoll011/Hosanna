import 'package:flutter_test/flutter_test.dart';

/// Advances frames without waiting for infinite animations
/// (e.g. [CircularProgressIndicator]) that make [WidgetTester.pumpAndSettle]
/// hang forever.
Future<void> pumpFrames(
  WidgetTester tester, [
  Duration total = const Duration(milliseconds: 500),
]) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}
