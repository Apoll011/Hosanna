import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/core/auth/session_store.dart';
import 'package:hosanna/core/auth/social_auth_exception.dart';
import 'package:hosanna/core/auth/social_auth_provider.dart';
import 'package:hosanna/core/config/app_config.dart';
import 'package:hosanna/core/network/api_client.dart';
import 'package:hosanna/features/auth/data/auth_repository.dart';
import 'package:hosanna/features/auth/domain/auth_controller.dart';
import 'package:hosanna/features/auth/presentation/auth_ui_utils.dart';
import 'package:hosanna/features/auth/presentation/sign_in_page.dart';
import 'package:hosanna/features/auth/presentation/sign_up_page.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth controller double: records which provider the screens hand over and can
/// fail or block on demand, instead of touching the network or secure storage.
class _RecordingAuthController extends AuthController {
  _RecordingAuthController({this.failure, this.pending})
      : super(
          AuthRepository(Dio()),
          SessionStore(),
          TokenStore(),
          AppConfig.instance,
        );

  final SocialAuthException? failure;

  /// When set, a social sign-in stays pending until it completes.
  final Completer<void>? pending;

  final List<SocialAuthProvider> attempts = [];

  @override
  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    attempts.add(provider);
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }
}

class _FakeSocialProvider implements SocialAuthProvider {
  @override
  String get id => 'google';

  @override
  String get displayName => 'Google';

  @override
  Future<SocialAuthCredential> authenticate() async =>
      const SocialAuthCredential(idToken: 'id-token');
}

void main() {
  late _FakeSocialProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = _FakeSocialProvider();
  });

  /// Pumps a page on a tall surface so the whole form (including the social
  /// section) is laid out and tappable.
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page,
    _RecordingAuthController controller,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => controller),
          socialAuthProvidersProvider.overrideWithValue([provider]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sign-in page offers the Google button next to the form', (
    tester,
  ) async {
    await pumpPage(tester, const SignInPage(), _RecordingAuthController());

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
  });

  testWidgets('sign-up page offers the same Google button', (tester) async {
    await pumpPage(tester, const SignUpPage(), _RecordingAuthController());

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  group('both screens submit through the same provider implementation', () {
    for (final (name, page) in <(String, Widget)>[
      ('sign-in', const SignInPage()),
      ('sign-up', const SignUpPage()),
    ]) {
      testWidgets(name, (tester) async {
        final controller = _RecordingAuthController();
        await pumpPage(tester, page, controller);

        await tester.ensureVisible(find.text('Continue with Google'));
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(controller.attempts, hasLength(1));
        expect(controller.attempts.single, same(provider));
      });
    }
  });

  testWidgets('a cancelled native picker is not shown as an error', (
    tester,
  ) async {
    final controller = _RecordingAuthController(
      failure: const SocialAuthException(SocialAuthErrorCode.canceled),
    );
    await pumpPage(tester, const SignInPage(), controller);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthErrorBanner), findsNothing);
  });

  testWidgets('a rejected credential shows a localized failure', (
    tester,
  ) async {
    final controller = _RecordingAuthController(
      failure: const SocialAuthException(SocialAuthErrorCode.rejected),
    );
    await pumpPage(tester, const SignUpPage(), controller);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(
      find.text("We couldn't verify your account. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('the Google button and the form are disabled while it runs', (
    tester,
  ) async {
    final pending = Completer<void>();
    final controller = _RecordingAuthController(pending: pending);
    await pumpPage(tester, const SignInPage(), controller);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    // Loading state on the social button…
    expect(
      find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    // …and the email form cannot be submitted concurrently.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
