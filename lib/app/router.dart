import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/agenda/presentation/agenda_event_page.dart';
import '../features/agenda/presentation/agenda_page.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/auth/presentation/email_verification_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/auth/presentation/sign_up_page.dart';
import '../features/circle_of_fifths/presentation/circle_of_fifths_page.dart';
import '../features/folders/presentation/folder_browser_page.dart';
import '../features/metronome/presentation/metronome_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/services/presentation/next_service_page.dart';
import '../features/services/presentation/service_detail_page.dart';
import '../features/services/presentation/service_list_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/songs/presentation/ai_import/ai_import_models.dart';
import '../features/songs/presentation/ai_import/ai_import_nav.dart';
import '../features/songs/presentation/ai_import/ai_import_progress_page.dart';
import '../features/songs/presentation/ai_import/ai_import_review_page.dart';
import '../features/songs/presentation/ai_import/ai_import_source_page.dart';
import '../features/songs/presentation/song_detail_page.dart';
import '../features/songs/presentation/song_editor_page.dart';
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
      GoRoute(path: '/splash', builder: (_, _) => const _SplashPage()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpPage()),
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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      // Branch order must match the kSongsBranch..kSettingsBranch constants in
      // nav_branches.dart (used by the shell + sidebar).
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/metronome',
                builder: (_, _) => const MetronomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/circle-of-fifths',
                builder: (_, _) => const CircleOfFifthsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                builder: (_, _) => const FolderBrowserPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, state) {
                  final tab = state.uri.queryParameters['tab'];
                  return SettingsPage(
                    initialTab: switch (tab) {
                      'workspace' => SettingsTab.workspace,
                      'service' || 'preferences' => SettingsTab.service,
                      'appearance' => SettingsTab.appearance,
                      _ => SettingsTab.account,
                    },
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (_, _) => const AgendaPage(),
              ),
            ],
          ),
        ],
      ),
      // Outside the shell (same pattern as /songs/:id) so the shell drawer
      // stays available on the agenda list via ShellLeadingButton.
      GoRoute(
        path: '/agenda/:id',
        builder: (_, state) =>
            AgendaEventPage(eventId: state.pathParameters['id']!),
      ),
      // Static song paths before `/songs/:id` so "new" / "import" are not
      // swallowed as ids.
      GoRoute(
        path: '/songs/new',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          final extra = state.extra;
          String? title = q['title'];
          String? artist = q['artist'];
          String? content = q['content'];
          String? folderId = q['folderId'];
          if (extra is Map) {
            title ??= extra['title'] as String?;
            artist ??= extra['artist'] as String?;
            content ??= extra['content'] as String?;
            folderId ??= extra['folderId'] as String?;
          }
          return SongEditorPage(
            initialTitle: title,
            initialArtist: artist,
            initialContent: content,
            initialFolderId: folderId,
          );
        },
      ),
      GoRoute(
        path: '/songs/import/ai',
        builder: (_, state) {
          String? folderId = state.uri.queryParameters['folderId'];
          final extra = state.extra;
          if (extra is Map) {
            folderId ??= extra['folderId'] as String?;
          }
          return AiImportSourcePage(folderId: folderId);
        },
      ),
      GoRoute(
        path: '/songs/import/ai/progress',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! AiImportJobRequest) {
            // Avoid nesting a second source page on a dead progress route.
            return const AiImportMissingPayloadRedirect();
          }
          return AiImportProgressPage(request: extra);
        },
      ),
      GoRoute(
        path: '/songs/import/ai/review',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! AiImportDraft) {
            return const AiImportMissingPayloadRedirect();
          }
          return AiImportReviewPage(draft: extra);
        },
      ),
      GoRoute(
        path: '/songs/:id/edit',
        builder: (_, state) =>
            SongEditorPage(songId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/songs/:id',
        builder: (_, state) =>
            SongDetailPage(songId: state.pathParameters['id']!),
      ),
      // Declared before `/services/:id` so the launcher shortcut
      // (`hosanna://services/next`) isn't swallowed by the id route; the page
      // replaces itself with the resolved service.
      GoRoute(
        path: '/services/next',
        builder: (_, _) => const NextServicePage(),
      ),
      GoRoute(
        path: '/services/:id',
        builder: (_, state) =>
            ServiceDetailPage(serviceId: state.pathParameters['id']!),
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
