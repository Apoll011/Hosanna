import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/session_store.dart';
import '../core/config/app_config.dart';
import '../core/db/database.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';

/// Compile-time configuration (API URL, Turnstile site key).
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

/// Shared Dio instance (cookies + bearer + captcha + error normalization).
final dioProvider = Provider<Dio>((ref) {
  return buildDio(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    cookieJar: ref.watch(cookieJarProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Key of the shell's [Scaffold], letting branch pages open the navigation
/// drawer (hamburger) via `currentState?.openDrawer()`.
final shellScaffoldKeyProvider =
    Provider<GlobalKey<ScaffoldState>>((ref) => GlobalKey<ScaffoldState>());
