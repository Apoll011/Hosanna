import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/service_repository.dart';

/// Common date formats used for search, so queries like `dd/MM/yyyy`,
/// `MM-dd-yyyy`, `yyyy.MM.dd`, etc. match however the user types the date.
final _dateSearchFormats = [
  DateFormat('dd/MM/yyyy'),
  DateFormat('MM/dd/yyyy'),
  DateFormat('yyyy/MM/dd'),
  DateFormat('dd-MM-yyyy'),
  DateFormat('MM-dd-yyyy'),
  DateFormat('yyyy-MM-dd'),
  DateFormat('dd.MM.yyyy'),
  DateFormat('MM.dd.yyyy'),
  DateFormat('yyyy.MM.dd'),
  DateFormat('d/M/yyyy'),
  DateFormat('M/d/yyyy'),
  DateFormat('yyyy/M/d'),
  DateFormat('ddMMyyyy'),
  DateFormat('MMddyyyy'),
  DateFormat('yyyyMMdd'),
];

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
                AsyncValue(hasError: true) => ErrorState(
                  title: l10n.commonError,
                  description: l10n.commonErrorDesc,
                  retryLabel: l10n.commonRetry,
                  onRetry: _refresh,
                  scrollable: true,
                ),
                AsyncValue(:final value?) => _ServiceList(
                  services: _filtered(value),
                  hasQuery: _search.text.trim().isNotEmpty,
                  onClearSearch: () {
                    _search.clear();
                    setState(() => _searchOpen = false);
                  },
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
    final locale = Localizations.localeOf(context).toString();
    final localizedDateFormat = DateFormat.yMMMd(locale);
    return services.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      final date = DateTime.tryParse(s.date);
      if (date == null) return s.date.toLowerCase().contains(q);
      if (localizedDateFormat.format(date).toLowerCase().contains(q)) {
        return true;
      }
      return _dateSearchFormats.any(
        (f) => f.format(date).toLowerCase().contains(q),
      );
    }).toList();
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({
    required this.services,
    required this.hasQuery,
    required this.onClearSearch,
  });

  final List<ServiceRow> services;
  final bool hasQuery;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (services.isEmpty) {
      if (hasQuery) {
        return EmptyState(
          icon: Icons.search_off_outlined,
          title: l10n.servicesNoResults,
          description: l10n.servicesNoResultsDesc,
          primaryLabel: l10n.songsClearSearch,
          primaryIcon: Icons.search_off_outlined,
          onPrimary: onClearSearch,
          scrollable: true,
        );
      }
      return EmptyState(
        icon: Icons.event_note_outlined,
        title: l10n.servicesEmpty,
        description: l10n.servicesEmptyDesc,
        scrollable: true,
      );
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
