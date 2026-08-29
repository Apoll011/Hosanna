import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/app/router.dart';
import 'package:hosanna/core/auth/auth_session.dart';
import 'package:hosanna/core/auth/session_store.dart';
import 'package:hosanna/core/config/app_config.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/core/network/api_client.dart';
import 'package:hosanna/features/auth/data/auth_repository.dart';
import 'package:hosanna/features/auth/domain/auth_controller.dart';
import 'package:hosanna/features/circle_of_fifths/presentation/circle_of_fifths_page.dart';
import 'package:hosanna/features/songs/presentation/song_library_page.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authenticated controller with an org, so the router lands on /songs.
class _TestAuthController extends AuthController {
  _TestAuthController()
      : super(
          AuthRepository(Dio()),
          SessionStore(),
          TokenStore(),
          AppConfig.instance,
        ) {
    const org = Organization(id: 'o1', name: 'Test Org', slug: 'test');
    state = AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        user: const AuthUser(id: 'u1', name: 'Test User', email: 't@example.com'),
        sessionToken: 'tok',
        organization: org,
      ),
      organization: org,
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size logicalSize = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.reset);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          cookieJarProvider.overrideWithValue(CookieJar()),
          authControllerProvider.overrideWith((ref) => _TestAuthController()),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(goRouterProvider),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone: drawer tool item navigates to its shell branch',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(SongLibraryPage), findsOneWidget);

    // Open the drawer via the hamburger.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Circle of Fifths'), findsOneWidget);

    // Tap the Circle of Fifths tool row.
    await tester.tap(find.text('Circle of Fifths'));
    await tester.pumpAndSettle();

    expect(find.byType(CircleOfFifthsPage), findsOneWidget);
  });

  testWidgets('tablet: sidebar tool item navigates to its shell branch',
      (tester) async {
    await pumpApp(tester, logicalSize: const Size(1280, 800));
    expect(find.byType(SongLibraryPage), findsOneWidget);
    expect(find.text('Circle of Fifths'), findsOneWidget);

    await tester.tap(find.text('Circle of Fifths'));
    await tester.pumpAndSettle();

    expect(find.byType(CircleOfFifthsPage), findsOneWidget);
  });
}
