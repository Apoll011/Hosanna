/// Compile-time application configuration.
///
/// Values are injected via `--dart-define` so the same build can point at
/// different environments without code changes:
///
///   flutter run --dart-define=HOSANNA_API_URL=https://api.example.com
///   flutter run --dart-define=HOSANNA_TURNSTILE_URL=https://studio.hosanna.live/captcha
///
/// The API URL defaults to the Hosanna production API.
library;

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.turnstileUrl,
    required this.origin,
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

  /// Full API root, e.g. `https://host/api`.
  String get apiRoot => '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api';

  /// Captcha is available when a hosted Turnstile page URL is configured.
  bool get isTurnstileConfigured => turnstileUrl.trim().isNotEmpty;

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
      defaultValue: 'http://localhost',
    ),
  );
}
