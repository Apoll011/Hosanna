import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/settings_controller.dart';
import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../songs/data/song_repository.dart';
import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../../songs/presentation/song_reader.dart';
import '../../songs/presentation/song_toolbar.dart';
import '../data/service_repository.dart';
import 'service_element_meta.dart';
import 'widgets/horizontal_swipe_navigator.dart';
import 'widgets/service_notes_panel.dart';

/// Non-musician service view: run-of-show with durations, item detail, and
/// team notes. No chords tab — songs open with lyrics (chords hidden).
class ServiceOrderPage extends ConsumerStatefulWidget {
  const ServiceOrderPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<ServiceOrderPage> createState() => _ServiceOrderPageState();
}

class _ServiceOrderPageState extends ConsumerState<ServiceOrderPage> {
  int _tabIndex = 0;
  final Set<String> _completedIds = {};
  String? _currentElementId;
  DateTime? _startedAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsControllerProvider).keepScreenAwake) {
      WakelockPlus.enable();
    }
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  List<ServiceElement> _sorted(ServiceRow service) {
    return List<ServiceElement>.from(service.elements)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
  }

  void _ensureCurrent(List<ServiceElement> elements) {
    if (elements.isEmpty) return;
    final stillValid =
        _currentElementId != null &&
        elements.any((e) => e.id == _currentElementId);
    if (stillValid) return;
    final firstOpen = elements.where((e) => !_completedIds.contains(e.id));
    _currentElementId = (firstOpen.isEmpty ? elements.first : firstOpen.first).id;
  }

  Duration get _elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final serviceAsync = ref.watch(serviceByIdProvider(widget.serviceId));

    return serviceAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        body: ErrorState(
          title: l10n.commonError,
          description: l10n.commonErrorDesc,
        ),
      ),
      data: (service) {
        if (service == null) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.event_busy_outlined,
              title: l10n.servicesNotFound,
              description: l10n.servicesNotFoundDesc,
            ),
          );
        }
        final elements = _sorted(service);
        _ensureCurrent(elements);

        return Scaffold(
          body: Column(
            children: [
              _OrderHeader(
                service: service,
                elapsed: _elapsed,
                onLeave: () => context.pop(),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _OrderListTab(
                      elements: elements,
                      completedIds: _completedIds,
                      currentElementId: _currentElementId,
                      onOpen: (element) => _openElement(context, element),
                    ),
                    ServiceNotesPanel(
                      serviceId: widget.serviceId,
                      embedded: true,
                      title: l10n.servicesTeamNotes,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _tabIndex == 1
              ? ServiceNotesFab(serviceId: widget.serviceId)
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.view_list_outlined),
                selectedIcon: const Icon(Icons.view_list),
                label: l10n.servicesOrderTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.sticky_note_2_outlined),
                selectedIcon: const Icon(Icons.sticky_note_2),
                label: l10n.servicesNotes,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openElement(
    BuildContext context,
    ServiceElement element,
  ) async {
    final service =
        ref.read(serviceByIdProvider(widget.serviceId)).valueOrNull;
    if (service == null) return;
    final elements = _sorted(service);
    final index = elements.indexWhere((e) => e.id == element.id);
    if (index < 0) return;
    final completedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ElementViewerPage(
          serviceId: widget.serviceId,
          elements: elements,
          initialIndex: index,
          completedIds: _completedIds,
        ),
      ),
    );
    if (!mounted || completedId == null) return;
    setState(() {
      _completedIds.add(completedId);
      final idx = elements.indexWhere((e) => e.id == completedId);
      final next = elements
          .skip(idx < 0 ? 0 : idx + 1)
          .where((e) => !_completedIds.contains(e.id));
      if (next.isNotEmpty) {
        _currentElementId = next.first.id;
      }
    });
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({
    required this.service,
    required this.elapsed,
    required this.onLeave,
  });

  final ServiceRow service;
  final Duration elapsed;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateTime.tryParse(service.date);
    final dateLabel = date == null
        ? ''
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(date);
    final timer = formatServiceDuration(elapsed.inSeconds);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.servicesLeave,
                  onPressed: onLeave,
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.servicesLeave,
                  onPressed: onLeave,
                  icon: Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.servicesInProgress,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timer,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

class _OrderListTab extends ConsumerWidget {
  const _OrderListTab({
    required this.elements,
    required this.completedIds,
    required this.currentElementId,
    required this.onOpen,
  });

  final List<ServiceElement> elements;
  final Set<String> completedIds;
  final String? currentElementId;
  final ValueChanged<ServiceElement> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (elements.isEmpty) {
      return EmptyState(
        icon: Icons.playlist_add_outlined,
        title: l10n.servicesNoItems,
        description: l10n.servicesNoItemsDesc,
      );
    }

    final windows = computeElementTimeWindows(elements.map((e) => e.duration));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          l10n.servicesOrderTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < elements.length; i++) ...[
          _OrderRow(
            index: i,
            element: elements[i],
            window: windows[i],
            status: completedIds.contains(elements[i].id)
                ? _ItemStatus.done
                : elements[i].id == currentElementId
                    ? _ItemStatus.current
                    : _ItemStatus.upcoming,
            onTap: () => onOpen(elements[i]),
          ),
          if (i < elements.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

enum _ItemStatus { done, current, upcoming }

class _OrderRow extends ConsumerWidget {
  const _OrderRow({
    required this.index,
    required this.element,
    required this.window,
    required this.status,
    required this.onTap,
  });

  final int index;
  final ServiceElement element;
  final ElementTimeWindow window;
  final _ItemStatus status;
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

    final title = element.type == 'song'
        ? (song?.title ?? l10n.servicesElementSong)
        : (element.title.isNotEmpty ? element.title : meta.label);
    final subtitle = element.type == 'song'
        ? (song?.artist ?? l10n.servicesElementSong)
        : meta.label;

    final borderColor = switch (status) {
      _ItemStatus.current => theme.colorScheme.primary.withValues(alpha: 0.45),
      _ => theme.colorScheme.outlineVariant,
    };

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, size: 18, color: meta.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (window.hasDuration) ...[
                const SizedBox(width: 8),
                Text(
                  window.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _StatusGlyph(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.status});

  final _ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      _ItemStatus.done => Icon(
          Icons.check_circle,
          size: 22,
          color: const Color(0xFF16A34A),
        ),
      _ItemStatus.current => Icon(
          Icons.play_circle_filled,
          size: 22,
          color: theme.colorScheme.primary,
        ),
      _ItemStatus.upcoming => Icon(
          Icons.circle_outlined,
          size: 22,
          color: theme.colorScheme.outline,
        ),
    };
  }
}

/// Full-screen viewer for any service element with swipe across the whole order.
class _ElementViewerPage extends ConsumerStatefulWidget {
  const _ElementViewerPage({
    required this.serviceId,
    required this.elements,
    required this.initialIndex,
    required this.completedIds,
  });

  final String serviceId;
  final List<ServiceElement> elements;
  final int initialIndex;
  final Set<String> completedIds;

  @override
  ConsumerState<_ElementViewerPage> createState() => _ElementViewerPageState();
}

class _ElementViewerPageState extends ConsumerState<_ElementViewerPage> {
  late int _index;
  bool _hidChords = false;
  SongDisplaySettingsController? _displaySettings;

  ServiceElement get _element => widget.elements[_index];

  List<ElementTimeWindow> get _windows =>
      computeElementTimeWindows(widget.elements.map((e) => e.duration));

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.elements.length - 1);
    _maybeHideChords();
  }

  @override
  void dispose() {
    _restoreChords();
    super.dispose();
  }

  void _maybeHideChords() {
    if (_element.type != 'song') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hidChords) return;
      _displaySettings ??= ref.read(songDisplaySettingsProvider.notifier);
      if (ref.read(songDisplaySettingsProvider).showChords) {
        _displaySettings!.setShowChords(false, persist: false);
        _hidChords = true;
      }
    });
  }

  void _restoreChords() {
    if (!_hidChords || _displaySettings == null) return;
    _displaySettings!.setShowChords(
      _displaySettings!.persistedShowChords,
      persist: false,
    );
    _hidChords = false;
  }

  void _goTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.elements.length) return;
    final wasSong = _element.type == 'song';
    setState(() => _index = nextIndex);
    final isSong = _element.type == 'song';
    if (wasSong && !isSong) {
      _restoreChords();
    } else if (isSong) {
      _maybeHideChords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final element = _element;
    final isSong = element.type == 'song' && element.songId != null;
    final canPrev = _index > 0;
    final canNext = _index < widget.elements.length - 1;
    final positionLabel = '${_index + 1} / ${widget.elements.length}';
    final isCompleted = widget.completedIds.contains(element.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servicesItemDetail),
        actions: [
          if (isSong) const SongToolbarButton(),
          IconButton(
            tooltip: l10n.servicesNotes,
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: () => showServiceNotesSheet(
              context,
              serviceId: widget.serviceId,
              elementId: element.id,
            ),
          ),
        ],
      ),
      body: isSong
          ? _SongDetailBody(
              serviceId: widget.serviceId,
              songId: element.songId!,
              notes: element.notes,
              canPrev: canPrev,
              canNext: canNext,
              positionLabel: positionLabel,
              onPrev: () => _goTo(_index - 1),
              onNext: () => _goTo(_index + 1),
            )
          : HorizontalSwipeNavigator(
              canPrev: canPrev,
              canNext: canNext,
              positionLabel: positionLabel,
              onPrev: canPrev ? () => _goTo(_index - 1) : null,
              onNext: canNext ? () => _goTo(_index + 1) : null,
              child: _NonSongDetailBody(
                serviceId: widget.serviceId,
                element: element,
                timeWindow: _windows[_index],
              ),
            ),
      bottomNavigationBar: isCompleted
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, element.id),
                  child: Text(l10n.servicesMarkCompleted),
                ),
              ),
            ),
    );
  }
}

class _NonSongDetailBody extends StatelessWidget {
  const _NonSongDetailBody({
    required this.serviceId,
    required this.element,
    required this.timeWindow,
  });

  final String serviceId;
  final ServiceElement element;
  final ElementTimeWindow timeWindow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = serviceElementMeta(l10n, theme.colorScheme, element.type);
    final hasPassage = element.passage != null && element.passage!.isNotEmpty;
    final hasContent = element.content != null && element.content!.isNotEmpty;
    final hasItemNotes = element.notes != null && element.notes!.isNotEmpty;
    final hasBody = hasPassage || hasContent || hasItemNotes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                element.title.isNotEmpty ? element.title : meta.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meta.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (timeWindow.hasDuration) ...[
          const SizedBox(height: 12),
          _InfoCard(
            label: l10n.servicesEstimatedDuration,
            child: Text(
              timeWindow.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (hasPassage) ...[
          const SizedBox(height: 12),
          _InfoCard(
            label: l10n.servicesPassage,
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
          const SizedBox(height: 12),
          _InfoCard(
            label: l10n.servicesItems,
            child: Text(element.content!, style: theme.textTheme.bodyMedium),
          ),
        ],
        if (hasItemNotes) ...[
          const SizedBox(height: 12),
          _InfoCard(
            label: l10n.servicesItemNotes,
            child: Text(
              element.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        if (!hasBody) ...[
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.notes_outlined,
            title: l10n.servicesElementEmpty,
            description: l10n.servicesElementEmptyDesc,
          ),
        ],
        const SizedBox(height: 12),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ListTile(
            title: Text(l10n.servicesLeaderNotes),
            subtitle: Text(l10n.servicesLeaderNotesHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showServiceNotesSheet(
              context,
              serviceId: serviceId,
              elementId: element.id,
            ),
          ),
        ),
      ],
    );
  }
}

class _SongDetailBody extends ConsumerWidget {
  const _SongDetailBody({
    required this.serviceId,
    required this.songId,
    required this.notes,
    required this.canPrev,
    required this.canNext,
    required this.positionLabel,
    required this.onPrev,
    required this.onNext,
  });

  final String serviceId;
  final String songId;
  final String? notes;
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
              key: ValueKey(songId),
              content: song.content,
              notes: notes,
              serviceId: serviceId,
              songId: songId,
              canPrev: canPrev,
              canNext: canNext,
              positionLabel: positionLabel,
              onPrev: onPrev,
              onNext: onNext,
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

