import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/captcha_required_exception.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'turnstile_captcha_page.dart';

/// Maps an auth error to a user-facing string, using server messages when
/// available and localized fallbacks otherwise.
String authErrorMessage(Object error, AppLocalizations l10n) {
  if (error is CaptchaRequiredException) {
    return l10n.authCaptchaNotConfigured;
  }
  if (error is ApiException) {
    return error.message.isNotEmpty ? error.message : l10n.commonError;
  }
  return l10n.commonError;
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
