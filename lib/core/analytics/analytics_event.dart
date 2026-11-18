/// Sealed hierarchy of all trackable analytics events for the Hosanna app.
///
/// Every event carries a [name] (PostHog event name, snake_case) and a
/// [properties] map. Add new events by extending [AnalyticsEvent] with a
/// `final class`.
library;

sealed class AnalyticsEvent {
  const AnalyticsEvent();

  /// PostHog event name (snake_case).
  String get name;

  /// Properties sent with the event. Defaults to an empty map.
  Map<String, dynamic> get properties => const {};
}

// ── App lifecycle ─────────────────────────────────────────────────────────────

final class AppLaunched extends AnalyticsEvent {
  const AppLaunched();
  @override
  String get name => 'app_launched';
}

final class AppOpenedFromBackground extends AnalyticsEvent {
  const AppOpenedFromBackground();
  @override
  String get name => 'app_opened_from_background';
}

// ── Auth events ───────────────────────────────────────────────────────────────

final class SignInStarted extends AnalyticsEvent {
  const SignInStarted({required this.method});
  final String method;
  @override
  String get name => 'sign_in_started';
  @override
  Map<String, dynamic> get properties => {'method': method};
}

final class SignInSucceeded extends AnalyticsEvent {
  const SignInSucceeded({required this.method, required this.userId});
  final String method;
  final String userId;
  @override
  String get name => 'sign_in_succeeded';
  @override
  Map<String, dynamic> get properties => {'method': method, 'user_id': userId};
}

final class SignInFailed extends AnalyticsEvent {
  const SignInFailed({required this.method, required this.error});
  final String method;
  final String error;
  @override
  String get name => 'sign_in_failed';
  @override
  Map<String, dynamic> get properties => {'method': method, 'error': error};
}

final class SignUpStarted extends AnalyticsEvent {
  const SignUpStarted({required this.method});
  final String method;
  @override
  String get name => 'sign_up_started';
  @override
  Map<String, dynamic> get properties => {'method': method};
}

final class SignUpSucceeded extends AnalyticsEvent {
  const SignUpSucceeded({required this.method, required this.userId});
  final String method;
  final String userId;
  @override
  String get name => 'sign_up_succeeded';
  @override
  Map<String, dynamic> get properties => {'method': method, 'user_id': userId};
}

final class SignUpFailed extends AnalyticsEvent {
  const SignUpFailed({required this.method, required this.error});
  final String method;
  final String error;
  @override
  String get name => 'sign_up_failed';
  @override
  Map<String, dynamic> get properties => {'method': method, 'error': error};
}

final class SignOutRequested extends AnalyticsEvent {
  const SignOutRequested();
  @override
  String get name => 'sign_out_requested';
}

final class PasswordResetRequested extends AnalyticsEvent {
  const PasswordResetRequested();
  @override
  String get name => 'password_reset_requested';
}

final class EmailVerificationSent extends AnalyticsEvent {
  const EmailVerificationSent();
  @override
  String get name => 'email_verification_sent';
}

// ── Navigation events ─────────────────────────────────────────────────────────

final class ScreenViewed extends AnalyticsEvent {
  const ScreenViewed({required this.screenName, this.params});
  final String screenName;
  final Map<String, dynamic>? params;
  @override
  String get name => 'screen_viewed';
  @override
  Map<String, dynamic> get properties => {
    'screen_name': screenName,
    if (params != null) ...params!,
  };
}

// ── Song events ───────────────────────────────────────────────────────────────

final class SongViewed extends AnalyticsEvent {
  const SongViewed({
    required this.songId,
    required this.songTitle,
    this.folderId,
  });
  final String songId;
  final String songTitle;
  final String? folderId;
  @override
  String get name => 'song_viewed';
  @override
  Map<String, dynamic> get properties => {
    'song_id': songId,
    'song_title': songTitle,
    if (folderId != null) 'folder_id': folderId,
  };
}

final class SongEdited extends AnalyticsEvent {
  const SongEdited({required this.songId});
  final String songId;
  @override
  String get name => 'song_edited';
  @override
  Map<String, dynamic> get properties => {'song_id': songId};
}

final class SongCreated extends AnalyticsEvent {
  const SongCreated({this.folderId});
  final String? folderId;
  @override
  String get name => 'song_created';
  @override
  Map<String, dynamic> get properties => {
    if (folderId != null) 'folder_id': folderId,
  };
}

final class SongDeleted extends AnalyticsEvent {
  const SongDeleted({required this.songId});
  final String songId;
  @override
  String get name => 'song_deleted';
  @override
  Map<String, dynamic> get properties => {'song_id': songId};
}

final class SongTransposed extends AnalyticsEvent {
  const SongTransposed({required this.songId, required this.semitones});
  final String songId;
  final int semitones;
  @override
  String get name => 'song_transposed';
  @override
  Map<String, dynamic> get properties => {
    'song_id': songId,
    'semitones': semitones,
  };
}

final class SongShared extends AnalyticsEvent {
  const SongShared({required this.songId, required this.format});
  final String songId;
  final String format;
  @override
  String get name => 'song_shared';
  @override
  Map<String, dynamic> get properties => {'song_id': songId, 'format': format};
}

final class SongPdfExported extends AnalyticsEvent {
  const SongPdfExported({required this.songId});
  final String songId;
  @override
  String get name => 'song_pdf_exported';
  @override
  Map<String, dynamic> get properties => {'song_id': songId};
}

final class SongImported extends AnalyticsEvent {
  const SongImported({required this.source});
  final String source;
  @override
  String get name => 'song_imported';
  @override
  Map<String, dynamic> get properties => {'source': source};
}

final class SongAiImportStarted extends AnalyticsEvent {
  const SongAiImportStarted({required this.source});
  final String source;
  @override
  String get name => 'song_ai_import_started';
  @override
  Map<String, dynamic> get properties => {'source': source};
}

final class SongAiImportCompleted extends AnalyticsEvent {
  const SongAiImportCompleted({required this.songId});
  final String songId;
  @override
  String get name => 'song_ai_import_completed';
  @override
  Map<String, dynamic> get properties => {'song_id': songId};
}

final class SongAiImportFailed extends AnalyticsEvent {
  const SongAiImportFailed({required this.error});
  final String error;
  @override
  String get name => 'song_ai_import_failed';
  @override
  Map<String, dynamic> get properties => {'error': error};
}

final class AutoScrollToggled extends AnalyticsEvent {
  const AutoScrollToggled({required this.songId, required this.enabled});
  final String songId;
  final bool enabled;
  @override
  String get name => 'auto_scroll_toggled';
  @override
  Map<String, dynamic> get properties => {
    'song_id': songId,
    'enabled': enabled,
  };
}

final class MetronomeUsed extends AnalyticsEvent {
  const MetronomeUsed({required this.bpm, this.songId});
  final int bpm;
  final String? songId;
  @override
  String get name => 'metronome_used';
  @override
  Map<String, dynamic> get properties => {
    'bpm': bpm,
    if (songId != null) 'song_id': songId,
  };
}

// ── Collection events ─────────────────────────────────────────────────────────

final class CollectionViewed extends AnalyticsEvent {
  const CollectionViewed({required this.collectionId});
  final String collectionId;
  @override
  String get name => 'collection_viewed';
  @override
  Map<String, dynamic> get properties => {'collection_id': collectionId};
}

final class CollectionCreated extends AnalyticsEvent {
  const CollectionCreated();
  @override
  String get name => 'collection_created';
}

final class CollectionDeleted extends AnalyticsEvent {
  const CollectionDeleted({required this.collectionId});
  final String collectionId;
  @override
  String get name => 'collection_deleted';
  @override
  Map<String, dynamic> get properties => {'collection_id': collectionId};
}

// ── Folder events ─────────────────────────────────────────────────────────────

final class FolderOpened extends AnalyticsEvent {
  const FolderOpened({this.folderId});
  final String? folderId;
  @override
  String get name => 'folder_opened';
  @override
  Map<String, dynamic> get properties => {
    if (folderId != null) 'folder_id': folderId,
  };
}

final class FolderCreated extends AnalyticsEvent {
  const FolderCreated({this.parentId});
  final String? parentId;
  @override
  String get name => 'folder_created';
  @override
  Map<String, dynamic> get properties => {
    if (parentId != null) 'parent_id': parentId,
  };
}

final class FolderDeleted extends AnalyticsEvent {
  const FolderDeleted({required this.folderId});
  final String folderId;
  @override
  String get name => 'folder_deleted';
  @override
  Map<String, dynamic> get properties => {'folder_id': folderId};
}

// ── Agenda / Service events ───────────────────────────────────────────────────

final class AgendaViewed extends AnalyticsEvent {
  const AgendaViewed();
  @override
  String get name => 'agenda_viewed';
}

final class ServiceViewed extends AnalyticsEvent {
  const ServiceViewed({required this.serviceId});
  final String serviceId;
  @override
  String get name => 'service_viewed';
  @override
  Map<String, dynamic> get properties => {'service_id': serviceId};
}

final class ServiceCreated extends AnalyticsEvent {
  const ServiceCreated();
  @override
  String get name => 'service_created';
}

final class ServiceAnnotationAdded extends AnalyticsEvent {
  const ServiceAnnotationAdded({required this.serviceId});
  final String serviceId;
  @override
  String get name => 'service_annotation_added';
  @override
  Map<String, dynamic> get properties => {'service_id': serviceId};
}

// ── Sync events ───────────────────────────────────────────────────────────────

final class SyncStarted extends AnalyticsEvent {
  const SyncStarted({required this.organizationId});
  final String organizationId;
  @override
  String get name => 'sync_started';
  @override
  Map<String, dynamic> get properties => {'organization_id': organizationId};
}

final class SyncCompleted extends AnalyticsEvent {
  const SyncCompleted({
    required this.organizationId,
    required this.durationMs,
  });
  final String organizationId;
  final int durationMs;
  @override
  String get name => 'sync_completed';
  @override
  Map<String, dynamic> get properties => {
    'organization_id': organizationId,
    'duration_ms': durationMs,
  };
}

final class SyncFailed extends AnalyticsEvent {
  const SyncFailed({required this.organizationId, required this.error});
  final String organizationId;
  final String error;
  @override
  String get name => 'sync_failed';
  @override
  Map<String, dynamic> get properties => {
    'organization_id': organizationId,
    'error': error,
  };
}

// ── Settings events ───────────────────────────────────────────────────────────

final class SettingsOpened extends AnalyticsEvent {
  const SettingsOpened();
  @override
  String get name => 'settings_opened';
}

final class ThemeChanged extends AnalyticsEvent {
  const ThemeChanged({required this.theme});
  final String theme;
  @override
  String get name => 'theme_changed';
  @override
  Map<String, dynamic> get properties => {'theme': theme};
}

final class LocaleChanged extends AnalyticsEvent {
  const LocaleChanged({required this.locale});
  final String locale;
  @override
  String get name => 'locale_changed';
  @override
  Map<String, dynamic> get properties => {'locale': locale};
}

final class NotificationsEnabled extends AnalyticsEvent {
  const NotificationsEnabled();
  @override
  String get name => 'notifications_enabled';
}

final class NotificationsDisabled extends AnalyticsEvent {
  const NotificationsDisabled();
  @override
  String get name => 'notifications_disabled';
}

// ── Onboarding events ─────────────────────────────────────────────────────────

final class OnboardingStarted extends AnalyticsEvent {
  const OnboardingStarted();
  @override
  String get name => 'onboarding_started';
}

final class OnboardingOrganizationCreated extends AnalyticsEvent {
  const OnboardingOrganizationCreated();
  @override
  String get name => 'onboarding_organization_created';
}

final class OnboardingOrganizationJoined extends AnalyticsEvent {
  const OnboardingOrganizationJoined();
  @override
  String get name => 'onboarding_organization_joined';
}

final class OnboardingCompleted extends AnalyticsEvent {
  const OnboardingCompleted();
  @override
  String get name => 'onboarding_completed';
}

// ── Error events ──────────────────────────────────────────────────────────────

final class AppErrorCaptured extends AnalyticsEvent {
  const AppErrorCaptured({
    required this.error,
    this.stackTrace,
    this.context,
  });
  final String error;
  final String? stackTrace;
  final String? context;
  @override
  String get name => 'app_error_captured';
  @override
  Map<String, dynamic> get properties => {
    'error': error,
    if (stackTrace != null) 'stack_trace': stackTrace,
    if (context != null) 'context': context,
  };
}

// ── Feature flag events ───────────────────────────────────────────────────────

final class FeatureFlagEvaluated extends AnalyticsEvent {
  const FeatureFlagEvaluated({required this.flagKey, required this.value});
  final String flagKey;
  final dynamic value;
  @override
  String get name => 'feature_flag_evaluated';
  @override
  Map<String, dynamic> get properties => {
    'flag_key': flagKey,
    'value': value,
  };
}
