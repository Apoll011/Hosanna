import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_controller.dart';

/// Asks the user — once, after the first authenticated session — whether the
/// server may send notifications to this device, then records the answer and
/// mirrors it onto the current session's `notify` field.
///
/// It is mounted from `MaterialApp.builder`, i.e. *above* the Navigator, so
/// the prompt is rendered as an in-tree modal overlay instead of a dialog.
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
    if (!ref.read(authControllerProvider).isAuthenticated) return;
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

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.notificationConsentTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.notificationConsentMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _busy ? null : () => _answer(false),
                          child: Text(l10n.notificationConsentNotNow),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _busy ? null : () => _answer(true),
                          child: Text(l10n.notificationConsentAllow),
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
    );
  }
}
