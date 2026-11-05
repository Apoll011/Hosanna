import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';
import 'auth_ui_utils.dart';
import 'social_sign_in_button.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _socialBusy = false;
  String? _error;
  bool _obscure = true;

  bool get _busy => _loading || _socialBusy;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.authRequiredFields);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final captchaToken = await obtainCaptchaToken(ref, context);
      if (captchaToken == null &&
          ref.read(authControllerProvider).status != AuthStatus.authenticated) {
        // No token but captcha configured means the user cancelled; keep going
        // only when captcha is simply not configured (controller surfaces it).
      }
      await ref.read(authControllerProvider.notifier).signIn(
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
      title: l10n.authSignInTitle,
      subtitle: l10n.authSignInSubtitle,
      heroAsset: AuthHeroes.signIn,
      heroFallbackIcon: Icons.login_rounded,
      showBack: false,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.authNoAccount),
          TextButton(
            onPressed: () => context.push('/sign-up'),
            child: Text(l10n.authCreateAccount),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(l10n.authForgotPassword),
            ),
          ),
          const SizedBox(height: 4),
          AuthPrimaryButton(
            label: l10n.authSignInButton,
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
