enum TwoFactorMethod { totp, otp, backup }

class TwoFactorRequiredException implements Exception {
  const TwoFactorRequiredException(this.methods);

  final List<TwoFactorMethod> methods;
}
