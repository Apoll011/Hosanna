import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/social_auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/google_g_logo.dart';
import '../domain/auth_controller.dart';
import 'auth_ui_utils.dart';

/// The "or" divider plus one button per registered [SocialAuthProvider].
///
/// Both the sign-in and the sign-up screen render this identical widget: a
/// social attempt is one flow for Better Auth (it decides whether the identity
/// is an existing or a new user), so there is deliberately no separate
/// "social sign-up" implementation anywhere in the client.
class SocialSignInSection extends ConsumerStatefulWidget {
  const SocialSignInSection({
    super.key,
    required this.onError,
    this.onBusyChanged,
    this.enabled = true,
  });

  /// Surfaces a failure in the host page's error banner (`null` clears it).
  /// Cancellations are never reported: dismissing the native picker is not an
  /// error.
  final ValueChanged<String?> onError;

  /// Tells the host page whether a native sign-in is running, so it can disable
  /// its own submit button meanwhile.
  final ValueChanged<bool>? onBusyChanged;

  /// False while the host page has its own request in flight.
  final bool enabled;

  @override
  ConsumerState<SocialSignInSection> createState() => _SocialSignInSectionState();
}

class _SocialSignInSectionState extends ConsumerState<SocialSignInSection> {
  /// Provider currently authenticating, if any.
  String? _activeProviderId;

  Future<void> _signIn(SocialAuthProvider provider) async {
    if (_activeProviderId != null || !widget.enabled) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _activeProviderId = provider.id);
    widget.onError(null);
    widget.onBusyChanged?.call(true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithSocial(provider);
      // Success: the router's auth redirect navigates into the app.
    } catch (error) {
      // `authErrorMessage` returns an empty string for a cancellation.
      final message = authErrorMessage(error, l10n);
      if (mounted && message.isNotEmpty) widget.onError(message);
    } finally {
      if (mounted) {
        setState(() => _activeProviderId = null);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(socialAuthProvidersProvider);
    if (providers.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _OrDivider(label: l10n.authOr),
        const SizedBox(height: 24),
        for (final provider in providers)
          Padding(
            padding: EdgeInsets.only(bottom: provider == providers.last ? 0 : 12),
            child: SocialSignInButton(
              provider: provider,
              loading: _activeProviderId == provider.id,
              onPressed: widget.enabled && _activeProviderId == null
                  ? () => _signIn(provider)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// A "Continue with …" button for one [SocialAuthProvider].
///
/// The provider stays an implementation detail: the label is built from its
/// display name and the branding is resolved from its id here, so no auth
/// screen ever imports a provider-specific widget or SDK.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.loading = false,
  });

  final SocialAuthProvider provider;

  /// `null` disables the button (another sign-in is running).
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the label while this provider authenticates.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        // Google's branding asks for a neutral, high-contrast button surface.
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _brandIcon(provider.id),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.authContinueWith(provider.displayName),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  /// Branding per provider id, with a neutral fallback for new providers.
  Widget _brandIcon(String providerId) => switch (providerId) {
        'google' => const GoogleGLogo(size: 18),
        _ => const Icon(Icons.login, size: 18),
      };
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
