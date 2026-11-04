import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../services/data/service_repository.dart';
import '../data/agenda_repository.dart';
import '../domain/agenda_models.dart';

/// Full event details — mirrors the Studio agenda sidebar fields.
class AgendaEventPage extends ConsumerWidget {
  const AgendaEventPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref.watch(agendaEventByIdProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agendaEventDetails),
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          title: l10n.commonError,
          description: l10n.commonErrorDesc,
        ),
        data: (event) {
          if (event == null || event.isDeleted) {
            return EmptyState(
              icon: Icons.event_busy_outlined,
              title: l10n.agendaEventNotFound,
              description: l10n.agendaEventNotFoundBody,
            );
          }
          return _EventBody(event: event);
        },
      ),
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({required this.event});

  final AgendaEventRow event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime.tryParse(event.date);
    final dateLabel = date == null
        ? event.date
        : DateFormat.yMMMMEEEEd(locale).format(date);
    final end = agendaEndTime(event.time, event.durationMinutes);
    final timeLabel = end == null ? event.time : '${event.time} – $end';
    final responsibilities =
        AgendaResponsibility.parse(event.responsibilities);

    final linkedId = event.linkedServiceId;
    final linkedAsync = linkedId == null || linkedId.isEmpty
        ? null
        : ref.watch(serviceByIdProvider(linkedId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          event.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(Icons.category_outlined, size: 16, color: scheme.primary),
              label: Text(event.type),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            if (event.durationMinutes > 0)
              Chip(
                avatar: Icon(
                  Icons.timelapse_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                label: Text(l10n.agendaMinutes(event.durationMinutes)),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.agendaFieldDate,
              value: dateLabel,
            ),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: l10n.agendaFieldTime,
              value: timeLabel,
            ),
            if (event.location != null && event.location!.isNotEmpty)
              _InfoRow(
                icon: Icons.place_outlined,
                label: l10n.agendaFieldLocation,
                value: event.location!,
              ),
          ],
        ),
        if (linkedId != null && linkedId.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LinkedServiceTile(
            serviceAsync: linkedAsync!,
            onOpen: (id) => context.push('/services/$id'),
          ),
        ],
        if (event.notes != null && event.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.agendaFieldNotes,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              event.notes!.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
        if (responsibilities.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.agendaFieldResponsibilities,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...responsibilities.map(
            (r) => _ResponsibilityCard(responsibility: r),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedServiceTile extends StatelessWidget {
  const _LinkedServiceTile({
    required this.serviceAsync,
    required this.onOpen,
  });

  final AsyncValue<ServiceRow?> serviceAsync;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return serviceAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, _) => const SizedBox.shrink(),
      data: (service) {
        if (service == null || service.isDeleted) {
          return const SizedBox.shrink();
        }
        final date = DateTime.tryParse(service.date);
        final dateLabel = date == null
            ? service.date
            : DateFormat.yMMMd(locale).format(date);
        return Material(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpen(service.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  Icon(Icons.music_note_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.agendaLinkedService,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          dateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, color: scheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResponsibilityCard extends StatelessWidget {
  const _ResponsibilityCard({required this.responsibility});

  final AgendaResponsibility responsibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = responsibility.assignees.map((a) => a.name).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names.isEmpty ? l10n.agendaUnassigned : names,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (responsibility.assignees.length > 1)
                    Text(
                      l10n.agendaAssigneeCount(responsibility.assignees.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
