import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/design/tokens.dart';
import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bar_search_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hosanna_surface.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../data/service_repository.dart';
import 'service_filter_widgets.dart';
import 'service_filters.dart';

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
  ServiceFilterSettings _filters = const ServiceFilterSettings();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  void _openFilterSheet() {
    showServiceFilterSheet(
      context,
      initial: _filters,
      onChanged: (next) => setState(() => _filters = next),
    );
  }

  void _clearSearch() {
    setState(() {
      _search.clear();
      _searchOpen = false;
    });
  }

  void _resetFilters() {
    setState(() => _filters = const ServiceFilterSettings());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final hasQuery = _search.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? AppBarSearchField(
                controller: _search,
                hintText: l10n.servicesSearchHint,
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
          ServiceFilterButton(
            activeCount: _filters.activeFilterCount,
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          ServiceActiveFilterChips(
            settings: _filters,
            onOpenFilters: _openFilterSheet,
            onReset: _resetFilters,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (servicesAsync) {
                AsyncValue(hasError: true) => ErrorState(
                    illustrationAsset: HosannaIllustrations.stateError,
                    title: l10n.commonError,
                    description: l10n.commonErrorDesc,
                    retryLabel: l10n.commonRetry,
                    onRetry: _refresh,
                    scrollable: true,
                  ),
                AsyncValue(:final value?) => _ServiceList(
                    services: _filtered(value),
                    hasQuery: hasQuery,
                    hasFilters: !_filters.isDefault,
                    onClearSearch: _clearSearch,
                    onClearFilters: () {
                      if (hasQuery) _clearSearch();
                      if (!_filters.isDefault) _resetFilters();
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
    final locale = Localizations.localeOf(context).toString();
    final localizedDateFormat = DateFormat.yMMMd(locale);
    return applyServiceFilters(
      services,
      settings: _filters,
      query: _search.text,
      matchesSearch: (s, q) {
        final needle = q.toLowerCase();
        if (s.name.toLowerCase().contains(needle)) return true;
        final date = DateTime.tryParse(s.date);
        if (date == null) return s.date.toLowerCase().contains(needle);
        if (localizedDateFormat.format(date).toLowerCase().contains(needle)) {
          return true;
        }
        return _dateSearchFormats.any(
          (f) => f.format(date).toLowerCase().contains(needle),
        );
      },
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({
    required this.services,
    required this.hasQuery,
    required this.hasFilters,
    required this.onClearSearch,
    required this.onClearFilters,
  });

  final List<ServiceRow> services;
  final bool hasQuery;
  final bool hasFilters;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (services.isEmpty) {
      if (hasQuery || hasFilters) {
        return EmptyState(
          illustrationAsset: HosannaIllustrations.emptySearch,
          title: l10n.servicesNoResults,
          description: hasFilters && !hasQuery
              ? l10n.servicesNoResultsFiltersDesc
              : l10n.servicesNoResultsDesc,
          primaryLabel: hasQuery && !hasFilters
              ? l10n.songsClearSearch
              : l10n.songsClearFilters,
          primaryIcon: hasQuery && !hasFilters
              ? Icons.search_off_outlined
              : Icons.filter_alt_off_outlined,
          onPrimary: hasQuery && !hasFilters ? onClearSearch : onClearFilters,
          scrollable: true,
        );
      }
      return EmptyState(
        illustrationAsset: HosannaIllustrations.emptyServices,
        title: l10n.servicesEmpty,
        description: l10n.servicesEmptyDesc,
        scrollable: true,
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + shellBottomContentPadding(context),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final date = DateTime.tryParse(service.date);
        final dateLabel = date == null
            ? ''
            : DateFormat.yMMMd(locale).format(date);
        final isToday = service.date == todayKey;
        final weekday = date == null
            ? ''
            : DateFormat.E(locale).format(date).toUpperCase();
        final dayNum = date == null ? '' : DateFormat.d(locale).format(date);

        return Padding(
          padding: const EdgeInsets.only(bottom: HosannaSpacing.sm),
          child: HosannaSurface(
            elevated: false,
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            onTap: () => context.push('/services/${service.id}'),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isToday
                        ? scheme.primary
                        : scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(HosannaRadii.sm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekday,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isToday
                              ? scheme.onPrimary.withValues(alpha: 0.85)
                              : scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: isToday
                              ? scheme.onPrimary
                              : scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: HosannaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          dateLabel,
                          if (service.archived) l10n.servicesArchived,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
