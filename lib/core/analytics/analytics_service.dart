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
  bool _enabled = false;
  String? _apiKey;
  String? _host;

  /// Converts a [Map<String, dynamic>] to [Map<String, Object>] as required
  /// by the PostHog Flutter API (removes null values).
  static Map<String, Object>? _toPostHogMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    final result = <String, Object>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value != null) result[entry.key] = value as Object;
    }
    return result.isEmpty ? null : result;
  }

  /// Initialises PostHog with [apiKey] and [host].
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> init({required String apiKey, required String host}) async {
    _apiKey = apiKey;
    _host = host;
    if (_initialized) return;
    try {
      final config = PostHogConfig(apiKey)
        ..host = host
        ..captureApplicationLifecycleEvents = false
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
    if (!_enabled) return;
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
    if (!_enabled) return;
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('[Analytics] reset error: $e');
    }
  }

  /// Captures an [AnalyticsEvent] in PostHog.
  Future<void> track(AnalyticsEvent event) async {
    if (!_enabled) return;
    try {
      await Posthog().capture(
        eventName: event.name,
        properties: _toPostHogMap(event.properties),
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
    if (!_enabled) return;
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: _toPostHogMap(properties),
      );
    } catch (e) {
      debugPrint('[Analytics] screen error ($screenName): $e');
    }
  }

  /// Returns whether the given feature flag is enabled for the current user.
  Future<bool> isFeatureEnabled(String flagKey) async {
    if (!_enabled) return false;
    try {
      return await Posthog().isFeatureEnabled(flagKey);
    } catch (e) {
      debugPrint('[Analytics] isFeatureEnabled error ($flagKey): $e');
      return false;
    }
  }

  /// Returns the value of the given feature flag (may be bool, String, etc.).
  Future<dynamic> getFeatureFlag(String flagKey) async {
    if (!_enabled) return null;
    try {
      return await Posthog().getFeatureFlag(flagKey);
    } catch (e) {
      debugPrint('[Analytics] getFeatureFlag error ($flagKey): $e');
      return null;
    }
  }

  /// Reloads feature flags from PostHog.
  Future<void> reloadFeatureFlags() async {
    if (!_enabled) return;
    try {
      await Posthog().reloadFeatureFlags();
    } catch (e) {
      debugPrint('[Analytics] reloadFeatureFlags error: $e');
    }
  }

  /// Flushes queued events to PostHog immediately.
  Future<void> flush() async {
    if (!_enabled) return;
    try {
      await Posthog().flush();
    } catch (e) {
      debugPrint('[Analytics] flush error: $e');
    }
  }

  /// Opts the user out of (or back into) analytics data collection.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      if (enabled) {
        if (!_initialized && _apiKey != null && _host != null) {
          await init(apiKey: _apiKey!, host: _host!);
        }
        if (_initialized) await Posthog().optIn();
      } else if (_initialized) {
        await Posthog().optOut();
        await Posthog().reset();
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
