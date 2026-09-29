import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/auth_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/service_notes_controller.dart';
import '../../domain/service_note.dart';

/// Team notes feed for a service (or a single element).
///
/// Fetches via [serviceNotesProvider], polls while mounted, and supports
/// create / edit / delete for notes authored by the current user.
class ServiceNotesPanel extends ConsumerWidget {
  const ServiceNotesPanel({
    super.key,
    required this.serviceId,
    this.elementId,
    this.serviceScope = false,
    this.embedded = false,
    this.title,
  });

  final String serviceId;
  final String? elementId;
  final bool serviceScope;

  /// When true, omits the outer title chrome (useful inside a tab).
  final bool embedded;
  final String? title;

  ServiceNotesQuery get _query => ServiceNotesQuery(
        serviceId: serviceId,
        elementId: elementId,
        serviceScope: serviceScope,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notesAsync = ref.watch(serviceNotesProvider(_query));
    final userId = ref.watch(authSessionProvider)?.user.id;

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
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _NotesError(
              error: e,
              onRetry: () =>
                  ref.read(serviceNotesProvider(_query).notifier).refresh(),
            ),
            data: (notes) {
              if (notes.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(serviceNotesProvider(_query).notifier).refresh(),
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
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(serviceNotesProvider(_query).notifier).refresh(),
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
                              )
                          : null,
                      onDelete: note.isAuthoredBy(userId)
                          ? () => _confirmDelete(context, ref, note)
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openComposer(
    BuildContext context,
    WidgetRef ref, {
    ServiceNote? existing,
    String? defaultElementId,
  }) async {
    final result = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NoteComposerSheet(
        initialBody: existing?.body ?? '',
        initialPrivate: existing?.isPrivate ?? false,
        isEditing: existing != null,
      ),
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(serviceNotesProvider(_query).notifier);
    final l10n = AppLocalizations.of(context);
    try {
      if (existing == null) {
        await notifier.add(
          body: result.body,
          elementId: defaultElementId ?? elementId,
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
      await ref.read(serviceNotesProvider(_query).notifier).remove(note.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(l10n, e))),
      );
    }
  }
}

/// Floating action that opens the note composer for [panel]'s query.
class ServiceNotesFab extends ConsumerWidget {
  const ServiceNotesFab({
    super.key,
    required this.serviceId,
    this.elementId,
    this.serviceScope = false,
  });

  final String serviceId;
  final String? elementId;
  final bool serviceScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton(
      tooltip: l10n.servicesNotesAdd,
      onPressed: () => _compose(context, ref),
      child: const Icon(Icons.edit_outlined),
    );
  }

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final query = ServiceNotesQuery(
      serviceId: serviceId,
      elementId: elementId,
      serviceScope: serviceScope,
    );
    final result = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _NoteComposerSheet(
        initialBody: '',
        initialPrivate: false,
        isEditing: false,
      ),
    );
    if (result == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(serviceNotesProvider(query).notifier).add(
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
          ),
          floatingActionButton: ServiceNotesFab(
            serviceId: serviceId,
            elementId: elementId,
          ),
        ),
      );
    },
  );
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
  });

  final String initialBody;
  final bool initialPrivate;
  final bool isEditing;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final trimmed = _controller.text.trim();
    final canSave = trimmed.isNotEmpty && trimmed.length <= 10000 && !_submitting;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing
                ? l10n.servicesNotesEdit
                : l10n.servicesNotesAdd,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
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
                ? () {
                    setState(() => _submitting = true);
                    Navigator.pop(
                      context,
                      _NoteDraft(body: trimmed, isPrivate: _isPrivate),
                    );
                  }
                : null,
            child: Text(
              widget.isEditing ? l10n.commonSave : l10n.servicesNotesAdd,
            ),
          ),
        ],
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
        onLongPress: isMine
            ? () => _showActions(context)
            : null,
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
