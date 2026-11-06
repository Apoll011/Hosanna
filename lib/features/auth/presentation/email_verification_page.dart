import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_scaffold.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _sending = false;

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).sendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authEmailVerificationSent)),
        );
      }
    } catch (_) {
      // Non-fatal; the user can retry.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verified =
        ref.watch(authControllerProvider).session?.user.emailVerified == true;

    if (verified) {
      return AuthScaffold(
        title: l10n.authEmailVerified,
        heroAsset: AuthHeroes.emailVerified,
        heroFallbackIcon: Icons.verified_rounded,
        showBack: false,
        child: const SizedBox.shrink(),
      );
    }

    return AuthScaffold(
      title: l10n.authVerifyEmailTitle,
      subtitle: l10n.authVerifyEmailMessage,
      heroAsset: AuthHeroes.verifyEmail,
      heroFallbackIcon: Icons.mark_email_read_outlined,
      showBack: false,
      child: AuthPrimaryButton(
        label: l10n.authResendEmail,
        loading: _sending,
        onPressed: _resend,
      ),
    );
  }
}
