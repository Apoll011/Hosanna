import 'package:dio/dio.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/social_auth_provider.dart';
import '../../../core/network/api_client.dart';

/// Thin client over Better Auth's `/api/auth/*` REST surface.
///
/// The React app uses `better-auth/client` + `@hosanna/shared`'s `ApiClient`;
/// here we call the same endpoints through Dio. Hand-rolled rather than using
/// `flutter_better_auth` because this app needs (a) per-request Turnstile
/// captcha injection, (b) the bearer `set-auth-token` + cookie session combo,
/// and (c) the organization-plugin endpoints — none of which the pub package
/// covers cleanly.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  // ── Session ──────────────────────────────────────────────────────────────

  /// GET /api/auth/get-session → `{session, user}` or `null`.
  Future<AuthSession?> getSession() async {
    try {
      final res = await _dio.get<dynamic>('/api/auth/get-session');
      final data = res.data;
      if (data == null) return null;
      if (data is Map && (data['session'] == null || data['user'] == null)) {
        return null;
      }
      return AuthSession.fromJson(_asMap(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw toApiException(e);
    }
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
    String? captchaToken,
    String? fcm,
    bool? notify,
  }) async {
    return _authRequest(
      () => _dio.post<dynamic>(
        '/api/auth/sign-in/email',
        // The `fcm`/`notify` session additional fields are written onto the
        // session this call creates, so they belong to the new device session.
        data: {'email': email, 'password': password, 'fcm': ?fcm, 'notify': ?notify},
        options: _captchaOptions(captchaToken),
      ),
    );
  }

  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
    String? captchaToken,
    String? fcm,
    bool? notify,
  }) async {
    return _authRequest(
      () => _dio.post<dynamic>(
        '/api/auth/sign-up/email',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'fcm': ?fcm,
          'notify': ?notify,
        },
        options: _captchaOptions(captchaToken),
      ),
    );
  }

  /// POST /api/auth/update-session
  ///
  /// Updates **only** the current session's additional fields. Only the values
  /// actually supplied are sent, so `updateSession(notify: false)` produces
  /// `{"notify": false}` and never touches `fcm` (or the user record).
  Future<AuthSession> updateSession({String? fcm, bool? notify}) async {
    return _authRequest(
      () => _dio.post<dynamic>(
        '/api/auth/update-session',
        data: {
          'fcm': ?fcm,
          'notify': ?notify,
        },
      ),
    );
  }

  /// Signs in (or signs up) with a native provider credential.
  ///
  /// POSTs Better Auth's `/api/auth/sign-in/social` with the provider id and
  /// the credential the native provider produced (the `signIn.social({idToken})`
  /// shape). When an ID token is sent, Better Auth skips the OAuth redirect:
  /// it verifies the token itself, then finds or creates the user, so the
  /// response is the same `{user, token}` payload as email sign-in and is
  /// stored through the exact same session path. The server decides whether
  /// this is a sign-in or a sign-up; no captcha is involved on this endpoint.
  Future<AuthSession> signInWithSocial({
    required String providerId,
    required SocialAuthCredential credential,
  }) {
    return _authRequest(
      () => _dio.post<dynamic>(
        '/api/auth/sign-in/social',
        data: {'provider': providerId, 'idToken': credential.toJson()},
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await _dio.post<dynamic>('/api/auth/sign-out');
    } on DioException {
      // Sign-out is best-effort; a failed call still clears local state.
    }
  }

  // ── Verification & password reset ────────────────────────────────────────

  Future<void> requestPasswordReset({
    required String email,
    String? captchaToken,
  }) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/request-password-reset',
        data: {'email': email},
        options: _captchaOptions(captchaToken),
      ),
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/reset-password',
        data: {'newPassword': newPassword, 'token': token},
      ),
    );
  }

  Future<void> sendVerificationEmail({String? email}) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/send-verification-email',
        data: {'email': ?email},
      ),
    );
  }

  // ── Account management ───────────────────────────────────────────────────

  Future<AuthSession> updateUser({String? name, String? image}) async {
    return _authRequest(
      () => _dio.post<dynamic>(
        '/api/auth/update-user',
        data: {
          'name': ?name,
          'image': ?image,
        },
      ),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'revokeOtherSessions': true,
        },
      ),
    );
  }

  Future<void> changeEmail({required String newEmail}) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/change-email',
        data: {'newEmail': newEmail},
      ),
    );
  }

  // ── Organization plugin ──────────────────────────────────────────────────

  /// The active (full) organization, or `null` when none is set.
  Future<Organization?> getFullOrganization() async {
    try {
      final res =
          await _dio.get<dynamic>('/api/auth/organization/get-full-organization');
      final data = res.data;
      if (data == null) return null;
      final map = _asMap(data);
      if (map.isEmpty) return null;
      return Organization.fromJson(map);
    } on DioException {
      return null;
    }
  }

  Future<List<Organization>> listOrganizations() async {
    final res = await _dio.get<dynamic>('/api/auth/organization/list');
    final data = res.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Organization.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> setActiveOrganization(String slug) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/organization/set-active',
        data: {'organizationSlug': slug},
      ),
    );
  }

  /// Pending invitations addressed to the signed-in user.
  Future<List<OrganizationInvitation>> listUserInvitations() async {
    final res = await _dio.get<dynamic>(
      '/api/auth/organization/list-user-invitations',
    );
    final data = res.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => OrganizationInvitation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> acceptInvitation(String invitationId) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/organization/accept-invitation',
        data: {'invitationId': invitationId},
      ),
    );
  }

  Future<void> rejectInvitation(String invitationId) async {
    await _guard(
      () => _dio.post<dynamic>(
        '/api/auth/organization/reject-invitation',
        data: {'invitationId': invitationId},
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Options _captchaOptions(String? token) => Options(extra: {
        if (token != null && token.isNotEmpty) kCaptchaTokenExtraKey: token,
      });

  Future<AuthSession> _authRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final res = await request();
      final token = _extractBearerToken(res);
      final data = res.data;
      if (data is Map) {
        final session = AuthSession.fromJson(Map<String, dynamic>.from(data));
        if (token.isNotEmpty && session.sessionToken.isEmpty) {
          // Prefer the bearer header token when the body omitted it.
          return AuthSession(
            user: session.user,
            sessionToken: token,
            activeOrganizationId: session.activeOrganizationId,
            organization: session.organization,
            expiresAt: session.expiresAt,
            fcm: session.fcm,
            notify: session.notify,
          );
        }
        return session;
      }
      return AuthSession(
        user: const AuthUser(id: '', name: '', email: ''),
        sessionToken: token,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  String _extractBearerToken(Response<dynamic> res) {
    final header = res.headers.value('set-auth-token');
    return header ?? '';
  }

  Future<void> _guard(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
