import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_repository.dart';

class ServiceListPage extends ConsumerStatefulWidget {
  const ServiceListPage({super.key});

  @override
  ConsumerState<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends ConsumerState<ServiceListPage> {
  final _search = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.servicesSearchHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(l10n.servicesTitle),
        leading: const ShellLeadingButton(),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            tooltip: l10n.commonSearch,
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _search.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (servicesAsync) {
                AsyncValue(hasError: true) => _Empty(
                  message: l10n.commonError,
                  onRefresh: _refresh,
                ),
                AsyncValue(:final value?) => _ServiceList(
                  services: _filtered(value),
                  onRefresh: _refresh,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ServiceRow> _filtered(List<ServiceRow> services) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return services.where((s) => !s.archived).toList();
    return services.where((s) {
      final date = DateTime.tryParse(s.date);
      final dateLabel = date == null
          ? ''
          : DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(date);
      return s.name.toLowerCase().contains(q) ||
          s.date.toLowerCase().contains(q) ||
          dateLabel.toLowerCase().contains(q);
    }).toList();
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
          title: Text(
            service.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              dateLabel,
              if (service.archived) l10n.servicesArchived,
            ].where((e) => e.isNotEmpty).join(' · '),
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
