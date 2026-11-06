import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/shell_modal.dart';
import 'service_filters.dart';

String serviceSortLabel(AppLocalizations l10n, ServiceSort sort) {
  return switch (sort) {
    ServiceSort.date => l10n.servicesSortDate,
    ServiceSort.name => l10n.servicesSortName,
  };
}

String serviceDateFilterLabel(AppLocalizations l10n, ServiceDateFilter filter) {
  return switch (filter) {
    ServiceDateFilter.all => l10n.servicesFilterDateAll,
    ServiceDateFilter.upcoming => l10n.servicesFilterUpcoming,
    ServiceDateFilter.past => l10n.servicesFilterPast,
    ServiceDateFilter.today => l10n.servicesFilterToday,
    ServiceDateFilter.thisWeek => l10n.servicesFilterThisWeek,
    ServiceDateFilter.thisMonth => l10n.servicesFilterThisMonth,
  };
}

String serviceArchiveFilterLabel(
  AppLocalizations l10n,
  ServiceArchiveFilter filter,
) {
  return switch (filter) {
    ServiceArchiveFilter.active => l10n.servicesFilterActive,
    ServiceArchiveFilter.archived => l10n.servicesFilterArchivedOnly,
    ServiceArchiveFilter.all => l10n.servicesFilterIncludeArchived,
  };
}

String serviceContentFilterLabel(
  AppLocalizations l10n,
  ServiceContentFilter filter,
) {
  return switch (filter) {
    ServiceContentFilter.any => l10n.servicesFilterContentAny,
    ServiceContentFilter.withSongs => l10n.servicesFilterWithSongs,
    ServiceContentFilter.withNotes => l10n.servicesFilterWithNotes,
    ServiceContentFilter.emptyPlan => l10n.servicesFilterEmptyPlan,
  };
}

/// AppBar filter button with an active-count badge.
class ServiceFilterButton extends StatelessWidget {
  const ServiceFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: l10n.servicesFilter,
        onPressed: onPressed,
      ),
    );
  }
}

Future<void> showServiceFilterSheet(
  BuildContext context, {
  required ServiceFilterSettings initial,
  required ValueChanged<ServiceFilterSettings> onChanged,
}) {
  return showShellModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
      ),
      child: ServiceFilterSheet(initial: initial, onChanged: onChanged),
    ),
  );
}

/// Live-updating filter/sort sheet for the services list.
class ServiceFilterSheet extends StatefulWidget {
  const ServiceFilterSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final ServiceFilterSettings initial;
  final ValueChanged<ServiceFilterSettings> onChanged;

  @override
  State<ServiceFilterSheet> createState() => _ServiceFilterSheetState();
}

class _ServiceFilterSheetState extends State<ServiceFilterSheet> {
  late ServiceFilterSettings _draft = widget.initial;

  void _apply(ServiceFilterSettings next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.servicesFilter,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!_draft.isDefault)
                  TextButton(
                    onPressed: () => _apply(const ServiceFilterSettings()),
                    child: Text(l10n.songsClearFilters),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _sectionHeader(l10n.songsSortBy),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in ServiceSort.values)
                  ChoiceChip(
                    label: Text(serviceSortLabel(l10n, sort)),
                    selected: _draft.sort == sort,
                    onSelected: (_) => _apply(_draft.copyWith(sort: sort)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.songsSortAscending),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.songsSortDescending),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                ),
              ],
              selected: {_draft.sortAscending},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  _apply(_draft.copyWith(sortAscending: selection.first)),
            ),
            const Divider(height: 32),
            _sectionHeader(l10n.servicesFilterWhen),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in ServiceDateFilter.values)
                  ChoiceChip(
                    label: Text(serviceDateFilterLabel(l10n, filter)),
                    selected: _draft.dateFilter == filter,
                    onSelected: (_) =>
                        _apply(_draft.copyWith(dateFilter: filter)),
                  ),
              ],
            ),
            const Divider(height: 32),
            _sectionHeader(l10n.servicesFilterStatus),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in ServiceArchiveFilter.values)
                  ChoiceChip(
                    label: Text(serviceArchiveFilterLabel(l10n, filter)),
                    selected: _draft.archiveFilter == filter,
                    onSelected: (_) =>
                        _apply(_draft.copyWith(archiveFilter: filter)),
                  ),
              ],
            ),
            const Divider(height: 32),
            _sectionHeader(l10n.servicesFilterContent),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in ServiceContentFilter.values)
                  ChoiceChip(
                    label: Text(serviceContentFilterLabel(l10n, filter)),
                    selected: _draft.contentFilter == filter,
                    onSelected: (_) =>
                        _apply(_draft.copyWith(contentFilter: filter)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Compact chip row summarizing non-default filters.
class ServiceActiveFilterChips extends StatelessWidget {
  const ServiceActiveFilterChips({
    super.key,
    required this.settings,
    required this.onOpenFilters,
    required this.onReset,
  });

  final ServiceFilterSettings settings;
  final VoidCallback onOpenFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (settings.isDefault) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final chips = <String>[
      if (settings.dateFilter != ServiceDateFilter.all)
        serviceDateFilterLabel(l10n, settings.dateFilter),
      if (settings.archiveFilter != ServiceArchiveFilter.active)
        serviceArchiveFilterLabel(l10n, settings.archiveFilter),
      if (settings.contentFilter != ServiceContentFilter.any)
        serviceContentFilterLabel(l10n, settings.contentFilter),
      if (settings.sort != ServiceSort.date || settings.sortAscending)
        '${serviceSortLabel(l10n, settings.sort)}'
        '${settings.sortAscending ? ' ↑' : ' ↓'}',
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          for (final label in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(label),
                onPressed: onOpenFilters,
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
            label: Text(l10n.songsClearFilters),
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}
