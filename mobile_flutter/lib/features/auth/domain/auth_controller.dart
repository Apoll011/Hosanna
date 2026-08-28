import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/captcha_required_exception.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.organization,
    this.resolvingOrganization = false,
  });

  final AuthStatus status;
  final AuthSession? session;
  final Organization? organization;

  /// True while the active organization is being fetched after sign-in/sign-up
  /// (or when re-resolving it), so the router can show a loading screen instead
  /// of briefly flashing the "join an org" onboarding page.
  final bool resolvingOrganization;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    Organization? organization,
    bool? resolvingOrganization,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      organization: clearSession ? null : (organization ?? this.organization),
      resolvingOrganization: resolvingOrganization ?? this.resolvingOrganization,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._repository,
    this._store,
    this._tokenStore,
    this._config,
  ) : super(const AuthState(status: AuthStatus.loading));

  final AuthRepository _repository;
  final SessionStore _store;
  final TokenStore _tokenStore;
  final AppConfig _config;

  /// Restores a persisted session on launch, then verifies it against the
  /// server (falling back to the cached session on network errors).
  Future<void> checkSession() async {
    final cached = await _store.readSession();
    final cachedToken = await _store.readToken();

    if (cached != null) {
      _tokenStore.update(cachedToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: cached,
        organization: cached.organization,
      );
    }

    try {
      final fresh = await _repository.getSession();
      if (fresh == null) {
        await _clearSession();
        return;
      }
      await _applySession(fresh, token: fresh.sessionToken);
      await _resolveOrganization(fresh);
    } on ApiException catch (e) {
      // Explicit auth rejection → sign out; network error → keep cache.
      if (_isAuthRejection(e)) {
        await _clearSession();
      } else if (cached != null) {
        // Keep the cached (offline) session.
      } else {
        await _clearSession();
      }
    } catch (_) {
      if (cached == null) await _clearSession();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    _requireCaptchaIfNeeded(captchaToken);
    final session = await _repository.signIn(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
    await _applySession(session, token: session.sessionToken);
    await _resolveOrganization(session);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    _requireCaptchaIfNeeded(captchaToken);
    final session = await _repository.signUp(
      name: name.trim(),
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
    await _applySession(session, token: session.sessionToken);
    await _resolveOrganization(session);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    await _clearSession();
  }

  Future<void> updateProfile({String? name}) async {
    final session = await _repository.updateUser(name: name);
    final current = state.session;
    final merged = AuthSession(
      user: session.user,
      sessionToken: current?.sessionToken ?? session.sessionToken,
      activeOrganizationId:
          current?.activeOrganizationId ?? session.activeOrganizationId,
      organization: current?.organization ?? session.organization,
      expiresAt: current?.expiresAt ?? session.expiresAt,
    );
    await _applySession(merged, token: merged.sessionToken);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  Future<void> changeEmail({required String newEmail}) =>
      _repository.changeEmail(newEmail: newEmail);

  Future<void> requestPasswordReset({
    required String email,
    String? captchaToken,
  }) async {
    _requireCaptchaIfNeeded(captchaToken);
    await _repository.requestPasswordReset(
      email: email.trim(),
      captchaToken: captchaToken,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _repository.resetPassword(token: token, newPassword: newPassword);

  Future<void> sendVerificationEmail() =>
      _repository.sendVerificationEmail(email: state.session?.user.email);

  Future<List<OrganizationInvitation>> listInvitations() =>
      _repository.listUserInvitations();

  Future<void> acceptInvitation(String invitationId) async {
    await _repository.acceptInvitation(invitationId);
    // The server sets the accepted org as active; re-resolve it locally so the
    // app routes into the org and triggers the initial sync.
    final session = state.session;
    if (session != null) {
      await _resolveOrganization(session);
    }
  }

  Future<void> rejectInvitation(String invitationId) =>
      _repository.rejectInvitation(invitationId);

  // ── Internals ────────────────────────────────────────────────────────────

  void _requireCaptchaIfNeeded(String? captchaToken) {
    if (!_config.isTurnstileConfigured &&
        (captchaToken == null || captchaToken.isEmpty)) {
      throw const CaptchaRequiredException();
    }
  }

  Future<void> _applySession(AuthSession session, {required String token}) async {
    final merged = token.isEmpty ? session : AuthSession(
      user: session.user,
      sessionToken: token,
      activeOrganizationId: session.activeOrganizationId,
      organization: session.organization,
      expiresAt: session.expiresAt,
    );
    _tokenStore.update(merged.sessionToken);
    await _store.writeToken(merged.sessionToken);
    await _store.writeSession(merged);
    final org = merged.organization ?? state.organization;
    state = AuthState(
      status: AuthStatus.authenticated,
      session: merged,
      organization: org,
      // If we don't know the org yet, the router shows a loading screen until
      // `_resolveOrganization` finishes instead of flashing onboarding.
      resolvingOrganization: org == null,
    );
  }

  Future<void> _resolveOrganization(AuthSession session) async {
    try {
      var org = await _repository.getFullOrganization();
      if (org == null) {
        final orgs = await _repository.listOrganizations();
        if (orgs.isNotEmpty) {
          await _repository.setActiveOrganization(orgs.first.slug);
          org = await _repository.getFullOrganization();
        }
      }
      if (org != null) {
        final merged = AuthSession(
          user: session.user,
          sessionToken: session.sessionToken,
          activeOrganizationId: org.id,
          organization: org,
          expiresAt: session.expiresAt,
        );
        await _store.writeSession(merged);
        state = state.copyWith(
          session: merged,
          organization: org,
          resolvingOrganization: false,
        );
      } else {
        state = state.copyWith(resolvingOrganization: false);
      }
    } catch (_) {
      // Non-fatal: sync will surface any missing active-org as a 403.
      state = state.copyWith(resolvingOrganization: false);
    }
  }

  Future<void> _clearSession() async {
    _tokenStore.update(null);
    await _store.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  bool _isAuthRejection(ApiException e) {
    final s = e.statusCode;
    return s == 401 || s == 403 || s == 404;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionStoreProvider),
    ref.watch(tokenStoreProvider),
    ref.watch(appConfigProvider),
  );
});

/// Convenience provider exposing just the current session (null when signed out).
final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).session;
});
