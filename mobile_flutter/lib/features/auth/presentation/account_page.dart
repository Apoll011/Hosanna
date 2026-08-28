import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_controller.dart';
import 'auth_ui_utils.dart';
import 'email_verification_page.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authAccount)),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(
                  name: user.name,
                  email: user.email,
                  emailVerified: user.emailVerified,
                  verifiedLabel: l10n.authEmailVerified,
                  unverifiedLabel: l10n.authEmailNotVerified,
                ),
                const SizedBox(height: 16),
                _EditNameCard(
                  initialName: user.name,
                  onSaved: (name) async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateProfile(name: name);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.authNameSaved)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (!user.emailVerified)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mark_email_unread_outlined),
                      title: Text(l10n.authVerifyEmail),
                      subtitle: Text(l10n.authEmailNotVerified),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmailVerificationPage(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _ChangePasswordCard(
                  onChanged: (current, next) async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .changePassword(
                          currentPassword: current,
                          newPassword: next,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.authPasswordChanged)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.authSignOut),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.verifiedLabel,
    required this.unverifiedLabel,
  });

  final String name;
  final String email;
  final bool emailVerified;
  final String verifiedLabel;
  final String unverifiedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.isEmpty
        ? '?'
        : name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(initials, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        emailVerified
                            ? Icons.verified
                            : Icons.pending_outlined,
                        size: 16,
                        color: emailVerified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        emailVerified ? verifiedLabel : unverifiedLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameCard extends StatefulWidget {
  const _EditNameCard({required this.initialName, required this.onSaved});

  final String initialName;
  final Future<void> Function(String name) onSaved;

  @override
  State<_EditNameCard> createState() => _EditNameCardState();
}

class _EditNameCardState extends State<_EditNameCard> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(name);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.authEditProfile, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.authName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard({required this.onChanged});

  final Future<void> Function(String current, String next) onChanged;

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_next.text.length < 6) {
      setState(() => _error = l10n.authPasswordMinLength);
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = l10n.authPasswordsDontMatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onChanged(_current.text, _next.text);
      _current.clear();
      _next.clear();
      _confirm.clear();
    } catch (e) {
      if (mounted) setState(() => _error = l10n.authPasswordChangeError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.authChangePassword,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.authCurrentPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.authNewPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.authConfirmPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.authChangePassword),
            ),
          ],
        ),
      ),
    );
  }
}
