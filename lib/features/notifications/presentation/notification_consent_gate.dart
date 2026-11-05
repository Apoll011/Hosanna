import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_controller.dart';
import '../../setup/data/setup_controller.dart';

/// Asks the user — once, after first-run setup is complete — whether the
/// server may send notifications to this device, then records the answer and
/// mirrors it onto the current session's `notify` field.
///
/// It is mounted from `MaterialApp.builder`, i.e. *above* the Navigator, so
/// the prompt is rendered as an in-tree modal overlay instead of a dialog.
///
/// Deferred until the user has an organization **and** finished the setup
/// wizard so the prompt does not stack on top of join/setup.
///
/// The answer is intentionally distinct from the OS notification permission:
/// "Allow" records consent and *also* requests the OS permission, while
/// "Not now" only disables `session.notify`.
class NotificationConsentGate extends ConsumerStatefulWidget {
  const NotificationConsentGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationConsentGate> createState() =>
      _NotificationConsentGateState();
}

class _NotificationConsentGateState
    extends ConsumerState<NotificationConsentGate> {
  bool _prompting = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _maybeAsk();
      }
      if (next.organization != null && previous?.organization == null) {
        _maybeAsk();
      }
    });
    ref.listen(setupControllerProvider, (previous, next) {
      if (next && previous != true) {
        _maybeAsk();
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_prompting) _buildPrompt(context),
      ],
    );
  }

  Future<void> _maybeAsk() async {
    if (_prompting || !mounted) return;
    if (await ref.read(notificationConsentStoreProvider).read() != null) return;
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.organization == null) return;
    if (!ref.read(setupControllerProvider)) return;
    if (!mounted) return;
    setState(() => _prompting = true);
  }

  Future<void> _answer(bool consented) async {
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider.notifier);
    try {
      await auth.recordNotificationConsent(consented);
      if (consented) {
        // OS permission is requested only when the user opts in, and remains
        // independent of `session.notify`.
        await ref.read(fcmServiceProvider).requestPermission();
      }
      await auth.setNotify(consented);
    } catch (_) {
      // Leave the prompt dismissed; the Settings toggle stays available.
    } finally {
      if (mounted) {
        setState(() {
          _prompting = false;
          _busy = false;
        });
      }
    }
  }

  Widget _buildPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.surface,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          HosannaIllustrations.notificationConsent,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.notifications_active_outlined,
                            color: scheme.primary,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notificationConsentTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.notificationConsentMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy ? null : () => _answer(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(l10n.notificationConsentNotNow),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy ? null : () => _answer(true),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(l10n.notificationConsentAllow),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
