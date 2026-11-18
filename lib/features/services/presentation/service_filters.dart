import '../../../core/db/database.dart';

/// Which services to include by archive flag.
enum ServiceArchiveFilter {
  /// Non-archived only (default list).
  active,

  /// Archived only.
  archived,

  /// Both.
  all,
}

/// Calendar window relative to "today" (local date).
enum ServiceDateFilter {
  all,
  upcoming,
  past,
  today,
  thisWeek,
  thisMonth,
}

/// Content / plan shape filters.
enum ServiceContentFilter {
  any,
  withSongs,
  withNotes,
  emptyPlan,
}

enum ServiceSort { date, name }

/// Sort + filter settings for the services list.
class ServiceFilterSettings {
  const ServiceFilterSettings({
    this.sort = ServiceSort.date,
    this.sortAscending = false,
    this.dateFilter = ServiceDateFilter.all,
    this.archiveFilter = ServiceArchiveFilter.active,
    this.contentFilter = ServiceContentFilter.any,
  });

  final ServiceSort sort;
  final bool sortAscending;
  final ServiceDateFilter dateFilter;
  final ServiceArchiveFilter archiveFilter;
  final ServiceContentFilter contentFilter;

  bool get isDefault =>
      sort == ServiceSort.date &&
      !sortAscending &&
      dateFilter == ServiceDateFilter.all &&
      archiveFilter == ServiceArchiveFilter.active &&
      contentFilter == ServiceContentFilter.any;

  int get activeFilterCount {
    var count = 0;
    if (sort != ServiceSort.date || sortAscending) count += 1;
    if (dateFilter != ServiceDateFilter.all) count += 1;
    if (archiveFilter != ServiceArchiveFilter.active) count += 1;
    if (contentFilter != ServiceContentFilter.any) count += 1;
    return count;
  }

  ServiceFilterSettings copyWith({
    ServiceSort? sort,
    bool? sortAscending,
    ServiceDateFilter? dateFilter,
    ServiceArchiveFilter? archiveFilter,
    ServiceContentFilter? contentFilter,
  }) {
    return ServiceFilterSettings(
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
      dateFilter: dateFilter ?? this.dateFilter,
      archiveFilter: archiveFilter ?? this.archiveFilter,
      contentFilter: contentFilter ?? this.contentFilter,
    );
  }
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the calendar week containing [day] (local).
DateTime _startOfWeek(DateTime day) {
  final d = _dayOf(day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

bool _matchesDateFilter(
  DateTime? serviceDay,
  ServiceDateFilter filter,
  DateTime today,
) {
  if (filter == ServiceDateFilter.all) return true;
  if (serviceDay == null) return false;

  switch (filter) {
    case ServiceDateFilter.all:
      return true;
    case ServiceDateFilter.upcoming:
      return !serviceDay.isBefore(today);
    case ServiceDateFilter.past:
      return serviceDay.isBefore(today);
    case ServiceDateFilter.today:
      return serviceDay == today;
    case ServiceDateFilter.thisWeek:
      final start = _startOfWeek(today);
      final end = start.add(const Duration(days: 7));
      return !serviceDay.isBefore(start) && serviceDay.isBefore(end);
    case ServiceDateFilter.thisMonth:
      return serviceDay.year == today.year && serviceDay.month == today.month;
  }
}

bool _matchesContent(ServiceRow service, ServiceContentFilter filter) {
  switch (filter) {
    case ServiceContentFilter.any:
      return true;
    case ServiceContentFilter.withSongs:
      return service.elements.any((e) => e.type == 'song');
    case ServiceContentFilter.withNotes:
      final notes = service.notes?.trim() ?? '';
      return notes.isNotEmpty;
    case ServiceContentFilter.emptyPlan:
      return service.elements.isEmpty;
  }
}

bool _matchesArchive(ServiceRow service, ServiceArchiveFilter filter) {
  return switch (filter) {
    ServiceArchiveFilter.active => !service.archived,
    ServiceArchiveFilter.archived => service.archived,
    ServiceArchiveFilter.all => true,
  };
}

/// Applies [settings] (and optional search [query]) to [services].
List<ServiceRow> applyServiceFilters(
  Iterable<ServiceRow> services, {
  required ServiceFilterSettings settings,
  String query = '',
  DateTime? now,
  required bool Function(ServiceRow service, String query) matchesSearch,
}) {
  final today = _dayOf(now ?? DateTime.now());
  final q = query.trim();

  final filtered = services.where((service) {
    if (!_matchesArchive(service, settings.archiveFilter)) return false;
    final day = DateTime.tryParse(service.date);
    final serviceDay = day == null ? null : _dayOf(day);
    if (!_matchesDateFilter(serviceDay, settings.dateFilter, today)) {
      return false;
    }
    if (!_matchesContent(service, settings.contentFilter)) return false;
    if (q.isNotEmpty && !matchesSearch(service, q)) return false;
    return true;
  }).toList();

  filtered.sort((a, b) {
    int cmp;
    switch (settings.sort) {
      case ServiceSort.name:
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case ServiceSort.date:
        cmp = a.date.compareTo(b.date);
    }
    if (cmp == 0) {
      cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    return settings.sortAscending ? cmp : -cmp;
  });

  return filtered;
}
