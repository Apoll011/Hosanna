/// Supplies a Cloudflare Turnstile token for endpoints that enforce captcha
/// (`/sign-in/email`, `/sign-up/email`, `/request-password-reset`).
///
/// This is the seam between the auth flow and the captcha implementation. v1
/// ships a WebView-based provider (see `TurnstileWebViewProvider`); until the
/// hosted Turnstile page URL is configured, it resolves `null` and the auth
/// layer surfaces a clear "captcha not configured" state instead of guessing.
abstract class CaptchaProvider {
  /// Resolves a fresh Turnstile token, or `null` when captcha is unavailable.
  Future<String?> resolveToken();
}

/// Captcha provider used when the hosted Turnstile page URL is not configured.
class NoopCaptchaProvider implements CaptchaProvider {
  const NoopCaptchaProvider();

  @override
  Future<String?> resolveToken() async => null;
}
