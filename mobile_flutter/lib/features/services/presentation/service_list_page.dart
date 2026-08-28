import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/sync_status_banner.dart';
import '../data/service_repository.dart';

class ServiceListPage extends ConsumerWidget {
  const ServiceListPage({super.key});

  Future<void> _refresh(WidgetRef ref) =>
      ref.read(syncControllerProvider.notifier).syncAll();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servicesTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l10n.commonOpenDrawer,
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SyncStatusBanner(compact: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: switch (servicesAsync) {
                AsyncValue(hasError: true) => _Empty(
                    message: l10n.commonError,
                    onRefresh: () => _refresh(ref),
                  ),
                AsyncValue(:final value?) => _ServiceList(
                    services: value,
                    onRefresh: () => _refresh(ref),
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.services, required this.onRefresh});

  final List<ServiceRow> services;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (services.isEmpty) {
      return _Empty(message: l10n.servicesEmpty, onRefresh: onRefresh);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final date = DateTime.tryParse(service.date);
        final dateLabel = date == null
            ? ''
            : DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(date);
        return ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [dateLabel, if (service.archived) l10n.settingsOffline]
                .where((e) => e.isNotEmpty)
                .join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/services/${service.id}'),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
