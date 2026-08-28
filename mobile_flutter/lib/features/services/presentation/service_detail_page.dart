import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/presentation/song_body_renderer.dart';
import '../../songs/presentation/song_toolbar.dart';
import '../data/service_repository.dart';

/// Musician view of a service: the first song (or element) is shown in a
/// full-screen song view, and the rest of the service order lives in a
/// slide-over menu, mirroring the React `MusicianServiceView`.
class ServiceDetailPage extends ConsumerStatefulWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentElementId;

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
      key: _scaffoldKey,
      drawer: service == null
          ? null
          : _OrderDrawer(
              service: service,
              currentElementId: _currentElementId,
              onSelect: (id) {
                setState(() => _currentElementId = id);
                _scaffoldKey.currentState?.closeDrawer();
              },
              onLeave: () => context.pop(),
            ),
      body: serviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (service) => service == null
            ? Center(child: Text(l10n.servicesEmpty))
            : _body(service: service),
      ),
    );
  }

  List<ServiceElement> _sorted(ServiceRow service) {
    final elements = List<ServiceElement>.from(service.elements)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return elements;
  }

  Widget _body({required ServiceRow service}) {
    final l10n = AppLocalizations.of(context);
    final elements = _sorted(service);

    if (elements.isEmpty) {
      return Center(child: Text(l10n.servicesNoItems));
    }

    // Resolve the current element, defaulting to the first song element (the
    // React app opens the service on the first cântico).
    final firstSong =
        elements.where((e) => e.type == 'song' && e.songId != null).firstOrNull;
    final current = elements.firstWhere(
      (e) => e.id == _currentElementId,
      orElse: () => firstSong ?? elements.first,
    );
    _currentElementId ??= current.id;

    // Song elements (in service order) for prev/next navigation.
    final songElements =
        elements.where((e) => e.type == 'song' && e.songId != null).toList();
    final songIndex = songElements.indexWhere((e) => e.id == current.id);

    return Column(
      children: [
        _MusicianTopBar(
          serviceName: service.name,
          itemLabel: l10n.servicesItemOf(
            elements.indexWhere((e) => e.id == current.id) + 1,
            elements.length,
          ),
          onOpenOrder: () => _scaffoldKey.currentState?.openDrawer(),
          onLeave: () => context.pop(),
        ),
        Expanded(
          child: current.type == 'song' && current.songId != null
              ? _SongElementView(
                  songId: current.songId!,
                  canPrev: songIndex > 0,
                  canNext: songIndex >= 0 && songIndex < songElements.length - 1,
                  positionLabel:
                      '${songIndex + 1} / ${songElements.length}',
                  onPrev: () => setState(() {
                    _currentElementId = songElements[songIndex - 1].id;
                  }),
                  onNext: () => setState(() {
                    _currentElementId = songElements[songIndex + 1].id;
                  }),
                )
              : _NonSongElementView(element: current),
        ),
      ],
    );
  }
}

class _MusicianTopBar extends StatelessWidget {
  const _MusicianTopBar({
    required this.serviceName,
    required this.itemLabel,
    required this.onOpenOrder,
    required this.onLeave,
  });

  final String serviceName;
  final String itemLabel;
  final VoidCallback onOpenOrder;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: l10n.servicesOrderTitle,
              onPressed: onOpenOrder,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    itemLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SongToolbarButton(),
            TextButton.icon(
              onPressed: onLeave,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.servicesLeave),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongElementView extends ConsumerWidget {
  const _SongElementView({required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(songId));

    return songAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.commonError)),
      data: (song) => song == null
          ? Center(child: Text(l10n.songsNoResults))
          : SongBodyRenderer(content: song.content),
    );
  }
}

class _NonSongElementView extends StatelessWidget {
  const _NonSongElementView({required this.element});

  final ServiceElement element;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = _elementMeta(l10n, element.type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: meta.color.withValues(alpha: 0.3)),
                ),
                child: Icon(meta.icon, color: meta.color, size: 28),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  meta.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: meta.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                element.title.isNotEmpty ? element.title : meta.label,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              if (element.passage != null && element.passage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    element.passage!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (element.content != null && element.content!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    element.content!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              if (element.notes != null && element.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _NotesCard(notes: element.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.servicesNotes.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _OrderDrawer extends StatelessWidget {
  const _OrderDrawer({
    required this.service,
    required this.currentElementId,
    required this.onSelect,
    required this.onLeave,
  });

  final ServiceRow service;
  final String? currentElementId;
  final ValueChanged<String> onSelect;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final elements = List<ServiceElement>.from(service.elements)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.servicesOrderTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.servicesMoments(elements.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (var i = 0; i < elements.length; i++)
                    _OrderItem(
                      index: i,
                      element: elements[i],
                      selected: elements[i].id == currentElementId,
                      onTap: () => onSelect(elements[i].id),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.logout),
                label: Text(l10n.servicesLeaveMode),
                onPressed: onLeave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends ConsumerWidget {
  const _OrderItem({
    required this.index,
    required this.element,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final ServiceElement element;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = _elementMeta(l10n, element.type);

    final songAsync = element.songId == null
        ? null
        : ref.watch(songByIdProvider(element.songId!));
    final song = songAsync?.valueOrNull;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(meta.icon, size: 18, color: meta.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.type == 'song'
                          ? (song?.title ?? l10n.servicesElementSong)
                          : (element.title.isNotEmpty
                              ? element.title
                              : meta.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      element.type == 'song'
                          ? (song?.artist ?? l10n.servicesElementSong)
                          : meta.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementMeta {
  const _ElementMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_ElementMeta _elementMeta(AppLocalizations l10n, String type) {
  return switch (type) {
    'song' => _ElementMeta(
        l10n.servicesElementSong,
        Icons.music_note,
        const Color(0xFF0284C7),
      ),
    'welcome' => _ElementMeta(
        l10n.servicesElementWelcome,
        Icons.waving_hand_outlined,
        const Color(0xFF2563EB),
      ),
    'scripture' => _ElementMeta(
        l10n.servicesElementScripture,
        Icons.menu_book_outlined,
        const Color(0xFF9333EA),
      ),
    'message' => _ElementMeta(
        l10n.servicesElementMessage,
        Icons.chat_bubble_outline,
        const Color(0xFFD97706),
      ),
    'announcement' => _ElementMeta(
        l10n.servicesElementAnnouncement,
        Icons.campaign_outlined,
        const Color(0xFF059669),
      ),
    _ => _ElementMeta(
        l10n.servicesElementDefault,
        Icons.label_outline,
        const Color(0xFF64748B),
      ),
  };
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
