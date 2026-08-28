/// Compile-time application configuration.
///
/// Values are injected via `--dart-define` so the same build can point at
/// different environments without code changes:
///
///   flutter run --dart-define=HOSANNA_API_URL=https://api.example.com
///   flutter run --dart-define=HOSANNA_TURNSTILE_SITE_KEY=0x4AAAA...
///
/// The API URL defaults to the Hosanna beta server used by the React app.
library;

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.turnstileSiteKey,
    required this.turnstileUrl,
    required this.origin,
  });

  /// Base URL of the Hosanna backend (no trailing slash, no `/api`).
  ///
  /// Mirrors the React app's `VITE_API_URL` (`https://hosanna-server-beta.vercel.app`).
  final String apiBaseUrl;

  /// Cloudflare Turnstile *site* (public) key.
  ///
  /// The backend enforces Turnstile on `/sign-up/email`, `/sign-in/email` and
  /// `/request-password-reset`. This key is rendered by the captcha WebView.
  /// It is intentionally empty until provided by the project owner.
  final String turnstileSiteKey;

  /// Optional URL of a hosted Turnstile page.
  ///
  /// Turnstile validates the hostname of the page that renders the widget, so
  /// inline WebView HTML (`about:blank`) cannot satisfy it in production. Point
  /// this at a page served from a domain listed in Cloudflare's "Hostname
  /// Management", e.g. `https://studio.hosanna.live/captcha`. The hosted page
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

  /// Full API root, e.g. `https://host/api`.
  String get apiRoot => '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api';

  /// Captcha is available when either a site key (inline fallback) or a
  /// hosted page URL (default: the Studio captcha page) is configured.
  bool get isTurnstileConfigured =>
      turnstileSiteKey.trim().isNotEmpty || turnstileUrl.trim().isNotEmpty;

  static const AppConfig instance = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOSANNA_API_URL',
      defaultValue: 'https://api.hosanna.live',
    ),
    turnstileSiteKey: String.fromEnvironment('HOSANNA_TURNSTILE_SITE_KEY'),
    turnstileUrl: String.fromEnvironment(
      'HOSANNA_TURNSTILE_URL',
      defaultValue: 'https://studio.hosanna.live/captcha',
    ),
    origin: String.fromEnvironment(
      'HOSANNA_ORIGIN',
      defaultValue: 'http://localhost',
    ),
  );
}
