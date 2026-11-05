import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/illustrations.dart';
import '../../../core/auth/auth_session.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/presentation/auth_scaffold.dart';
import '../../setup/data/setup_controller.dart';

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
      final all =
          await ref.read(authControllerProvider.notifier).listInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = all.where((i) => i.status == 'pending').toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).commonError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(OrganizationInvitation inv) async {
    setState(() => _processingId = inv.id);
    try {
      // Seed the setup wizard with the invite role before org state flips.
      await ref
          .read(setupControllerProvider.notifier)
          .rememberInviteRole(inv.role);
      await ref.read(authControllerProvider.notifier).acceptInvitation(inv.id);
      // Success: router sends the user to /setup (or /songs if already done).
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
      setState(
        () => _invitations = _invitations.where((i) => i.id != inv.id).toList(),
      );
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
    final scheme = theme.colorScheme;

    final empty = !_loading && _error == null && _invitations.isEmpty;
    final hasInvites = !_loading && _error == null && _invitations.isNotEmpty;

    // One illustration only: empty state owns the copy via scaffold title,
    // so we don't also render EmptyState's duplicate art underneath.
    final title = empty ? l10n.onboardingNoInvites : l10n.onboardingTitle;
    final subtitle =
        empty ? l10n.onboardingNoInvitesDesc : l10n.onboardingSubtitle;

    return AuthScaffold(
      title: title,
      subtitle: subtitle,
      heroAsset: _error != null ? null : HosannaIllustrations.onboardingInvite,
      heroFallbackIcon: Icons.groups_rounded,
      showLogo: _error != null,
      showBack: false,
      maxWidth: 480,
      footer: TextButton.icon(
        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: Text(l10n.onboardingSignOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingLoadingInvites,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else if (_error != null)
            ErrorState(
              title: _error!,
              description: l10n.commonErrorDesc,
              retryLabel: l10n.commonRetry,
              onRetry: _load,
              illustrationAsset: HosannaIllustrations.stateError,
            )
          else if (empty)
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.commonRetry),
            )
          else if (hasInvites) ...[
            Text(
              l10n.onboardingPendingInvites(_invitations.length),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final inv in _invitations)
              _InvitationCard(
                invitation: inv,
                processing: _processingId == inv.id,
                onAccept: () => _accept(inv),
                onReject: () => _reject(inv),
              ),
          ],
        ],
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
    final scheme = theme.colorScheme;
    final orgName = invitation.organizationName ?? invitation.organizationId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.church_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.onboardingRole}: ${_roleLabel(invitation.role)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: processing ? null : onReject,
                      child: Text(l10n.onboardingReject),
                    ),
                  ),
                  const SizedBox(width: 10),
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
