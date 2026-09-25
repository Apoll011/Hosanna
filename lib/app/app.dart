import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_controller.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/notifications/presentation/foreground_notification_listener.dart';
import '../features/notifications/presentation/notification_consent_gate.dart';
import '../l10n/generated/app_localizations.dart';
import 'launcher_links.dart';
import 'providers.dart';
import 'router.dart';
import 'settings_controller.dart';
import 'theme.dart';

class HosannaApp extends ConsumerStatefulWidget {
  const HosannaApp({super.key});

  @override
  ConsumerState<HosannaApp> createState() => _HosannaAppState();
}

class _HosannaAppState extends ConsumerState<HosannaApp>
    with WidgetsBindingObserver {
  ProviderSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _launcherLinks;
  StreamSubscription<String>? _notificationTaps;
  ProviderContainer? _container;

  /// Root messenger used to surface foreground FCM messages in-app.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Launcher shortcut target waiting for the session/organization to resolve.
  String? _pendingLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured once so deferred callbacks can read providers without touching
    // the (possibly deactivated) element tree via `ref`.
    _container ??= ProviderScope.containerOf(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial sync whenever an active organization first becomes available
    // (covers both launch-with-cache and post-sign-in). Registered here via
    // `listenManual` (not `ref.listen` in `build`) so the callback cannot fire
    // during the build phase or after the element has been deactivated — both
    // of which trigger framework assertions on hot restart.
    _authSubscription = ref.listenManual<AuthState>(
      authControllerProvider,
      (previous, next) => _onAuthChanged(previous, next),
    );

    // Deferred past the first frame: `checkSession`/`restore` mutate provider
    // state, and doing so synchronously in initState (i.e. during the tree's
    // first build) trips the framework's `!_dirty` assertion on hot restart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).checkSession();
      ref.read(syncControllerProvider.notifier).restore();
      _ensureNotificationPermission();
    });

    // Launcher shortcuts (`hosanna://songs`, `hosanna://services/next`, …).
    // The stream also replays the link the app was cold-started with.
    _launcherLinks = listenToLauncherLinks(_openLocation);

    // Notification taps. Routed through the same deferred `_openLocation` as
    // launcher links, so cold starts wait for the session/organization to
    // resolve before navigating.
    final fcm = ref.read(fcmServiceProvider);
    _notificationTaps = fcm.onNotificationTap.listen(_openLocation);
    unawaited(
      fcm.initialNotificationLocation().then((location) {
        if (location != null) _openLocation(location);
      }),
    );
  }

  /// Navigates to a launcher link's location once the app is ready for it.
  ///
  /// Deferred to the next frame because on a cold start the link can be
  /// delivered before the router has built, and `go` during the build phase
  /// trips a framework assertion. While the session is still loading the router
  /// redirects everything to `/splash`, so the target is kept until the auth
  /// state settles (see [_onAuthChanged]).
  void _openLocation(String location) {
    _pendingLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingLocation());
  }

  void _openPendingLocation() {
    final location = _pendingLocation;
    if (location == null || !mounted) return;
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.loading || auth.resolvingOrganization) return;
    _pendingLocation = null;
    ref.read(goRouterProvider).go(location);
  }

  /// Re-asserts the OS notification permission on startup.
  ///
  /// Consent-aware on purpose: the OS prompt is only shown here for users who
  /// have already opted in. First-time consent is handled by
  /// [NotificationConsentGate], whose "Allow" action requests the OS permission
  /// as well — so requesting it here unconditionally would double-prompt.
  Future<void> _ensureNotificationPermission() async {
    final consented =
        await ref.read(notificationConsentStoreProvider).read();
    if (consented != true) return;
    await ref.read(fcmServiceProvider).requestPermission();
  }

  @override
  void dispose() {
    _launcherLinks?.cancel();
    _notificationTaps?.cancel();
    _authSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (_pendingLocation != null) {
      // Same deferral as the sync below: never navigate from inside a provider
      // notification.
      Future.microtask(_openPendingLocation);
    }

    final prevOrg = previous?.organization?.id;
    final nextOrg = next.organization?.id;
    if (!next.isAuthenticated || nextOrg == null || nextOrg == prevOrg) return;

    // Defer so `syncAll` (which mutates SyncController state) never runs
    // synchronously inside the provider notification, which would rebuild
    // widgets while the tree is mid-build. Read via the captured container so
    // this stays valid even if the element has since been deactivated.
    Future.microtask(() {
      _container?.read(syncControllerProvider.notifier).syncAll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeSyncOnResume();
    }
  }

  void _maybeSyncOnResume() {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.organization == null) return;

    final lastSynced = ref.read(syncControllerProvider).lastSyncedAt;
    final stale = lastSynced == null ||
        DateTime.now().difference(lastSynced) > const Duration(seconds: 60);
    if (stale) {
      ref.read(syncControllerProvider.notifier).syncAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final platformHighContrast = MediaQuery.highContrastOf(context);
    final theme = HosannaTheme.resolve(
      mode: settings.themeMode,
      platformBrightness: platformBrightness,
      highContrast: settings.highContrast || platformHighContrast,
    );

    return MaterialApp.router(
      title: 'Hosanna',
      routerConfig: router,
      theme: theme,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      // Lets the app present foreground FCM messages from above the Navigator.
      scaffoldMessengerKey: _messengerKey,
      // Both sit above the Navigator: the listener surfaces foreground pushes,
      // and the gate overlays the first-run notification consent prompt.
      builder: (context, child) => ForegroundNotificationListener(
        messengerKey: _messengerKey,
        onOpen: _openLocation,
        child: NotificationConsentGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
