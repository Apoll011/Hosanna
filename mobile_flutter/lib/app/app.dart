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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick off the silent session check and restore sync metadata.
    ref.read(authControllerProvider.notifier).checkSession();
    ref.read(syncControllerProvider.notifier).restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    // Initial sync whenever an active organization first becomes available
    // (covers both launch-with-cache and post-sign-in).
    ref.listen(authControllerProvider, (previous, next) {
      final prevOrg = previous?.organization?.id;
      final nextOrg = next.organization?.id;
      if (next.isAuthenticated && nextOrg != null && nextOrg != prevOrg) {
        ref.read(syncControllerProvider.notifier).syncAll();
      }
    });

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
