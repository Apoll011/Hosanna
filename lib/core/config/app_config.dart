/// Compile-time application configuration.
///
/// Values are injected via `--dart-define` so the same build can point at
/// different environments without code changes:
///
///   flutter run --dart-define=HOSANNA_API_URL=https://api.example.com
///   flutter run --dart-define=HOSANNA_TURNSTILE_URL=https://studio.hosanna.live/captcha
///   flutter run --dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=1234.apps.googleusercontent.com
///
/// The API URL defaults to the Hosanna production API.
library;

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.turnstileUrl,
    required this.origin,
    this.googleServerClientId = '',
    this.googleNonceEnabled = false,
  });

  /// Base URL of the Hosanna backend (no trailing slash, no `/api`).
  final String apiBaseUrl;

  /// URL of the hosted Turnstile captcha page.
  ///
  /// Turnstile validates the hostname of the page that renders the widget, so
  /// the challenge must be served from a domain listed in Cloudflare's
  /// "Hostname Management" (default: the Studio captcha page). The hosted page
  /// must call `TurnstileCallback.postMessage(token)` in its success callback.
  final String turnstileUrl;

  /// `Origin` header value sent on state-changing requests.
  ///
  /// Better Auth's CSRF protection requires a non-GET request that carries a
  /// session cookie to also carry an `Origin` (or `Referer`) matching its
  /// `trustedOrigins`. The React/Capacitor app sends `capacitor://localhost`
  /// / `http://localhost`; Dio does not send one, so we set it explicitly.
  /// The backend trusts `http://localhost`, `capacitor://localhost`, and
  /// `https://*.hosanna.live`.
  final String origin;

  /// Google OAuth **web/server** client ID (`…apps.googleusercontent.com`).
  ///
  /// Native sign-in passes it to Google as the ID token's audience
  /// (`serverClientId` on Android), and the Better Auth server must list the
  /// same client ID under `socialProviders.google.clientId` so it accepts the
  /// token. Public by design — the Google *client secret* never leaves the
  /// server. Empty when the build was not configured for Google sign-in.
  final String googleServerClientId;

  /// Whether Google ID tokens are minted with a nonce that Better Auth must
  /// validate (`idToken.nonce` on `/sign-in/social`).
  ///
  /// Off by default: with the one-shot `GoogleSignIn.initialize()` API the
  /// nonce is fixed for the whole app run, so it must match between whatever
  /// Credential Manager has cached and the current run. Only enable it once
  /// the server-side flow is confirmed to expect a nonce.
  final bool googleNonceEnabled;

  /// Full API root, e.g. `https://host/api`.
  String get apiRoot => '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api';

  /// Captcha is available when a hosted Turnstile page URL is configured.
  bool get isTurnstileConfigured => turnstileUrl.trim().isNotEmpty;

  /// Google sign-in is available when the web/server client ID is configured.
  bool get isGoogleSignInConfigured => googleServerClientId.trim().isNotEmpty;

  static const AppConfig instance = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOSANNA_API_URL',
      defaultValue: 'https://api.hosanna.live',
    ),
    turnstileUrl: String.fromEnvironment(
      'HOSANNA_TURNSTILE_URL',
      defaultValue: 'https://studio.hosanna.live/captcha',
    ),
    origin: String.fromEnvironment(
      'HOSANNA_ORIGIN',
      defaultValue: 'hosanna://localhost',
    ),
    googleServerClientId: String.fromEnvironment(
      'HOSANNA_GOOGLE_SERVER_CLIENT_ID',
    ),
    googleNonceEnabled: bool.fromEnvironment('HOSANNA_GOOGLE_NONCE'),
  );
}
