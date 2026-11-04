import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_leading_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../data/agenda_repository.dart';

/// Read-only agenda list fed by replication (`agendaEvents`).
class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(agendaEventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeadingButton(),
        title: Text(l10n.navAgenda),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: shellBottomContentPadding(context)),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (events) {
            if (events.isEmpty) {
              return EmptyState(
                icon: Icons.event_outlined,
                title: l10n.agendaEmptyTitle,
                description: l10n.agendaEmptyBody,
              );
            }
            return ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = events[index];
                final subtitle = [
                  e.date,
                  if (e.time.isNotEmpty) e.time,
                  if (e.location != null && e.location!.isNotEmpty) e.location!,
                ].join(' · ');
                return ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(e.title),
                  subtitle: Text(subtitle),
                  trailing: Text(
                    e.type,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
