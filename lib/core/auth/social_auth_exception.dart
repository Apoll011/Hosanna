/// How a social sign-in attempt failed.
///
/// Distinguishes the failure modes the auth screens need to tell apart, from
/// the native provider (cancellation, no account, unavailable SDK) and from
/// Better Auth (rejected credential, server/network failure).
enum SocialAuthErrorCode {
  /// The user dismissed the native account picker.
  canceled,

  /// The device has no usable account for the provider.
  noAccount,

  /// The provider's native SDK/UI is unavailable on this platform or device.
  unavailable,

  /// The app is missing its provider configuration (e.g. the OAuth client ID).
  notConfigured,

  /// Better Auth refused the credential the provider produced.
  rejected,

  /// The request never reached the server.
  network,

  /// The server failed while completing the sign-in.
  server,

  /// Anything else.
  unknown,
}

/// Failure of a native social sign-in attempt.
///
/// [message] is developer-facing; it never contains provider tokens or raw
/// server responses.
class SocialAuthException implements Exception {
  const SocialAuthException(this.code, {this.message, this.cause});

  final SocialAuthErrorCode code;

  /// Developer-facing detail. Never shown to users as-is (see
  /// `authErrorMessage`) and never contains token material.
  final String? message;

  /// Original error, kept for debugging.
  final Object? cause;

  /// Cancellations are not failures: the UI stays silent for them.
  bool get isCancellation => code == SocialAuthErrorCode.canceled;

  @override
  String toString() =>
      'SocialAuthException(${code.name})${message == null ? '' : ': $message'}';
}
