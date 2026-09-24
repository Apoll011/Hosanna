import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_repository.dart';

/// Opens the next upcoming service, forwarding to its detail page.
///
/// Reached through the "Next service" launcher shortcut
/// (`hosanna://services/next`): a static shortcut cannot know a service id, so
/// the id is resolved here from the synced services.
class NextServicePage extends ConsumerStatefulWidget {
  const NextServicePage({super.key});

  @override
  ConsumerState<NextServicePage> createState() => _NextServicePageState();
}

class _NextServicePageState extends ConsumerState<NextServicePage> {
  bool _forwarded = false;

  /// Replaces this placeholder with the service detail page. Deferred to the
  /// next frame because the target is decided while building the placeholder.
  void _forward(String serviceId) {
    if (_forwarded) return;
    _forwarded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.replace('/services/$serviceId');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.servicesNextService)),
      body: switch (servicesAsync) {
        AsyncValue(hasError: true) => _Message(message: l10n.commonError),
        AsyncValue(:final value?) => _buildBody(value, l10n),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildBody(List<ServiceRow> services, AppLocalizations l10n) {
    final next = nextUpcomingService(services);
    if (next == null) return _Message(message: l10n.servicesNoUpcoming);

    _forward(next.id);
    return const Center(child: CircularProgressIndicator());
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
