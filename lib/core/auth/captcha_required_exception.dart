/// Thrown when an auth operation needs a Turnstile token but captcha is not
/// available (captcha page URL not configured, or the user cancelled the
/// challenge).
class CaptchaRequiredException implements Exception {
  const CaptchaRequiredException();
}
