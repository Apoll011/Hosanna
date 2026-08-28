import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_controller.dart';
import '../features/auth/domain/auth_controller.dart';
import '../l10n/generated/app_localizations.dart';
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
  ProviderContainer? _container;

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
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
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
    );
  }
}
