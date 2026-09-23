import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/captcha_required_exception.dart';
import '../../../core/auth/social_auth_exception.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'turnstile_captcha_page.dart';

/// Maps an auth error to a user-facing string, using server messages when
/// available and localized fallbacks otherwise.
///
/// Returns an empty string for errors that must not be surfaced at all —
/// currently only a cancelled social sign-in, which is a normal user action and
/// not a failure.
String authErrorMessage(Object error, AppLocalizations l10n) {
  if (error is CaptchaRequiredException) {
    return l10n.authCaptchaNotConfigured;
  }
  if (error is SocialAuthException) {
    return error.isCancellation ? '' : socialAuthErrorMessage(error, l10n);
  }
  if (error is ApiException) {
    return error.message.isNotEmpty ? error.message : l10n.commonError;
  }
  return l10n.commonError;
}

/// Maps a social sign-in failure to a localized message.
///
/// Server-provided text is deliberately *not* echoed here: social failures are
/// an internal handshake between the native provider and Better Auth, so the
/// user gets an actionable, translated explanation of the failure mode instead
/// of a raw API error.
String socialAuthErrorMessage(SocialAuthException error, AppLocalizations l10n) {
  return switch (error.code) {
    SocialAuthErrorCode.canceled => '',
    SocialAuthErrorCode.noAccount => l10n.authSocialNoAccount,
    SocialAuthErrorCode.unavailable => l10n.authSocialUnavailable,
    SocialAuthErrorCode.notConfigured => l10n.authSocialNotConfigured,
    SocialAuthErrorCode.rejected => l10n.authSocialRejected,
    SocialAuthErrorCode.network => l10n.authSocialNetworkError,
    SocialAuthErrorCode.server => l10n.authSocialServerError,
    SocialAuthErrorCode.unknown => l10n.authSocialError,
  };
}

/// Resolves a captcha token (navigating to the Turnstile WebView when the site
/// key is configured), or `null` otherwise.
Future<String?> obtainCaptchaToken(WidgetRef ref, BuildContext context) {
  return resolveCaptchaToken(context, ref.read(appConfigProvider));
}

/// Inline error banner used across the auth forms.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
