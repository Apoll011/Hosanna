import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/social_auth_exception.dart';

/// Thin seam over the `google_sign_in` plugin.
///
/// Everything that touches the plugin lives here, so [GoogleAuthProvider] stays
/// a testable "configure → authenticate → credential" orchestration. The plugin
/// only exposes a singleton ([GoogleSignIn.instance]) that cannot be
/// constructed outside the framework, so tests replace this class instead.
///
/// On Android the plugin drives Google's **Credential Manager**: the system
/// owns the account chooser, so no browser, WebView or custom list UI is ever
/// involved. Only the Google ID token is read from the result; account details
/// are deliberately ignored, because the server — not this client — decides
/// who the token belongs to.
class GoogleSignInClient {
  GoogleSignInClient();

  GoogleSignIn get _plugin => GoogleSignIn.instance;

  /// Whether this platform implements the interactive sign-in flow. False on
  /// web, where Google requires a button rendered by its own SDK.
  bool get supportsInteractiveSignIn {
    try {
      return _plugin.supportsAuthenticate();
    } catch (_) {
      return false;
    }
  }

  /// Configures the plugin. Must be awaited before any sign-in call, and only
  /// ever called once per process.
  ///
  /// [serverClientId] is the web/server OAuth client ID whose audience the ID
  /// token must carry for the backend to accept it. [nonce], when set, is
  /// embedded in the ID token for Better Auth to validate.
  Future<void> initialize({required String serverClientId, String? nonce}) {
    return _plugin.initialize(serverClientId: serverClientId, nonce: nonce);
  }

  /// Restores a previously authorised account with little or no UI.
  ///
  /// Resolves `null` when there is nothing to restore, and never throws for a
  /// cancellation (the plugin treats that as "no result").
  Future<String?> restoreIdToken() async {
    try {
      final attempt = _plugin.attemptLightweightAuthentication();
      if (attempt == null) return null;
      return (await attempt)?.authentication.idToken;
    } catch (error) {
      throw _toSocialAuthException(error);
    }
  }

  /// Shows Google's native sign-in UI (bottom sheet / account chooser) and
  /// resolves the ID token.
  Future<String?> signInIdToken() async {
    try {
      final account = await _plugin.authenticate();
      return account.authentication.idToken;
    } catch (error) {
      throw _toSocialAuthException(error);
    }
  }

  /// Maps plugin failures onto the app's social-auth error model.
  ///
  /// `description` is plugin-provided (e.g. `"No credential available: …"`) and
  /// carries no token material; `details` is never propagated.
  SocialAuthException _toSocialAuthException(Object error) {
    if (error is GoogleSignInException) {
      final code = switch (error.code) {
        GoogleSignInExceptionCode.canceled => SocialAuthErrorCode.canceled,
        GoogleSignInExceptionCode.clientConfigurationError =>
          SocialAuthErrorCode.notConfigured,
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.uiUnavailable =>
          SocialAuthErrorCode.unavailable,
        // The plugin reports "no credential available" through the generic
        // code, so the description is the only signal that the device simply
        // has no usable account.
        GoogleSignInExceptionCode.unknownError
            when error.description?.contains('No credential') ?? false =>
          SocialAuthErrorCode.noAccount,
        _ => SocialAuthErrorCode.unknown,
      };
      return SocialAuthException(code, message: error.description, cause: error);
    }
    if (error is MissingPluginException || error is PlatformException) {
      return SocialAuthException(
        SocialAuthErrorCode.unavailable,
        message: error is MissingPluginException
            ? 'The Google sign-in plugin is not available on this platform.'
            : (error as PlatformException).message,
        cause: error,
      );
    }
    return SocialAuthException(
      SocialAuthErrorCode.unknown,
      message: 'Unexpected ${error.runtimeType} from the Google sign-in plugin.',
      cause: error,
    );
  }
}
