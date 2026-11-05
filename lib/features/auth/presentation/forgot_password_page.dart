import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';
import 'auth_ui_utils.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = l10n.authEmailInvalid);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final captchaToken = await obtainCaptchaToken(ref, context);
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(email: email, captchaToken: captchaToken);
      if (mounted) setState(() => _sent = true);
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

    return AuthScaffold(
      title: _sent ? l10n.authResetLinkSent : l10n.authResetPasswordTitle,
      subtitle: _sent ? null : l10n.authResetPasswordMessage,
      heroAsset: _sent ? AuthHeroes.resetSent : AuthHeroes.forgotPassword,
      heroFallbackIcon: Icons.lock_reset_rounded,
      child: _sent
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AuthErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l10n.authEmail),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: l10n.authSendResetLink,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
    );
  }
}
