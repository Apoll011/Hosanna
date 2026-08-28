import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_repository.dart';

class ServiceDetailPage extends ConsumerStatefulWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final serviceAsync = ref.watch(serviceByIdProvider(widget.serviceId));
    final service = serviceAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(service?.name ?? l10n.servicesTitle)),
      body: serviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (service) => service == null
            ? Center(child: Text(l10n.servicesEmpty))
            : _detail(service: service),
      ),
    );
  }

  Widget _detail({required ServiceRow service}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateTime.tryParse(service.date);
    final dateLabel = date == null
        ? ''
        : DateFormat.yMMMEd(Localizations.localeOf(context).toString())
            .format(date);

    final elements = List<ServiceElement>.from(service.elements)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dateLabel.isNotEmpty)
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        if (service.notes != null && service.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.servicesGeneralNotes),
          Text(service.notes!),
        ],
        const SizedBox(height: 16),
        _SectionHeader(title: l10n.servicesOrderedItems),
        if (elements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.servicesNoItems),
          )
        else
          for (final element in elements) _ElementTile(element: element),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ElementTile extends StatelessWidget {
  const _ElementTile({required this.element});

  final ServiceElement element;

  IconData get _icon => switch (element.type) {
        'song' => Icons.music_note,
        'welcome' => Icons.waving_hand_outlined,
        'scripture' => Icons.menu_book_outlined,
        'message' => Icons.mic_none,
        'reading' => Icons.auto_stories_outlined,
        'announcement' => Icons.campaign_outlined,
        _ => Icons.label_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icon, color: theme.colorScheme.primary),
        title: Text(element.title.isEmpty ? element.type : element.title),
        subtitle: element.notes != null && element.notes!.isNotEmpty
            ? Text(element.notes!, maxLines: 3, overflow: TextOverflow.ellipsis)
            : null,
      ),
    );
  }
}
