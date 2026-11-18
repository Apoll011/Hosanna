/// Riverpod providers for the analytics layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Exposes [AnalyticsService.instance] as a Riverpod provider.
///
/// Widgets or other providers that want to call analytics helpers can watch or
/// read this instead of using the singleton directly.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService.instance,
);

/// A family provider that evaluates the named PostHog feature flag.
///
/// Example:
/// ```dart
/// final value = await ref.watch(featureFlagProvider('my_flag').future);
/// ```
final featureFlagProvider = FutureProvider.family<dynamic, String>(
  (ref, flagKey) async {
    return AnalyticsService.instance.getFeatureFlag(flagKey);
  },
);

/// An [AsyncNotifier] that holds the latest feature-flag reload timestamp.
///
/// Invalidating this notifier triggers a fresh [reloadFeatureFlags] call and
/// forces all [featureFlagProvider] watchers to re-evaluate.
class FeatureFlagReloaderNotifier extends AsyncNotifier<DateTime> {
  @override
  Future<DateTime> build() async {
    await AnalyticsService.instance.reloadFeatureFlags();
    return DateTime.now();
  }

  /// Reloads feature flags from PostHog and updates the timestamp.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await AnalyticsService.instance.reloadFeatureFlags();
    state = AsyncValue.data(DateTime.now());
  }
}

/// Provider for [FeatureFlagReloaderNotifier].
final featureFlagReloaderProvider =
    AsyncNotifierProvider<FeatureFlagReloaderNotifier, DateTime>(
      FeatureFlagReloaderNotifier.new,
    );
