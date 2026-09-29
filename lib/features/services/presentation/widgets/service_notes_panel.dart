import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/settings_controller.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/auth_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/service_notes_watch.dart';
import '../../domain/service_note.dart';
import '../../domain/service_note_suggestions.dart';

/// Team notes feed for a service (optionally filtered to one element).
///
/// Backed by [serviceNotesWatchProvider]: Firestore note pings plus a slow
/// REST poll fallback while the service screen is open.
class ServiceNotesPanel extends ConsumerWidget {
  const ServiceNotesPanel({
    super.key,
    required this.serviceId,
    this.elementId,
    this.elementType,
    this.serviceScope = false,
    this.embedded = false,
    this.title,
    this.markReadWhenBuilt = true,
    this.suggestionContext,
  });

  final String serviceId;
  final String? elementId;

  /// Type of the focused / ambient element (`song`, `message`, …).
  final String? elementType;
  final bool serviceScope;

  /// When true, omits the outer title chrome (useful inside a tab).
  final bool embedded;
  final String? title;

  /// Clear the unread badge while this panel is the active surface.
  final bool markReadWhenBuilt;

  /// Optional override; otherwise derived from settings + [elementType].
  final NoteSuggestionContext? suggestionContext;

  NoteSuggestionContext _resolveSuggestions(WidgetRef ref) {
    if (suggestionContext != null) return suggestionContext!;
    final musicianMode = ref.watch(settingsControllerProvider).musicianMode;
    return NoteSuggestionContext(
      musicianMode: musicianMode,
      elementType: elementType,
      scope: elementId != null
          ? NoteSuggestionScope.element
          : NoteSuggestionScope.service,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final watch = ref.watch(serviceNotesWatchProvider(serviceId));
    final userId = ref.watch(authSessionProvider)?.user.id;
    final notes = _filterNotes(watch.notes);
    final suggestions = _resolveSuggestions(ref);

    if (markReadWhenBuilt && watch.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serviceNotesWatchProvider(serviceId).notifier).markAllRead();
      });
    }
    Widget body;
    if (watch.isLoading && watch.notes.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (watch.error != null && watch.notes.isEmpty) {
      body = _NotesError(
        error: watch.error!,
        onRetry: () =>
            ref.read(serviceNotesWatchProvider(serviceId).notifier).refresh(),
      );
    } else if (notes.isEmpty) {
      body = RefreshIndicator(
        onRefresh: () =>
            ref.read(serviceNotesWatchProvider(serviceId).notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: EmptyState(
                icon: Icons.sticky_note_2_outlined,
                title: l10n.servicesNotesEmpty,
                description: l10n.servicesNotesEmptyDesc,
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () =>
            ref.read(serviceNotesWatchProvider(serviceId).notifier).refresh(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: notes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final note = notes[index];
            return _NoteCard(
              note: note,
              isMine: note.isAuthoredBy(userId),
              onEdit: note.isAuthoredBy(userId)
                  ? () => _openComposer(
                        context,
                        ref,
                        existing: note,
                        suggestions: suggestions,
                      )
                  : null,
              onDelete: note.isAuthoredBy(userId)
                  ? () => _confirmDelete(context, ref, note)
                  : null,
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded || title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              title ?? l10n.servicesTeamNotes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }

  List<ServiceNote> _filterNotes(List<ServiceNote> notes) {
    if (serviceScope) {
      return [for (final n in notes) if (n.elementId == null) n];
    }
    if (elementId != null) {
      return [for (final n in notes) if (n.elementId == elementId) n];
    }
    return notes;
  }

  Future<void> _openComposer(
    BuildContext context,
    WidgetRef ref, {
    ServiceNote? existing,
    required NoteSuggestionContext suggestions,
  }) async {
    final result = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NoteComposerSheet(
        initialBody: existing?.body ?? '',
        initialPrivate: existing?.isPrivate ?? false,
        isEditing: existing != null,
        suggestionContext: suggestions,
      ),
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(serviceNotesWatchProvider(serviceId).notifier);
    final l10n = AppLocalizations.of(context);
    try {
      if (existing == null) {
        await notifier.add(
          body: result.body,
          elementId: elementId,
          isPrivate: result.isPrivate,
        );
      } else {
        await notifier.edit(
          noteId: existing.id,
          body: result.body,
          isPrivate: result.isPrivate,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(l10n, e))),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServiceNote note,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.servicesNotesDeleteTitle),
        content: Text(l10n.servicesNotesDeleteDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.servicesNotesDelete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(serviceNotesWatchProvider(serviceId).notifier)
          .remove(note.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(l10n, e))),
      );
    }
  }
}

/// Floating action that opens the note composer for [serviceId].
class ServiceNotesFab extends ConsumerWidget {
  const ServiceNotesFab({
    super.key,
    required this.serviceId,
    this.elementId,
    this.elementType,
    this.suggestionContext,
  });

  final String serviceId;
  final String? elementId;
  final String? elementType;
  final NoteSuggestionContext? suggestionContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton(
      tooltip: l10n.servicesNotesAdd,
      onPressed: () => _compose(context, ref),
      child: const Icon(Icons.edit_outlined),
    );
  }

  NoteSuggestionContext _resolve(WidgetRef ref) {
    if (suggestionContext != null) return suggestionContext!;
    return NoteSuggestionContext(
      musicianMode: ref.read(settingsControllerProvider).musicianMode,
      elementType: elementType,
      scope: elementId != null
          ? NoteSuggestionScope.element
          : NoteSuggestionScope.service,
    );
  }

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final suggestions = _resolve(ref);
    final result = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NoteComposerSheet(
        initialBody: '',
        initialPrivate: false,
        isEditing: false,
        suggestionContext: suggestions,
      ),
    );
    if (result == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(serviceNotesWatchProvider(serviceId).notifier).add(
            body: result.body,
            elementId: elementId,
            isPrivate: result.isPrivate,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(l10n, e))),
      );
    }
  }
}

/// Opens the notes panel as a modal sheet (used from musician mode).
Future<void> showServiceNotesSheet(
  BuildContext context, {
  required String serviceId,
  String? elementId,
  String? elementType,
  NoteSuggestionContext? suggestionContext,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final height = MediaQuery.sizeOf(context).height * 0.85;
      return SizedBox(
        height: height,
        child: Scaffold(
          body: ServiceNotesPanel(
            serviceId: serviceId,
            elementId: elementId,
            elementType: elementType,
            suggestionContext: suggestionContext,
          ),
          floatingActionButton: ServiceNotesFab(
            serviceId: serviceId,
            elementId: elementId,
            elementType: elementType,
            suggestionContext: suggestionContext,
          ),
        ),
      );
    },
  );
}

/// Listens for newly arrived remote notes and shows a floating snackbar.
class ServiceNotesIncomingListener extends ConsumerWidget {
  const ServiceNotesIncomingListener({
    super.key,
    required this.serviceId,
    required this.child,
    this.onOpenNotes,
    this.suppressToast = false,
  });

  final String serviceId;
  final Widget child;
  final VoidCallback? onOpenNotes;

  /// When true (e.g. Notes tab visible), still refresh but skip the banner.
  final bool suppressToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(serviceNotesWatchProvider(serviceId), (previous, next) {
      if (previous == null) return;
      if (next.incomingTicket == previous.incomingTicket) return;
      final note = next.lastIncoming;
      if (note == null) return;

      final notifier = ref.read(serviceNotesWatchProvider(serviceId).notifier);
      if (suppressToast) {
        notifier
          ..consumeIncoming()
          ..markAllRead();
        return;
      }

      final l10n = AppLocalizations.of(context);
      final author = note.author?.name.trim();
      final who = (author == null || author.isEmpty)
          ? l10n.servicesNotesSomeone
          : author;
      final preview = note.body.trim();
      final body =
          preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        notifier.consumeIncoming();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              content: Text('$who: $body'),
              action: onOpenNotes == null
                  ? null
                  : SnackBarAction(
                      label: l10n.servicesNotes,
                      onPressed: onOpenNotes!,
                    ),
            ),
          );
      });
    });

    // Keep the watcher alive while this subtree is mounted.
    ref.watch(serviceNotesWatchProvider(serviceId));
    return child;
  }
}

/// Badge bubble for the Notes icon / tab.
class NotesUnreadBadge extends ConsumerWidget {
  const NotesUnreadBadge({
    super.key,
    required this.serviceId,
    required this.child,
  });

  final String serviceId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      serviceNotesWatchProvider(serviceId).select((s) => s.unreadCount),
    );
    if (count <= 0) return child;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}

class _NoteDraft {
  const _NoteDraft({required this.body, required this.isPrivate});
  final String body;
  final bool isPrivate;
}

class _NoteComposerSheet extends StatefulWidget {
  const _NoteComposerSheet({
    required this.initialBody,
    required this.initialPrivate,
    required this.isEditing,
    required this.suggestionContext,
  });

  final String initialBody;
  final bool initialPrivate;
  final bool isEditing;
  final NoteSuggestionContext suggestionContext;

  @override
  State<_NoteComposerSheet> createState() => _NoteComposerSheetState();
}

class _NoteComposerSheetState extends State<_NoteComposerSheet> {
  late final TextEditingController _controller;
  late bool _isPrivate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBody);
    _isPrivate = widget.initialPrivate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String body, {bool isPrivate = false}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 10000 || _submitting) return;
    setState(() => _submitting = true);
    Navigator.pop(
      context,
      _NoteDraft(body: trimmed, isPrivate: isPrivate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final trimmed = _controller.text.trim();
    final canSave =
        trimmed.isNotEmpty && trimmed.length <= 10000 && !_submitting;

    final suggestionIds = widget.isEditing
        ? const <String>[]
        : selectNoteSuggestionIds(widget.suggestionContext);
    final suggestionLabels = <(String, String)>[];
    for (final id in suggestionIds) {
      final label = labelForNoteSuggestion(l10n, id);
      if (label != null) suggestionLabels.add((id, label));
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.isEditing ? l10n.servicesNotesEdit : l10n.servicesNotesAdd,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (suggestionLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.servicesNotesQuickSend,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: suggestionLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = suggestionLabels[index].$2;
                  return _SuggestionChip(
                    label: label,
                    enabled: !_submitting,
                    onTap: () => _send(label),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 5,
                  maxLength: 10000,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.servicesNotesHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.servicesNotesPrivate),
                  subtitle: Text(l10n.servicesNotesPrivateDesc),
                  value: _isPrivate,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _isPrivate = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: canSave
                      ? () => _send(trimmed, isPrivate: _isPrivate)
                      : null,
                  child: Text(
                    widget.isEditing
                        ? l10n.commonSave
                        : l10n.servicesNotesAdd,
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? colors.onSurface
                  : colors.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.isMine,
    this.onEdit,
    this.onDelete,
  });

  final ServiceNote note;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.Hm(
      Localizations.localeOf(context).toString(),
    ).format(note.createdAt.toLocal());
    final author = note.author?.name.trim();
    final authorLabel = (author == null || author.isEmpty) ? '—' : '— $author';

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onLongPress: isMine ? () => _showActions(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (note.isPrivate) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  const Spacer(),
                  if (isMine)
                    Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                note.body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 10),
              Text(
                authorLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.servicesNotesEdit),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.servicesNotesDelete),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: l10n.commonError,
      description: _friendlyError(l10n, error),
      primaryLabel: l10n.commonRetry,
      primaryIcon: Icons.refresh,
      onPrimary: onRetry,
    );
  }
}

String _friendlyError(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'SUBSCRIPTION_REQUIRED' => l10n.servicesNotesSubscriptionRequired,
      'FORBIDDEN' => l10n.servicesNotesForbidden,
      'UNAUTHORIZED' => l10n.servicesNotesUnauthorized,
      'SERVICE_NOT_FOUND' => l10n.servicesNotFound,
      'NOTE_NOT_FOUND' => l10n.servicesNotesNotFound,
      'ELEMENT_NOT_FOUND' => l10n.servicesNotesElementNotFound,
      _ => error.message,
    };
  }
  return l10n.commonErrorDesc;
}
