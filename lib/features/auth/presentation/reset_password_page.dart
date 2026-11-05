import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';
import 'auth_ui_utils.dart';

/// Accepts a Better Auth password-reset `token` (from the emailed deep link)
/// via the `token` query parameter.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final password = _password.text;

    if (password.length < 6) {
      setState(() => _error = l10n.authPasswordMinLength);
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = l10n.authPasswordsDontMatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: widget.token,
            newPassword: password,
          );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_done) {
      return AuthScaffold(
        title: l10n.authPasswordChanged,
        heroAsset: AuthHeroes.passwordChanged,
        heroFallbackIcon: Icons.lock_open_rounded,
        showBack: false,
        child: AuthPrimaryButton(
          label: l10n.authSignIn,
          onPressed: () => context.go('/sign-in'),
        ),
      );
    }

    return AuthScaffold(
      title: l10n.authResetPassword,
      subtitle: l10n.authNewPassword,
      heroAsset: AuthHeroes.resetPassword,
      heroFallbackIcon: Icons.password_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.authNewPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l10n.authConfirmPassword),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: l10n.authChangePassword,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
