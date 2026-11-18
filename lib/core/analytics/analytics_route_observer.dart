/// Navigator observer that records screen views in PostHog via [AnalyticsService].
library;

import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// A [NavigatorObserver] that calls [AnalyticsService.screen] on every
/// route push, pop, or replace so PostHog has an accurate page-view trail.
class AnalyticsRouteObserver extends NavigatorObserver {
  /// Extracts the route name from [settings], preferring [RouteSettings.name].
  String? _routeName(Route<dynamic>? route) {
    if (route == null) return null;
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  void _record(String? name) {
    if (name == null || name.isEmpty) return;
    AnalyticsService.instance.screen(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(_routeName(route));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _record(_routeName(newRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Record the route we're returning to, not the one being popped.
    _record(_routeName(previousRoute));
  }
}
