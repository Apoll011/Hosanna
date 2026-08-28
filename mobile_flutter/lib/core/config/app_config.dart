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

  /// Full API root, e.g. `https://host/api`.
  String get apiRoot => '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api';

  bool get isTurnstileConfigured => turnstileSiteKey.trim().isNotEmpty;

  static const AppConfig instance = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOSANNA_API_URL',
      defaultValue: 'https://hosanna-server-beta.vercel.app',
    ),
    turnstileSiteKey: String.fromEnvironment('HOSANNA_TURNSTILE_SITE_KEY'),
    turnstileUrl: String.fromEnvironment('HOSANNA_TURNSTILE_URL'),
  );
}
