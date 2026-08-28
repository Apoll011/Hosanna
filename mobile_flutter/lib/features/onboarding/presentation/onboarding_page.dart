import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/hosanna_logo.dart';
import '../../auth/domain/auth_controller.dart';

/// Shown when a user is signed in but has no organization: lists the pending
/// invitations and lets them accept/reject. Deliberately has **no** create-org
/// flow — joining an existing church is the only path here.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _loading = true;
  String? _error;
  String? _processingId;
  List<OrganizationInvitation> _invitations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await ref.read(authControllerProvider.notifier).listInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = all.where((i) => i.status == 'pending').toList();
      });
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).commonError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(OrganizationInvitation inv) async {
    setState(() => _processingId = inv.id);
    try {
      await ref.read(authControllerProvider.notifier).acceptInvitation(inv.id);
      // Success: auth state now has an org; the router redirects to /songs.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonError)),
      );
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _reject(OrganizationInvitation inv) async {
    setState(() => _processingId = inv.id);
    try {
      await ref.read(authControllerProvider.notifier).rejectInvitation(inv.id);
      if (!mounted) return;
      setState(() => _invitations = _invitations.where((i) => i.id != inv.id).toList());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonError)),
      );
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: HosannaLogo(size: 80)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingSubtitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _load)
                  else if (_invitations.isEmpty)
                    _EmptyState(
                      title: l10n.onboardingNoInvites,
                      description: l10n.onboardingNoInvitesDesc,
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text(
                            l10n.onboardingPendingInvites(_invitations.length),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          for (final inv in _invitations)
                            _InvitationCard(
                              invitation: inv,
                              processing: _processingId == inv.id,
                              onAccept: () => _accept(inv),
                              onReject: () => _reject(inv),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.onboardingSignOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });

  final OrganizationInvitation invitation;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final orgName = invitation.organizationName ?? invitation.organizationId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orgName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.onboardingRole}: ${_roleLabel(invitation.role)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: processing ? null : onReject,
                    child: Text(l10n.onboardingReject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: processing ? null : onAccept,
                    child: processing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.onboardingAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    final r = role.toLowerCase();
    return switch (r) {
      'owner' => 'Owner',
      'admin' => 'Admin',
      'editor' => 'Editor',
      'musician' => 'Musician',
      'guest' => 'Guest',
      _ => role.isEmpty ? 'member' : role,
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.mail_outline,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    );
  }
}
