import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/two_factor_required_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';
import 'auth_ui_utils.dart';

class TwoFactorPage extends ConsumerStatefulWidget {
  const TwoFactorPage({required this.methods, super.key});

  final List<TwoFactorMethod> methods;

  @override
  ConsumerState<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends ConsumerState<TwoFactorPage> {
  final _code = TextEditingController();
  late TwoFactorMethod _method;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _method = widget.methods.contains(TwoFactorMethod.totp)
        ? TwoFactorMethod.totp
        : widget.methods.first;
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendTwoFactorOtp();
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).authTwoFactorCodeSent,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = authErrorMessage(e, AppLocalizations.of(context)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty ||
        (_method != TwoFactorMethod.backup && code.length < 6)) {
      setState(
        () => _error = AppLocalizations.of(context).authTwoFactorCodeRequired,
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyTwoFactor(method: _method, code: code);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = authErrorMessage(e, AppLocalizations.of(context)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final segments = [
      if (widget.methods.contains(TwoFactorMethod.totp))
        ButtonSegment(
          value: TwoFactorMethod.totp,
          icon: const Icon(LucideIcons.smartphone),
          label: Text(l10n.authTwoFactorAuthenticator),
        ),
      if (widget.methods.contains(TwoFactorMethod.otp))
        ButtonSegment(
          value: TwoFactorMethod.otp,
          icon: const Icon(LucideIcons.mail),
          label: Text(l10n.authTwoFactorEmail),
        ),
      if (widget.methods.contains(TwoFactorMethod.backup))
        ButtonSegment(
          value: TwoFactorMethod.backup,
          icon: const Icon(LucideIcons.keyRound),
          label: Text(l10n.authTwoFactorBackup),
        ),
    ];

    return AuthScaffold(
      title: l10n.authTwoFactorTitle,
      subtitle: l10n.authTwoFactorSubtitle,
      heroFallbackIcon: LucideIcons.shieldCheck,
      showBack: false,
      maxWidth: 480,
      footer: TextButton(
        onPressed: () => context.go('/sign-in'),
        child: Text(l10n.authTwoFactorBackToLogin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          if (_message != null) ...[
            Text(
              _message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          if (segments.length > 1) ...[
            SegmentedButton<TwoFactorMethod>(
              segments: segments,
              selected: {_method},
              onSelectionChanged: _loading
                  ? null
                  : (selection) => setState(() {
                      _method = selection.first;
                      _code.clear();
                      _error = null;
                      _message = null;
                    }),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            controller: _code,
            enabled: !_loading,
            keyboardType: _method == TwoFactorMethod.backup
                ? TextInputType.text
                : TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: _method == TwoFactorMethod.backup ? null : 8,
            decoration: InputDecoration(
              labelText: _method == TwoFactorMethod.backup
                  ? l10n.authTwoFactorBackupCode
                  : l10n.authTwoFactorCode,
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (_method == TwoFactorMethod.otp) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : _sendOtp,
              icon: const Icon(LucideIcons.mail),
              label: Text(l10n.authTwoFactorSendCode),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _loading ? null : _verify,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authTwoFactorVerify),
          ),
        ],
      ),
    );
  }
}
