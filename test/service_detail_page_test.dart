import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/core/db/tables.dart';
import 'package:hosanna/features/services/presentation/service_detail_page.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedService() async {
    await db.into(db.services).insert(
      ServicesCompanion.insert(
        id: 'svc-1',
        name: 'Sunday Service',
        date: '2024-01-01T00:00:00Z',
        elements: Value([
          ServiceElement(
            id: 'el-1',
            type: 'welcome',
            title: 'Welcome',
            position: 0,
          ),
        ]),
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
      ),
    );
  }

  /// Pumps the app with a minimal router: a home route plus the service detail
  /// route, mirroring the production `/services/:id` location.
  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/services/svc-1'),
                child: const Text('home'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/services/:id',
          builder: (_, state) =>
              ServiceDetailPage(serviceId: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'drawer leave button exits the service instead of only closing the drawer',
    (tester) async {
      await seedService();
      await pumpApp(tester);

      // Open the service detail page.
      await tester.tap(find.text('home'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceDetailPage), findsOneWidget);

      // Open the order drawer.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Leave Service Mode'), findsOneWidget);

      // Tap the drawer's leave action.
      await tester.tap(find.text('Leave Service Mode'));
      await tester.pumpAndSettle();

      // The whole service page must be popped, not just the drawer closed.
      expect(find.byType(ServiceDetailPage), findsNothing);
      expect(find.text('home'), findsOneWidget);
    },
  );
}
