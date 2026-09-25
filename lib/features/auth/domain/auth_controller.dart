import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/captcha_required_exception.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/auth/social_auth_exception.dart';
import '../../../core/auth/social_auth_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/data/fcm_service.dart';
import '../../notifications/data/notification_consent_store.dart';
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
    this._config, {
    FcmService? fcm,
    NotificationConsentStore? consentStore,
  })  : _fcm = fcm ?? FcmService(),
        _consent = consentStore ?? InMemoryNotificationConsentStore(),
        super(const AuthState(status: AuthStatus.loading)) {
    // Firebase may rotate the device token at any time; when it does, push the
    // new token onto the **current** session only.
    _fcmSubscription = _fcm.onTokenRefresh.listen(_onFcmTokenRefresh);
  }

  final AuthRepository _repository;
  final SessionStore _store;
  final TokenStore _tokenStore;
  final AppConfig _config;
  final FcmService _fcm;
  final NotificationConsentStore _consent;

  StreamSubscription<String>? _fcmSubscription;

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
      // Sessions created before FCM support carry no token; sync this device's
      // token onto the session on every authenticated startup.
      await syncFcmToken();
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
    // Resolve this device's token up front so it lands on the session being
    // created (it belongs to *this* device, not the account).
    final fcm = await _fcm.getToken();
    final consented = await _consent.read();
    final session = await _repository.signIn(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
      fcm: fcm,
      // No explicit consent yet → the session starts with notifications off.
      notify: consented == true,
    );
    await _applySession(session, token: session.sessionToken);
    await _resolveOrganization(session);
    await _applyNotificationConsent();
    await syncFcmToken();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    _requireCaptchaIfNeeded(captchaToken);
    final fcm = await _fcm.getToken();
    final consented = await _consent.read();
    final session = await _repository.signUp(
      name: name.trim(),
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
      fcm: fcm,
      // No explicit consent yet → the session starts with notifications off.
      notify: consented == true,
    );
    await _applySession(session, token: session.sessionToken);
    await _resolveOrganization(session);
    await _applyNotificationConsent();
    await syncFcmToken();
  }

  /// Signs in — or signs up — with a native social provider.
  ///
  /// Both auth screens call this same method: the provider only supplies a
  /// credential, and Better Auth decides whether it belongs to an existing
  /// account or a new one. No captcha is required on the social endpoint, and
  /// the resulting session is applied through the same path as email sign-in.
  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    final credential = await provider.authenticate();
    try {
      final session = await _repository.signInWithSocial(
        providerId: provider.id,
        credential: credential,
      );
      await _applySession(session, token: session.sessionToken);
      await _resolveOrganization(session);
      // Same per-device sync as email auth: the social flow creates a session
      // on this device too.
      await _applyNotificationConsent();
      await syncFcmToken();
    } on ApiException catch (e) {
      throw _socialFailure(e);
    }
  }

  Future<void> signOut() async {
    // The session naturally stops being valid server-side; the FCM token is
    // intentionally left on the (now dead) session rather than deleted first.
    await _repository.signOut();
    await _clearSession();
  }

  // ── FCM / per-session notifications ──────────────────────────────────────

  /// Pushes this device's current FCM token onto the authenticated session.
  ///
  /// Centralised so sign-in, sign-up, startup and token refresh all funnel
  /// through one place. No request is made when the token is missing or the
  /// session already carries the same token. Does nothing when signed out.
  Future<void> syncFcmToken() async {
    final session = state.session;
    if (session == null) return;
    final token = await _fcm.getToken();
    if (token == null || token.isEmpty) return;
    if (session.fcm == token) return;
    try {
      await updateCurrentSession(fcm: token);
    } catch (_) {
      // Best-effort backstop — retried on the next startup/token refresh, so a
      // failed sync never turns a successful sign-in into a failure.
    }
  }

  /// Enables/disables server notifications for **this** session only
  /// (`session.notify`), flipping it between true and false. Independent of the
  /// OS notification permission.
  Future<void> setNotify(bool value) => updateCurrentSession(notify: value);

  /// Records the user's consent decision for this device.
  Future<void> recordNotificationConsent(bool consented) =>
      _consent.write(consented);

  /// Ensures a session without explicit consent has `notify` disabled.
  ///
  /// Email sign-in/sign-up already send this at creation time; this also
  /// covers the social flow (whose endpoint has no `notify` field) and any
  /// server that does not echo the additional field back.
  Future<void> _applyNotificationConsent() async {
    final consented = await _consent.read();
    final session = state.session;
    if (session == null) return;
    if (consented != true && session.notify) {
      try {
        await updateCurrentSession(notify: false);
      } catch (_) {
        // Best-effort; retried on the next auth/startup.
      }
    }
  }

  /// Updates the current session's additional fields via
  /// `POST /api/auth/update-session`, then mirrors the change locally.
  ///
  /// Only the supplied values are sent, and only the current session is
  /// touched — other devices/sessions keep their own `fcm`/`notify`.
  Future<void> updateCurrentSession({String? fcm, bool? notify}) async {
    final current = state.session;
    if (current == null) return;
    await _repository.updateSession(fcm: fcm, notify: notify);
    // Mirror exactly what we asked for; `copyWithFcm` keeps whatever was not
    // supplied (e.g. `notify: false` leaves `fcm` intact).
    final merged = current.copyWithFcm(fcm: fcm, notify: notify);
    _tokenStore.update(merged.sessionToken);
    await _store.writeSession(merged);
    state = state.copyWith(session: merged);
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onFcmTokenRefresh(String token) async {
    final session = state.session;
    if (session == null || token.isEmpty || session.fcm == token) return;
    try {
      await updateCurrentSession(fcm: token);
    } catch (_) {
      // A failed sync is retried on the next refresh/startup.
    }
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
      fcm: current?.fcm ?? session.fcm,
      notify: current?.notify ?? session.notify,
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

  /// Organizations the user belongs to (for the workspace switcher).
  Future<List<Organization>> listOrganizations() =>
      _repository.listOrganizations();

  /// Switches the active organization and re-resolves it locally.
  Future<void> switchOrganization(String slug) async {
    await _repository.setActiveOrganization(slug);
    final session = state.session;
    if (session != null) {
      await _resolveOrganization(session);
    }
  }

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
      fcm: session.fcm,
      notify: session.notify,
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
          fcm: session.fcm,
          notify: session.notify,
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

  /// Folds a Better Auth failure into the social error model so the UI only
  /// has to understand [SocialAuthException].
  SocialAuthException _socialFailure(ApiException e) {
    if (e.isNetworkError) {
      return SocialAuthException(
        SocialAuthErrorCode.network,
        message: e.message,
        cause: e,
      );
    }
    final status = e.statusCode;
    if (status == 401 ||
        status == 403 ||
        e.code == 'INVALID_TOKEN' ||
        e.code == 'OAUTH_LINK_ERROR') {
      return SocialAuthException(
        SocialAuthErrorCode.rejected,
        message: e.message,
        cause: e,
      );
    }
    if (status != null && status >= 500) {
      return SocialAuthException(
        SocialAuthErrorCode.server,
        message: e.message,
        cause: e,
      );
    }
    return SocialAuthException(
      SocialAuthErrorCode.unknown,
      message: e.message,
      cause: e,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionStoreProvider),
    ref.watch(tokenStoreProvider),
    ref.watch(appConfigProvider),
    fcm: ref.watch(fcmServiceProvider),
    consentStore: ref.watch(notificationConsentStoreProvider),
  );
});

/// Convenience provider exposing just the current session (null when signed out).
final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).session;
});
