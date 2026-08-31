import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/session_store.dart';
import '../core/config/app_config.dart';
import '../core/db/database.dart';
import '../core/network/api_client.dart';
import '../core/network/user_agent.dart';
import '../features/auth/data/auth_repository.dart';

/// Compile-time configuration (API URL, hosted Turnstile page URL).
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);

/// In-memory bearer token read by the Dio auth interceptor.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Secure storage for the session + bearer token.
final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

/// On-device Drift database. Overridden in `main()` with the opened instance.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// Cookie jar for Better Auth's session cookie. Overridden in `main()`.
final cookieJarProvider = Provider<CookieJar>(
  (ref) => throw UnimplementedError('cookieJarProvider must be overridden'),
);

/// Shared preferences for small key-value state (sync checkpoints, timestamps).
/// Overridden in `main()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Shared Dio instance (cookies + bearer + captcha + user-agent + error
/// normalization). A stable random install id is generated once, persisted in
/// [sharedPreferencesProvider], and baked into the User-Agent so server logs
/// can tell installs apart.
final dioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  var installId = prefs.getString(kInstallIdPrefsKey);
  if (installId == null || installId.isEmpty) {
    installId = generateInstallId();
    // Fire-and-forget: the id only needs to survive restarts; a lost write
    // just means the next launch mints a new one.
    unawaited(prefs.setString(kInstallIdPrefsKey, installId));
  }
  return buildDio(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    cookieJar: ref.watch(cookieJarProvider),
    installId: installId,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Key of the shell's [Scaffold], letting branch pages open the navigation
/// drawer (hamburger) via `currentState?.openDrawer()`.
final shellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);

/// Whether the tablet persistent sidebar is collapsed. Phones don't use a
/// sidebar, so this flag is only meaningful in the tablet layout.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => true);
