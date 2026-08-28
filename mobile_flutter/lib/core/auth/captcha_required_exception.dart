/// Thrown when an auth operation needs a Turnstile token but captcha is not
/// available (site key not configured, or the user cancelled the challenge).
class CaptchaRequiredException implements Exception {
  const CaptchaRequiredException();
}
