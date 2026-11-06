import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';
import 'auth_ui_utils.dart';
import 'social_sign_in_button.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _socialBusy = false;
  String? _error;
  bool _obscure = true;

  bool get _busy => _loading || _socialBusy;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty) {
      setState(() => _error = l10n.authNameRequired);
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = l10n.authEmailInvalid);
      return;
    }
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
      final captchaToken = await obtainCaptchaToken(ref, context);
      await ref.read(authControllerProvider.notifier).signUp(
            name: name,
            email: email,
            password: password,
            captchaToken: captchaToken,
          );
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
      title: l10n.authSignUpTitle,
      subtitle: l10n.authSignUpSubtitle,
      heroAsset: AuthHeroes.signUp,
      heroFallbackIcon: Icons.person_add_alt_1_rounded,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.authHaveAccount),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.authSignIn),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(labelText: l10n.authName),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.authEmail),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              helperText: l10n.authPasswordMinLength,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
            label: l10n.authSignUpButton,
            loading: _loading,
            onPressed: _busy ? null : _submit,
          ),
          SocialSignInSection(
            enabled: !_loading,
            onBusyChanged: (busy) => setState(() => _socialBusy = busy),
            onError: (message) => setState(() => _error = message),
          ),
        ],
      ),
    );
  }
}
