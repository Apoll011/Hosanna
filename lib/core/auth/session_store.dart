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
  static const _memberRoleKey = 'hosanna_member_role';

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

  /// Org membership role for offline RBAC (song edit/create, etc.).
  ///
  /// Stored with [orgId] so a role for org A is never applied to org B after
  /// a workspace switch that failed to re-resolve online.
  Future<CachedMemberRole?> readMemberRole() async {
    final raw = await _storage.read(key: _memberRoleKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final orgId = json['orgId'];
      final role = json['role'];
      if (orgId is! String || orgId.isEmpty) return null;
      if (role is! String || role.isEmpty) return null;
      return CachedMemberRole(orgId: orgId, role: role);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMemberRole({
    required String orgId,
    required String role,
  }) {
    return _storage.write(
      key: _memberRoleKey,
      value: jsonEncode({'orgId': orgId, 'role': role}),
    );
  }

  Future<void> clearMemberRole() => _storage.delete(key: _memberRoleKey);

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _memberRoleKey);
  }
}

/// Cached Better Auth membership role scoped to one organization.
class CachedMemberRole {
  const CachedMemberRole({required this.orgId, required this.role});

  final String orgId;
  final String role;
}
