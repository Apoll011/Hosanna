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
import '../data/service_repository.dart';
import 'service_element_meta.dart';
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
                    _MoreTab(
                      onLeave: () => context.pop(),
                      onOpenNotes: () => setState(() => _tabIndex = 1),
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
              NavigationDestination(
                icon: const Icon(Icons.more_horiz),
                selectedIcon: const Icon(Icons.more_horiz),
                label: l10n.servicesMore,
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
    final windows =
        computeElementTimeWindows(elements.map((e) => e.duration));
    final index = elements.indexWhere((e) => e.id == element.id);
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ElementDetailPage(
          serviceId: widget.serviceId,
          element: element,
          timeWindow: index >= 0 ? windows[index] : null,
          isCompleted: _completedIds.contains(element.id),
          isCurrent: element.id == _currentElementId,
        ),
      ),
    );
    if (!mounted || completed != true) return;
    setState(() {
      _completedIds.add(element.id);
      final service = ref.read(serviceByIdProvider(widget.serviceId)).valueOrNull;
      if (service == null) return;
      final elements = _sorted(service);
      final idx = elements.indexWhere((e) => e.id == element.id);
      final next = elements.skip(idx + 1).where((e) => !_completedIds.contains(e.id));
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

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.onLeave, required this.onOpenNotes});

  final VoidCallback onLeave;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.servicesMore,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(l10n.servicesTeamNotes),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenNotes,
        ),
        const SizedBox(height: 10),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text(l10n.servicesLeaveMode),
          onTap: onLeave,
        ),
      ],
    );
  }
}

class _ElementDetailPage extends ConsumerStatefulWidget {
  const _ElementDetailPage({
    required this.serviceId,
    required this.element,
    required this.timeWindow,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String serviceId;
  final ServiceElement element;
  final ElementTimeWindow? timeWindow;
  final bool isCompleted;
  final bool isCurrent;

  @override
  ConsumerState<_ElementDetailPage> createState() => _ElementDetailPageState();
}

class _ElementDetailPageState extends ConsumerState<_ElementDetailPage> {
  bool _hidChords = false;
  SongDisplaySettingsController? _displaySettings;

  @override
  void initState() {
    super.initState();
    if (widget.element.type == 'song') {
      _displaySettings = ref.read(songDisplaySettingsProvider.notifier);
      if (ref.read(songDisplaySettingsProvider).showChords) {
        _displaySettings!.setShowChords(false, persist: false);
        _hidChords = true;
      }
    }
  }

  @override
  void dispose() {
    if (_hidChords && _displaySettings != null) {
      _displaySettings!.setShowChords(
        _displaySettings!.persistedShowChords,
        persist: false,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final element = widget.element;
    final meta = serviceElementMeta(l10n, theme.colorScheme, element.type);

    if (element.type == 'song' && element.songId != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.servicesItemDetail),
          actions: [
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
        body: _SongDetailBody(
          serviceId: widget.serviceId,
          songId: element.songId!,
          notes: element.notes,
        ),
        bottomNavigationBar: widget.isCompleted
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.servicesMarkCompleted),
                  ),
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servicesItemDetail),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          if (widget.timeWindow != null && widget.timeWindow!.hasDuration) ...[
            const SizedBox(height: 12),
            _InfoCard(
              label: l10n.servicesEstimatedDuration,
              child: Text(
                widget.timeWindow!.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (element.passage != null && element.passage!.isNotEmpty) ...[
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
          if (element.content != null && element.content!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              label: l10n.servicesItems,
              child: Text(element.content!, style: theme.textTheme.bodyMedium),
            ),
          ],
          if (element.notes != null && element.notes!.isNotEmpty) ...[
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
                serviceId: widget.serviceId,
                elementId: element.id,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isCompleted
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.servicesMarkCompleted),
                ),
              ),
            ),
    );
  }
}

class _SongDetailBody extends ConsumerWidget {
  const _SongDetailBody({
    required this.serviceId,
    required this.songId,
    required this.notes,
  });

  final String serviceId;
  final String songId;
  final String? notes;

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
