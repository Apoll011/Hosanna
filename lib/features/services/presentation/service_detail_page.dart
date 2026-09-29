import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/settings_controller.dart';
import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/presentation/song_reader.dart';
import '../../songs/presentation/song_toolbar.dart';
import '../data/service_repository.dart';
import '../data/service_notes_watch.dart';
import 'service_element_meta.dart';
import 'service_order_page.dart';
import 'widgets/horizontal_swipe_navigator.dart';
import 'widgets/service_notes_panel.dart';

/// Entry point for a service. Honours [AppSettings.musicianMode]: musician
/// view opens the first song with a drawer order; otherwise the run-of-show
/// [ServiceOrderPage] is shown.
class ServiceDetailPage extends ConsumerStatefulWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentElementId;
  bool _isAnnotating = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsControllerProvider).keepScreenAwake) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicianMode = ref.watch(settingsControllerProvider).musicianMode;
    if (!musicianMode) {
      return ServiceOrderPage(serviceId: widget.serviceId);
    }

    final l10n = AppLocalizations.of(context);
    final serviceAsync = ref.watch(serviceByIdProvider(widget.serviceId));
    final service = serviceAsync.valueOrNull;

    return Scaffold(
      key: _scaffoldKey,
      // Edge-drag open fights horizontal prev/next swipes in the song reader.
      drawerEnableOpenDragGesture: false,
      drawer: service == null
          ? null
          : _OrderDrawer(
              service: service,
              currentElementId: _currentElementId,
              onSelect: (id) {
                setState(() => _currentElementId = id);
                _scaffoldKey.currentState?.closeDrawer();
              },
              onLeave: () {
                // While open, the drawer holds a local history entry on this
                // page's route, so a bare pop would only dismiss the drawer.
                // Close it first (removing that entry synchronously), then
                // leave the service.
                _scaffoldKey.currentState?.closeDrawer();
                context.pop();
              },
            ),
      body: ServiceNotesIncomingListener(
        serviceId: widget.serviceId,
        onOpenNotes: () => _openNotes(
          context,
          elementType: _currentElementType(serviceAsync.valueOrNull),
        ),
        child: serviceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorState(
            title: l10n.commonError,
            description: l10n.commonErrorDesc,
          ),
          data: (service) => service == null
              ? EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: l10n.servicesNotFound,
                  description: l10n.servicesNotFoundDesc,
                )
              : _body(service: service),
        ),
      ),
    );
  }

  Future<void> _openNotes(BuildContext context, {String? elementType}) async {
    ref.read(serviceNotesWatchProvider(widget.serviceId).notifier).markAllRead();
    await showServiceNotesSheet(
      context,
      serviceId: widget.serviceId,
      elementType: elementType,
    );
    if (mounted) {
      ref.read(serviceNotesWatchProvider(widget.serviceId).notifier).markAllRead();
    }
  }

  String? _currentElementType(ServiceRow? service) {
    if (service == null) return null;
    final elements = _sorted(service);
    if (elements.isEmpty) return null;
    final id = _currentElementId;
    if (id != null) {
      for (final e in elements) {
        if (e.id == id) return e.type;
      }
    }
    return elements
            .where((e) => e.type == 'song' && e.songId != null)
            .firstOrNull
            ?.type ??
        elements.first.type;
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
      return EmptyState(
        icon: Icons.playlist_add_outlined,
        title: l10n.servicesNoItems,
        description: l10n.servicesNoItemsDesc,
      );
    }

    // Resolve the current element, defaulting to the first song element (the
    // React app opens the service on the first cântico).
    final firstSong = elements
        .where((e) => e.type == 'song' && e.songId != null)
        .firstOrNull;
    final current = elements.firstWhere(
      (e) => e.id == _currentElementId,
      orElse: () => firstSong ?? elements.first,
    );
    _currentElementId ??= current.id;

    final elementIndex = elements.indexWhere((e) => e.id == current.id);
    final isSong = current.type == 'song' && current.songId != null;

    // On songs: swipe only between songs. On non-songs: swipe through every
    // element until a song is reached, then song-only nav resumes.
    final songElements = elements
        .where((e) => e.type == 'song' && e.songId != null)
        .toList();
    final songIndex = songElements.indexWhere((e) => e.id == current.id);

    final bool canPrev;
    final bool canNext;
    final String positionLabel;
    final VoidCallback onPrev;
    final VoidCallback onNext;

    if (isSong) {
      canPrev = songIndex > 0;
      canNext = songIndex >= 0 && songIndex < songElements.length - 1;
      positionLabel = '${songIndex + 1} / ${songElements.length}';
      onPrev = () => setState(() {
            _isAnnotating = false;
            _currentElementId = songElements[songIndex - 1].id;
          });
      onNext = () => setState(() {
            _isAnnotating = false;
            _currentElementId = songElements[songIndex + 1].id;
          });
    } else {
      canPrev = elementIndex > 0;
      canNext = elementIndex >= 0 && elementIndex < elements.length - 1;
      positionLabel = '${elementIndex + 1} / ${elements.length}';
      onPrev = () => setState(() {
            _isAnnotating = false;
            _currentElementId = elements[elementIndex - 1].id;
          });
      onNext = () => setState(() {
            _isAnnotating = false;
            _currentElementId = elements[elementIndex + 1].id;
          });
    }

    return Column(
      children: [
        _MusicianTopBar(
          serviceId: widget.serviceId,
          serviceName: service.name,
          itemLabel: l10n.servicesItemOf(
            elementIndex + 1,
            elements.length,
          ),
          onOpenOrder: () => _scaffoldKey.currentState?.openDrawer(),
          onOpenNotes: () => _openNotes(context, elementType: current.type),
          onLeave: () => context.pop(),
          isSong: isSong,
          isAnnotating: _isAnnotating,
          onToggleAnnotation: () {
            setState(() {
              _isAnnotating = !_isAnnotating;
            });
          },
        ),
        Expanded(
          child: isSong
              ? _SongElementView(
                  serviceId: widget.serviceId,
                  songId: current.songId!,
                  notes: current.notes,
                  isAnnotating: _isAnnotating,
                  canPrev: canPrev,
                  canNext: canNext,
                  positionLabel: positionLabel,
                  onPrev: onPrev,
                  onNext: onNext,
                )
              : _NonSongElementView(
                  serviceId: widget.serviceId,
                  element: current,
                  canPrev: canPrev,
                  canNext: canNext,
                  positionLabel: positionLabel,
                  onPrev: onPrev,
                  onNext: onNext,
                ),
        ),
      ],
    );
  }
}

class _MusicianTopBar extends StatelessWidget {
  const _MusicianTopBar({
    required this.serviceId,
    required this.serviceName,
    required this.itemLabel,
    required this.onOpenOrder,
    required this.onOpenNotes,
    required this.onLeave,
    required this.isSong,
    this.isAnnotating = false,
    this.onToggleAnnotation,
  });

  final String serviceId;
  final String serviceName;
  final String itemLabel;
  final VoidCallback onOpenOrder;
  final VoidCallback onOpenNotes;
  final VoidCallback onLeave;
  final bool isSong;
  final bool isAnnotating;
  final VoidCallback? onToggleAnnotation;

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
            IconButton(
              icon: NotesUnreadBadge(
                serviceId: serviceId,
                child: const Icon(Icons.sticky_note_2_outlined),
              ),
              tooltip: l10n.servicesNotes,
              onPressed: onOpenNotes,
            ),
            if (isSong) ...[
              IconButton(
                icon: Icon(
                  isAnnotating ? Icons.edit : Icons.edit_outlined,
                  color: isAnnotating ? theme.colorScheme.primary : null,
                ),
                tooltip: l10n.annotationModeTitle,
                onPressed: onToggleAnnotation,
              ),
              const SongToolbarButton(),
            ],
            // Icon-only Leave avoids overflow on narrow phones; keep the
            // labelled button when there is room.
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = MediaQuery.sizeOf(context).width < 420;
                if (narrow) {
                  return IconButton(
                    onPressed: onLeave,
                    tooltip: l10n.servicesLeave,
                    icon: Icon(
                      Icons.logout,
                      color: theme.colorScheme.error,
                    ),
                  );
                }
                return TextButton.icon(
                  onPressed: onLeave,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.servicesLeave),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SongElementView extends ConsumerWidget {
  const _SongElementView({
    required this.serviceId,
    required this.songId,
    required this.notes,
    required this.isAnnotating,
    required this.canPrev,
    required this.canNext,
    required this.positionLabel,
    required this.onPrev,
    required this.onNext,
  });

  final String serviceId;
  final String songId;

  /// Musician notes attached to this song element in the service order,
  /// shown in a card below the song metadata.
  final String? notes;

  final bool isAnnotating;
  final bool canPrev;
  final bool canNext;
  final String positionLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final songAsync = ref.watch(songByIdProvider(songId));

    return songAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErrorState(
        title: l10n.commonError,
        description: l10n.commonErrorDesc,
      ),
      data: (song) => song == null
          ? EmptyState(
              icon: Icons.music_off_outlined,
              title: l10n.songsNotFound,
              description: l10n.songsNotFoundDesc,
            )
          : SongReader(
              content: song.content,
              notes: notes,
              serviceId: serviceId,
              songId: songId,
              isAnnotating: isAnnotating,
              canPrev: canPrev,
              canNext: canNext,
              positionLabel: positionLabel,
              onPrev: onPrev,
              onNext: onNext,
            ),
    );
  }
}

class _NonSongElementView extends StatelessWidget {
  const _NonSongElementView({
    required this.serviceId,
    required this.element,
    required this.canPrev,
    required this.canNext,
    required this.positionLabel,
    required this.onPrev,
    required this.onNext,
  });

  final String serviceId;
  final ServiceElement element;
  final bool canPrev;
  final bool canNext;
  final String positionLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = serviceElementMeta(l10n, theme.colorScheme, element.type);
    final hasPassage = element.passage != null && element.passage!.isNotEmpty;
    final hasContent = element.content != null && element.content!.isNotEmpty;
    final hasItemNotes = element.notes != null && element.notes!.isNotEmpty;
    final hasBody = hasPassage || hasContent || hasItemNotes;

    return HorizontalSwipeNavigator(
      canPrev: canPrev,
      canNext: canNext,
      positionLabel: positionLabel,
      onPrev: canPrev ? onPrev : null,
      onNext: canNext ? onNext : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasPassage) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
                if (hasContent) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      element.content!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (hasItemNotes) ...[
                  const SizedBox(height: 16),
                  _NotesCard(notes: element.notes!),
                ],
                if (!hasBody) ...[
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.notes_outlined,
                    title: l10n.servicesElementEmpty,
                    description: l10n.servicesElementEmptyDesc,
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => showServiceNotesSheet(
                    context,
                    serviceId: serviceId,
                    elementId: element.id,
                    elementType: element.type,
                  ),
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  label: Text(l10n.servicesTeamNotes),
                ),
              ],
            ),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
    final meta = serviceElementMeta(l10n, theme.colorScheme, element.type);

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
                            ? theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              )
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
