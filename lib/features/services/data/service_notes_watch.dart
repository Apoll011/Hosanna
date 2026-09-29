import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../domain/service_note.dart';
import 'service_notes_repository.dart';

/// Live notes for a service.
///
/// Primary path: Firestore signal at `services/{id}/realtime/notes` (written
/// by the API after note CUD). Fallback: slow REST poll every 60s.
@immutable
class ServiceNotesWatchState {
  const ServiceNotesWatchState({
    this.notes = const [],
    this.unreadCount = 0,
    this.lastIncoming,
    this.incomingTicket = 0,
    this.isLoading = true,
    this.error,
  });

  final List<ServiceNote> notes;
  final int unreadCount;

  /// Latest remote note that should surface as an in-app notification.
  final ServiceNote? lastIncoming;

  /// Bumps whenever [lastIncoming] changes so listeners can react.
  final int incomingTicket;

  final bool isLoading;
  final Object? error;

  ServiceNotesWatchState copyWith({
    List<ServiceNote>? notes,
    int? unreadCount,
    ServiceNote? lastIncoming,
    bool clearIncoming = false,
    int? incomingTicket,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return ServiceNotesWatchState(
      notes: notes ?? this.notes,
      unreadCount: unreadCount ?? this.unreadCount,
      lastIncoming: clearIncoming ? null : (lastIncoming ?? this.lastIncoming),
      incomingTicket: incomingTicket ?? this.incomingTicket,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ServiceNotesWatchController
    extends StateNotifier<ServiceNotesWatchState> {
  ServiceNotesWatchController(this._repo, this._currentUserId, this._serviceId)
      : super(const ServiceNotesWatchState()) {
    _bootstrap();
  }

  /// Slow safety net when Firestore is unavailable or a ping is missed.
  static const _pollInterval = Duration(seconds: 60);

  final ServiceNotesRepository _repo;
  final String? _currentUserId;
  final String _serviceId;

  final Set<String> _knownIds = {};
  var _seeded = false;
  Timer? _poll;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _signalSub;
  var _skipNextSignal = true;
  var _disposed = false;

  DocumentReference<Map<String, dynamic>> get _signalDoc =>
      FirebaseFirestore.instance
          .collection('services')
          .doc(_serviceId)
          .collection('realtime')
          .doc('notes');

  Future<void> _bootstrap() async {
    await refresh();
    if (_disposed) return;
    _listenForSignals();
    _poll = Timer.periodic(_pollInterval, (_) => refresh(silent: true));
  }

  void _listenForSignals() {
    try {
      _signalSub = _signalDoc.snapshots().listen(
        (snap) {
          if (_disposed) return;
          // First event is the current doc (or missing) — seed only.
          if (_skipNextSignal) {
            _skipNextSignal = false;
            return;
          }
          if (!snap.exists) return;
          final data = snap.data();
          final authorId = data?['authorId'] as String?;
          // Own writes already updated local state; still refresh for consistency
          // but applyNotes will not toast for the current user.
          unawaited(refresh(silent: true, preferToast: authorId != _currentUserId));
        },
        onError: (Object e, StackTrace st) {
          debugPrint('Notes Firestore signal listen failed: $e');
        },
      );
    } catch (e) {
      debugPrint('Notes Firestore signal subscribe failed: $e');
    }
  }

  Future<void> refresh({bool silent = false, bool preferToast = true}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final notes = await _repo.listNotes(serviceId: _serviceId);
      if (_disposed) return;
      _applyNotes(notes, preferToast: preferToast);
    } catch (e) {
      if (_disposed) return;
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e);
      }
    }
  }

  void _applyNotes(List<ServiceNote> notes, {bool preferToast = true}) {
    final ids = notes.map((n) => n.id).toSet();

    if (!_seeded) {
      _knownIds
        ..clear()
        ..addAll(ids);
      _seeded = true;
      state = state.copyWith(
        notes: notes,
        isLoading: false,
        clearError: true,
        clearIncoming: true,
      );
      return;
    }

    final newcomers = preferToast
        ? notes
            .where((n) => !_knownIds.contains(n.id))
            .where((n) => n.author?.id != _currentUserId)
            .toList()
        : const <ServiceNote>[];

    _knownIds
      ..clear()
      ..addAll(ids);

    final nextUnread = state.unreadCount + newcomers.length;

    state = state.copyWith(
      notes: notes,
      unreadCount: nextUnread,
      isLoading: false,
      clearError: true,
      lastIncoming: newcomers.isEmpty ? state.lastIncoming : newcomers.last,
      incomingTicket: newcomers.isEmpty
          ? state.incomingTicket
          : state.incomingTicket + 1,
      clearIncoming: false,
    );
  }

  /// Clears the badge (e.g. when opening the Notes tab / sheet).
  void markAllRead() {
    if (state.unreadCount == 0 && state.lastIncoming == null) return;
    state = state.copyWith(unreadCount: 0, clearIncoming: true);
  }

  /// Acknowledges the toast so it is not shown again.
  void consumeIncoming() {
    if (state.lastIncoming == null) return;
    state = state.copyWith(clearIncoming: true);
  }

  Future<ServiceNote> add({
    required String body,
    String? elementId,
    bool isPrivate = false,
  }) async {
    final created = await _repo.createNote(
      serviceId: _serviceId,
      body: body,
      elementId: elementId,
      isPrivate: isPrivate,
    );
    _knownIds.add(created.id);
    state = state.copyWith(notes: [...state.notes, created]);
    return created;
  }

  Future<ServiceNote> edit({
    required String noteId,
    String? body,
    bool? isPrivate,
  }) async {
    final updated = await _repo.updateNote(
      serviceId: _serviceId,
      noteId: noteId,
      body: body,
      isPrivate: isPrivate,
    );
    state = state.copyWith(
      notes: [
        for (final n in state.notes)
          if (n.id == noteId) updated else n,
      ],
    );
    return updated;
  }

  Future<void> remove(String noteId) async {
    await _repo.deleteNote(serviceId: _serviceId, noteId: noteId);
    _knownIds.remove(noteId);
    state = state.copyWith(
      notes: [
        for (final n in state.notes)
          if (n.id != noteId) n,
      ],
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    unawaited(_signalSub?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}

final serviceNotesWatchProvider = StateNotifierProvider.autoDispose
    .family<ServiceNotesWatchController, ServiceNotesWatchState, String>((
      ref,
      serviceId,
    ) {
      final userId = ref.watch(authSessionProvider)?.user.id;
      return ServiceNotesWatchController(
        ref.watch(serviceNotesRepositoryProvider),
        userId,
        serviceId,
      );
    });
