import 'dart:convert';
import 'dart:math';

import 'social_auth_exception.dart';

/// Seam between the auth screens and the native social providers.
///
/// A provider owns the *platform* authentication for one identity provider
/// (Google today; Apple, GitHub, Microsoft later) and hands back the credential
/// the Better Auth server needs to verify that identity. Providers never talk
/// to the server themselves, never look inside the credential they produce, and
/// never see the provider's client secret — the server remains the only place
/// that decides whether a credential is authentic.
abstract interface class SocialAuthProvider {
  /// Better Auth provider id, sent as `provider` on `/sign-in/social`.
  String get id;

  /// Human-readable provider name, used to build the button label.
  String get displayName;

  /// Runs the provider's native authentication and resolves the credential to
  /// forward to Better Auth.
  ///
  /// Throws a [SocialAuthException] for every failure mode — including user
  /// cancellation — so callers only need one error model.
  Future<SocialAuthCredential> authenticate();
}

/// Credentials produced by a native provider, in the shape Better Auth's
/// `/api/auth/sign-in/social` request body expects.
class SocialAuthCredential {
  const SocialAuthCredential({
    required this.idToken,
    this.accessToken,
    this.nonce,
  });

  /// Provider ID token (e.g. a Google ID token): the credential Better Auth
  /// verifies server-side before creating or linking the account.
  final String idToken;

  /// Provider access token, when the native flow handed one out. Google's
  /// native flow does not need one for the Better Auth ID-token sign-in, so it
  /// is normally `null`.
  final String? accessToken;

  /// Nonce the ID token was minted with, when one was requested.
  final String? nonce;

  /// Value of the `idToken` object in the `/sign-in/social` request body.
  Map<String, dynamic> toJson() => {
        'token': idToken,
        if (nonce != null && nonce!.isNotEmpty) 'nonce': nonce,
        if (accessToken != null && accessToken!.isNotEmpty)
          'accessToken': accessToken,
      };

  /// Redacted on purpose: token material must never reach logs or crash
  /// reports.
  @override
  String toString() => 'SocialAuthCredential('
      'idToken: <redacted>, '
      'accessToken: ${accessToken == null ? 'null' : '<redacted>'}, '
      'nonce: ${nonce == null ? 'null' : '<redacted>'})';
}

/// Generates a cryptographically secure, URL-safe nonce for providers that
/// support binding the ID token to the sign-in attempt.
///
/// The nonce is handed to the provider (so it lands in the ID token's `nonce`
/// claim) and sent to Better Auth, which rejects a token whose `nonce` claim
/// does not match.
String generateSocialAuthNonce({int bytes = 32}) {
  final random = Random.secure();
  final values = List<int>.generate(bytes, (_) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}
