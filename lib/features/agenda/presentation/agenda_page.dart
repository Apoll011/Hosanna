import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../data/agenda_repository.dart';
import '../domain/agenda_models.dart';

/// Calendar-style agenda: horizontal day strip of dates that have events,
/// with the selected day's events listed below.
class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  String? _selectedDate;
  final ScrollController _dayStripController = ScrollController();

  @override
  void dispose() {
    _dayStripController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  void _scrollDayStripTo(String date, List<String> dates) {
    final index = dates.indexOf(date);
    if (index < 0 || !_dayStripController.hasClients) return;
    const itemExtent = 82.0; // 72 width + 10 separator
    final target = (index * itemExtent) - 24;
    _dayStripController.animateTo(
      target.clamp(0.0, _dayStripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _ensureSelection(Map<String, List<AgendaEventRow>> byDate) {
    if (byDate.isEmpty) {
      if (_selectedDate != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedDate = null);
        });
      }
      return;
    }
    if (_selectedDate != null && byDate.containsKey(_selectedDate)) return;

    final today = agendaDayKey(DateTime.now());
    final dates = byDate.keys.toList()..sort();
    final String next;
    if (byDate.containsKey(today)) {
      next = today;
    } else {
      next = dates.firstWhere(
        (d) => d.compareTo(today) >= 0,
        orElse: () => dates.last,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedDate = next);
      _scrollDayStripTo(next, dates);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(agendaEventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeadingButton(),
        title: Text(l10n.navAgenda),
      ),
      body: eventsAsync.when(
        loading: () => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        error: (_, _) => RefreshIndicator(
          onRefresh: _refresh,
          child: ErrorState(
            title: l10n.commonError,
            description: l10n.commonErrorDesc,
            retryLabel: l10n.commonRetry,
            onRetry: _refresh,
            scrollable: true,
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: EmptyState(
                icon: Icons.event_outlined,
                title: l10n.agendaEmptyTitle,
                description: l10n.agendaEmptyBody,
                scrollable: true,
              ),
            );
          }

          final byDate = <String, List<AgendaEventRow>>{};
          for (final e in events) {
            byDate.putIfAbsent(e.date, () => []).add(e);
          }
          _ensureSelection(byDate);

          final dates = byDate.keys.toList()..sort();
          final selected = _selectedDate;
          final dayEvents = selected == null
              ? const <AgendaEventRow>[]
              : byDate[selected] ?? const [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DayStrip(
                dates: dates,
                selectedDate: selected,
                controller: _dayStripController,
                eventCounts: {
                  for (final e in byDate.entries) e.key: e.value.length,
                },
                onSelect: (date) => setState(() => _selectedDate = date),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _DayEventsList(
                    dateKey: selected,
                    events: dayEvents,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.dates,
    required this.selectedDate,
    required this.controller,
    required this.eventCounts,
    required this.onSelect,
  });

  final List<String> dates;
  final String? selectedDate;
  final ScrollController controller;
  final Map<String, int> eventCounts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final weekdayFmt = DateFormat.E(locale);
    final dayFmt = DateFormat.d(locale);
    final monthFmt = DateFormat.MMM(locale);
    final todayKey = agendaDayKey(DateTime.now());

    return SizedBox(
      height: 108,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = dates[index];
          final date = DateTime.tryParse(key);
          final selected = key == selectedDate;
          final isToday = key == todayKey;
          final count = eventCounts[key] ?? 0;

          return Material(
            color: selected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelect(key),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : isToday
                            ? scheme.primary.withValues(alpha: 0.45)
                            : scheme.outline.withValues(alpha: 0.15),
                    width: isToday && !selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date == null ? '—' : weekdayFmt.format(date).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: selected
                            ? scheme.onPrimary.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? '?' : dayFmt.format(date),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                    Text(
                      date == null ? '' : monthFmt.format(date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.onPrimary.withValues(alpha: 0.8)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _EventDots(
                      count: count,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventDots extends StatelessWidget {
  const _EventDots({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(0, 3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(n, (i) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      }),
    );
  }
}

class _DayEventsList extends StatelessWidget {
  const _DayEventsList({
    required this.dateKey,
    required this.events,
  });

  final String? dateKey;
  final List<AgendaEventRow> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();

    if (dateKey == null || events.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        title: l10n.agendaNoEventsForDay,
        description: l10n.agendaNoEventsForDayBody,
      );
    }

    final date = DateTime.tryParse(dateKey!);
    final heading = date == null
        ? dateKey!
        : DateFormat.yMMMMEEEEd(locale).format(date);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + shellBottomContentPadding(context),
      ),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 4),
            child: Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final event = events[index - 1];
        final end = agendaEndTime(event.time, event.durationMinutes);
        final timeLabel = end == null ? event.time : '${event.time} – $end';
        final responsibilities =
            AgendaResponsibility.parse(event.responsibilities);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/agenda/${event.id}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              event.type,
                              if (event.location != null &&
                                  event.location!.isNotEmpty)
                                event.location!,
                              if (responsibilities.isNotEmpty)
                                l10n.agendaResponsibilityCount(
                                  responsibilities.fold<int>(
                                    0,
                                    (n, r) => n + r.assignees.length,
                                  ),
                                ),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
            ),
          ),
        );
      },
    );
  }
}
