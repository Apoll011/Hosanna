import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/service_note.dart';
import 'service_notes_repository.dart';

/// Cache key for notes belonging to a service (optionally one element).
class ServiceNotesQuery {
  const ServiceNotesQuery({
    required this.serviceId,
    this.elementId,
    this.serviceScope = false,
  });

  final String serviceId;
  final String? elementId;
  final bool serviceScope;

  @override
  bool operator ==(Object other) =>
      other is ServiceNotesQuery &&
      other.serviceId == serviceId &&
      other.elementId == elementId &&
      other.serviceScope == serviceScope;

  @override
  int get hashCode => Object.hash(serviceId, elementId, serviceScope);
}

/// In-memory notes list with pull-to-refresh and light background polling.
///
/// Polling runs only while the provider is watched (notes UI mounted) so the
/// feed stays reasonably fresh without a permanent network timer.
class ServiceNotesController
    extends AutoDisposeFamilyAsyncNotifier<List<ServiceNote>, ServiceNotesQuery> {
  static const _pollInterval = Duration(seconds: 45);
  Timer? _poll;
  var _disposed = false;

  ServiceNotesRepository get _repo =>
      ref.read(serviceNotesRepositoryProvider);

  @override
  Future<List<ServiceNote>> build(ServiceNotesQuery arg) async {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
    });
    _schedulePoll();
    return _fetch();
  }

  Future<List<ServiceNote>> _fetch() {
    return _repo.listNotes(
      serviceId: arg.serviceId,
      elementId: arg.elementId,
      serviceScope: arg.serviceScope,
    );
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) async {
      if (_disposed) return;
      try {
        final notes = await _fetch();
        if (!_disposed) state = AsyncData(notes);
      } catch (_) {
        // Keep showing the last good list; next manual refresh surfaces errors.
      }
    });
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<ServiceNote> add({
    required String body,
    String? elementId,
    bool isPrivate = false,
  }) async {
    final created = await _repo.createNote(
      serviceId: arg.serviceId,
      body: body,
      elementId: elementId ?? arg.elementId,
      isPrivate: isPrivate,
    );
    final current = state.valueOrNull ?? const <ServiceNote>[];
    // Preserve oldest-first order used by the API.
    state = AsyncData([...current, created]);
    return created;
  }

  Future<ServiceNote> edit({
    required String noteId,
    String? body,
    bool? isPrivate,
  }) async {
    final updated = await _repo.updateNote(
      serviceId: arg.serviceId,
      noteId: noteId,
      body: body,
      isPrivate: isPrivate,
    );
    final current = state.valueOrNull ?? const <ServiceNote>[];
    state = AsyncData([
      for (final n in current)
        if (n.id == noteId) updated else n,
    ]);
    return updated;
  }

  Future<void> remove(String noteId) async {
    await _repo.deleteNote(serviceId: arg.serviceId, noteId: noteId);
    final current = state.valueOrNull ?? const <ServiceNote>[];
    state = AsyncData([
      for (final n in current)
        if (n.id != noteId) n,
    ]);
  }
}

final serviceNotesProvider = AsyncNotifierProvider.autoDispose
    .family<ServiceNotesController, List<ServiceNote>, ServiceNotesQuery>(
      ServiceNotesController.new,
    );
