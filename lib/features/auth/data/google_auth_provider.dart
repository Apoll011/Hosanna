import '../../../core/auth/social_auth_exception.dart';
import '../../../core/auth/social_auth_provider.dart';
import '../../../core/config/app_config.dart';
import 'google_sign_in_client.dart';

/// Google implementation of [SocialAuthProvider].
///
/// Android is the priority target and uses Google's Credential Manager (through
/// `google_sign_in` 7.x), so tapping the button produces the native Google
/// account chooser rather than a browser page. The provider's only job is to
/// obtain the Google **ID token**:
///
/// 1. `initialize` once per process with the **web/server** client ID, so the
///    ID token's audience is the one the Better Auth server recognises.
/// 2. Try a previously authorised account (little or no UI), then the native
///    sign-in flow that lets the user pick or add an account.
/// 3. Hand the token to the Better Auth client, which posts it to
///    `/api/auth/sign-in/social` — the server verifies it, finds or creates the
///    user and issues the session.
///
/// The token is never decoded here and no profile data is trusted: it is an
/// opaque credential that only the server may interpret.
class GoogleAuthProvider implements SocialAuthProvider {
  GoogleAuthProvider(this._config, {GoogleSignInClient? client})
      : _client = client ?? GoogleSignInClient();

  /// Better Auth provider id for Google.
  static const String providerId = 'google';

  final AppConfig _config;
  final GoogleSignInClient _client;

  /// `initialize` may only run once per process, so the future is memoised and
  /// shared by every later sign-in attempt.
  Future<void>? _initialization;

  /// Nonce the ID token must carry, when enabled for this build.
  String? _nonce;

  @override
  String get id => providerId;

  @override
  String get displayName => 'Google';

  @override
  Future<SocialAuthCredential> authenticate() async {
    final serverClientId = _config.googleServerClientId.trim();
    if (serverClientId.isEmpty) {
      throw const SocialAuthException(
        SocialAuthErrorCode.notConfigured,
        message: 'HOSANNA_GOOGLE_SERVER_CLIENT_ID is not configured.',
      );
    }
    if (!_client.supportsInteractiveSignIn) {
      throw const SocialAuthException(
        SocialAuthErrorCode.unavailable,
        message: 'This platform does not support the native Google sign-in flow.',
      );
    }

    await _ensureInitialized(serverClientId: serverClientId);

    // The lightweight restore is a best-effort optimisation: it reuses a
    // previously authorised account with little or no UI. It must never be able
    // to abort the sign-in, because Google reports some *configuration*
    // failures (e.g. "[28444] Developer console is not set up correctly") from
    // that path before the interactive flow has a chance to run. Swallowing the
    // failure here lets the native account chooser open and surface the real,
    // actionable error instead of dying silently.
    String? idToken;
    try {
      idToken = await _client.restoreIdToken();
    } catch (_) {
      // A restore failure is not fatal: fall through to the interactive flow
      // below, which surfaces the real error and lets the user pick an account.
    }
    idToken ??= await _client.signInIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const SocialAuthException(
        SocialAuthErrorCode.noAccount,
        message: 'Google returned no ID token.',
      );
    }
    return SocialAuthCredential(idToken: idToken, nonce: _nonce);
  }

  Future<void> _ensureInitialized({required String serverClientId}) async {
    final pending = _initialization ??=
        _client.initialize(serverClientId: serverClientId, nonce: _resolveNonce());
    try {
      await pending;
    } catch (_) {
      // Let a later attempt retry after a transient initialisation failure
      // instead of replaying the failed future forever.
      _initialization = null;
      rethrow;
    }
  }

  /// Nonce for this app run, or `null` when the build does not opt in.
  String? _resolveNonce() {
    if (!_config.googleNonceEnabled) return null;
    return _nonce ??= generateSocialAuthNonce();
  }
}
