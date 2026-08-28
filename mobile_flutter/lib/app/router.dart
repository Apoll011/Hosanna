import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_controller.dart';
import '../features/auth/presentation/account_page.dart';
import '../features/auth/presentation/email_verification_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/auth/presentation/sign_up_page.dart';
import '../features/circle_of_fifths/presentation/circle_of_fifths_page.dart';
import '../features/export/presentation/export_pdf_page.dart';
import '../features/folders/presentation/folder_browser_page.dart';
import '../features/metronome/presentation/metronome_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/services/presentation/service_detail_page.dart';
import '../features/services/presentation/service_list_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/songs/presentation/song_detail_page.dart';
import '../features/songs/presentation/song_library_page.dart';
import '../shared/widgets/hosanna_logo.dart';
import 'shell.dart';

bool _isAuthRoute(String path) {
  return path == '/sign-in' ||
      path == '/sign-up' ||
      path == '/forgot-password' ||
      path == '/reset-password' ||
      path == '/verify-email';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      final loading = auth.status == AuthStatus.loading;
      final loggedIn = auth.isAuthenticated;
      final hasOrg = auth.organization != null;
      final onAuthRoute = _isAuthRoute(path);

      if (loading) return path == '/splash' ? null : '/splash';

      if (!loggedIn) {
        return onAuthRoute ? null : '/sign-in';
      }

      // Signed in but the active organization is still being fetched — show a
      // loading screen rather than flashing the onboarding/join-org page.
      if (auth.resolvingOrganization) {
        return path == '/splash' ? null : '/splash';
      }

      if (onAuthRoute) return hasOrg ? '/songs' : '/onboarding';

      if (!hasOrg) {
        // Org-less users may only see onboarding until they join one.
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Has an org — no longer allow the pre-org screens.
      if (path == '/onboarding' || path == '/splash') return '/songs';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _SplashPage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInPage(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (_, _) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            HosannaShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/songs',
                builder: (_, _) => const SongLibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (_, _) => const ServiceListPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/folders',
        builder: (_, _) => const FolderBrowserPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'];
          return SettingsPage(
            initialTab: switch (tab) {
              'workspace' => SettingsTab.workspace,
              'preferences' => SettingsTab.preferences,
              _ => SettingsTab.account,
            },
          );
        },
      ),
      GoRoute(
        path: '/songs/:id',
        builder: (_, state) => SongDetailPage(songId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/services/:id',
        builder: (_, state) =>
            ServiceDetailPage(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/metronome',
        builder: (_, _) => const MetronomePage(),
      ),
      GoRoute(
        path: '/circle-of-fifths',
        builder: (_, _) => const CircleOfFifthsPage(),
      ),
      GoRoute(
        path: '/export-pdf',
        builder: (_, _) => const ExportPdfPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (_, _) => const AccountPage(),
      ),
    ],
  );
});

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HosannaLogo(size: 96),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
