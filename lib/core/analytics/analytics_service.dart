/// PostHog-backed analytics service for the Hosanna app.
///
/// Usage:
/// ```dart
/// await AnalyticsService.instance.init(apiKey: '...', host: '...');
/// await AnalyticsService.instance.track(const AppLaunched());
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_event.dart';

/// Singleton analytics service backed by PostHog.
///
/// All public methods are safe to call before [init] completes — they will
/// silently no-op. All calls are wrapped in try/catch so analytics failures
/// never propagate to the caller.
class AnalyticsService {
  AnalyticsService._();

  /// The shared singleton instance.
  static final AnalyticsService instance = AnalyticsService._();

  bool _initialized = false;

  /// Initialises PostHog with [apiKey] and [host].
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> init({required String apiKey, required String host}) async {
    if (_initialized) return;
    try {
      final config = PostHogConfig(apiKey)
        ..host = host
        ..captureApplicationLifecycleEvents = true
        ..debug = kDebugMode;
      await Posthog().setup(config);
      _initialized = true;
    } catch (e, st) {
      debugPrint('[Analytics] init error: $e\n$st');
    }
  }

  /// Identifies the signed-in user so all subsequent events are attributed.
  Future<void> identify(
    String userId, {
    String? email,
    String? name,
    String? orgId,
    String? orgName,
    String? role,
  }) async {
    try {
      await Posthog().identify(
        userId: userId,
        userProperties: {
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (orgId != null) 'org_id': orgId,
          if (orgName != null) 'org_name': orgName,
          if (role != null) 'role': role,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] identify error: $e');
    }
  }

  /// Resets the PostHog person — call on sign-out.
  Future<void> reset() async {
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('[Analytics] reset error: $e');
    }
  }

  /// Captures an [AnalyticsEvent] in PostHog.
  Future<void> track(AnalyticsEvent event) async {
    try {
      await Posthog().capture(
        eventName: event.name,
        properties: event.properties.isEmpty ? null : event.properties,
      );
    } catch (e) {
      debugPrint('[Analytics] track error (${event.name}): $e');
    }
  }

  /// Records a screen view in PostHog.
  Future<void> screen(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (e) {
      debugPrint('[Analytics] screen error ($screenName): $e');
    }
  }

  /// Returns whether the given feature flag is enabled for the current user.
  Future<bool> isFeatureEnabled(String flagKey) async {
    try {
      return await Posthog().isFeatureEnabled(flagKey) ?? false;
    } catch (e) {
      debugPrint('[Analytics] isFeatureEnabled error ($flagKey): $e');
      return false;
    }
  }

  /// Returns the value of the given feature flag (may be bool, String, etc.).
  Future<dynamic> getFeatureFlag(String flagKey) async {
    try {
      return await Posthog().getFeatureFlag(flagKey);
    } catch (e) {
      debugPrint('[Analytics] getFeatureFlag error ($flagKey): $e');
      return null;
    }
  }

  /// Reloads feature flags from PostHog.
  Future<void> reloadFeatureFlags() async {
    try {
      await Posthog().reloadFeatureFlags();
    } catch (e) {
      debugPrint('[Analytics] reloadFeatureFlags error: $e');
    }
  }

  /// Flushes queued events to PostHog immediately.
  Future<void> flush() async {
    try {
      await Posthog().flush();
    } catch (e) {
      debugPrint('[Analytics] flush error: $e');
    }
  }

  /// Opts the user out of (or back into) analytics data collection.
  void setEnabled(bool enabled) {
    try {
      if (enabled) {
        Posthog().optIn();
      } else {
        Posthog().optOut();
      }
    } catch (e) {
      debugPrint('[Analytics] setEnabled error: $e');
    }
  }

  /// Captures an error as an [AppErrorCaptured] event.
  ///
  /// The [stackTrace] is truncated to 2 000 characters to stay within
  /// PostHog's property size limits.
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    try {
      final stackStr = stackTrace?.toString();
      final truncated =
          stackStr != null && stackStr.length > 2000
              ? '${stackStr.substring(0, 2000)}…'
              : stackStr;
      await track(
        AppErrorCaptured(
          error: error.toString(),
          stackTrace: truncated,
          context: context,
        ),
      );
    } catch (e) {
      debugPrint('[Analytics] captureError failed: $e');
    }
  }
}
