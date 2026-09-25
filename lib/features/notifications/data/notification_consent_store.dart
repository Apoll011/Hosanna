import 'package:shared_preferences/shared_preferences.dart';

/// Records the user's answer to "may we send notifications to this device?".
///
/// Tri-state: `null` = never asked, `true` = consented, `false` = declined.
/// Persisted per install (i.e. per device), which mirrors the per-session
/// nature of Better Auth's `session.notify`: the same account on another
/// device has its own consent and its own session.
abstract class NotificationConsentStore {
  Future<bool?> read();

  Future<void> write(bool consented);
}

/// Shared-preferences backed implementation used by the app.
class PrefsNotificationConsentStore implements NotificationConsentStore {
  PrefsNotificationConsentStore(this._prefs);

  static const _key = 'notifications.consented';

  final SharedPreferences _prefs;

  @override
  Future<bool?> read() async => _prefs.getBool(_key);

  @override
  Future<void> write(bool consented) => _prefs.setBool(_key, consented);
}

/// Default for tests / when no preferences are available: consent unknown.
class InMemoryNotificationConsentStore implements NotificationConsentStore {
  bool? _value;

  @override
  Future<bool?> read() async => _value;

  @override
  Future<void> write(bool consented) async => _value = consented;
}
