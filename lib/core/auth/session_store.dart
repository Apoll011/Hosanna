import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

/// Persists the authenticated session and bearer token securely
/// (Keychain on iOS, EncryptedSharedPreferences on Android).
class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'hosanna_session';
  static const _tokenKey = 'hosanna_access_token';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSession(AuthSession session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _tokenKey);
  }
}
