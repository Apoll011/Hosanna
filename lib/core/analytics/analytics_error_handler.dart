/// Flutter error handler helpers that forward uncaught errors to PostHog.
library;

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Sets up global Flutter and platform error handlers to capture uncaught
/// exceptions via [AnalyticsService.captureError].
///
/// Call once from [main], before [runApp].
class AnalyticsErrorHandler {
  const AnalyticsErrorHandler._();

  /// Installs [FlutterError.onError] and [PlatformDispatcher.instance.onError]
  /// handlers that forward exceptions to PostHog.
  ///
  /// The original [FlutterError.onError] handler is preserved and called after
  /// the analytics capture, so framework error reporting is unaffected.
  static void setupFlutterErrorHandling() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      AnalyticsService.instance.captureError(
        details.exception,
        stackTrace: details.stack,
        context: 'FlutterError',
      );
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AnalyticsService.instance.captureError(
        error,
        stackTrace: stack,
        context: 'PlatformDispatcher',
      );
      return false;
    };
  }
}
