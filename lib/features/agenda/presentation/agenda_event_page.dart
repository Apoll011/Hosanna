import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design/illustrations.dart';
import '../../../core/db/database.dart';
import '../../auth/domain/auth_controller.dart';
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
          illustrationAsset: HosannaIllustrations.stateError,
          title: l10n.commonError,
          description: l10n.commonErrorDesc,
        ),
        data: (event) {
          if (event == null || event.isDeleted) {
            return EmptyState(
              illustrationAsset: HosannaIllustrations.emptyAgenda,
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
    final categories = AgendaResponsibilityCategory.parse(
      ref.watch(authControllerProvider).organization?.responsibilityCategoryMaps,
    );

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
            (r) => _ResponsibilityCard(
              responsibility: r,
              categories: categories,
            ),
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
  const _ResponsibilityCard({
    required this.responsibility,
    required this.categories,
  });

  final AgendaResponsibility responsibility;
  final List<AgendaResponsibilityCategory> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = AgendaResponsibilityCategory.find(
      responsibility.categoryId,
      categories: categories,
    );
    final roleLabel = category?.label ??
        AgendaResponsibilityCategory.labelFor(
          responsibility.categoryId,
          categories: categories,
        );
    final assignees = responsibility.assignees;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconFor(category?.icon),
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    roleLabel.isEmpty
                        ? l10n.agendaFieldResponsibilities
                        : roleLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (assignees.isEmpty)
              Text(
                l10n.agendaUnassigned,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              ...assignees.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          _initials(a.name),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        roleLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  IconData _iconFor(String? iconKey) {
    return switch (iconKey) {
      'mic' => Icons.mic_none_rounded,
      'music' => Icons.music_note_rounded,
      'volume' => Icons.volume_up_outlined,
      'light' => Icons.lightbulb_outline_rounded,
      'monitor' => Icons.monitor_outlined,
      'book' => Icons.menu_book_outlined,
      'heart' => Icons.favorite_border_rounded,
      _ => Icons.badge_outlined,
    };
  }
}
