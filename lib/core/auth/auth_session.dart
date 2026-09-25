/// Domain models for the authenticated session, mirroring the Better Auth
/// `get-session` response surface actually used by the React app.
library;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.image,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String? image;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        emailVerified: json['emailVerified'] == true,
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'emailVerified': emailVerified,
        if (image != null) 'image': image,
      };
}

/// The active organization (tenant). Only the fields needed by v1.
class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

/// A pending invitation to join an organization, as returned by Better Auth's
/// `GET /organization/list-user-invitations`.
class OrganizationInvitation {
  const OrganizationInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.organizationId,
    this.organizationName,
    required this.inviterId,
    this.teamId,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String role;
  final String organizationId;
  final String? organizationName;
  final String inviterId;
  final String? teamId;
  final String status;
  final String expiresAt;
  final String createdAt;

  factory OrganizationInvitation.fromJson(Map<String, dynamic> json) =>
      OrganizationInvitation(
        id: json['id'] as String,
        email: (json['email'] ?? '') as String,
        role: (json['role'] ?? 'member') as String,
        organizationId: (json['organizationId'] ?? '') as String,
        organizationName: json['organizationName'] as String?,
        inviterId: (json['inviterId'] ?? '') as String,
        teamId: json['teamId'] as String?,
        status: (json['status'] ?? 'pending') as String,
        expiresAt: (json['expiresAt'] ?? '') as String,
        createdAt: (json['createdAt'] ?? '') as String,
      );
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.sessionToken,
    this.activeOrganizationId,
    this.organization,
    this.expiresAt,
    this.fcm,
    this.notify = true,
  });

  final AuthUser user;

  /// Session token issued by the Better Auth bearer plugin
  /// (also persisted in secure storage and sent as `Authorization: Bearer`).
  final String sessionToken;

  final String? activeOrganizationId;
  final Organization? organization;
  final DateTime? expiresAt;

  /// FCM registration token for the device this session belongs to.
  ///
  /// Stored per Better Auth session (not on the user), because one account can
  /// be signed in on several devices, each with its own token. `null` when the
  /// session predates FCM support or the device has not registered a token
  /// yet, so callers must handle its absence.
  final String? fcm;

  /// Whether the server is allowed to push notifications to **this** session.
  ///
  /// This is independent of the OS notification permission. Defaults to `true`
  /// (Better Auth's `defaultValue`) and is forced to `true` when the server
  /// omits the field, since older sessions may not carry it.
  final bool notify;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    final sessionMap = session is Map<String, dynamic> ? session : <String, dynamic>{};
    final userMap = json['user'];
    final user = userMap is Map<String, dynamic>
        ? AuthUser.fromJson(userMap)
        : AuthUser(id: '', name: '', email: '');

    // `fcm`/`notify` are session additional fields. Read them from the nested
    // `session` object as well as the top level so a session round-tripped
    // through [toJson] keeps them.
    final fcm = sessionMap['fcm'] as String? ?? json['fcm'] as String?;
    final notify = sessionMap['notify'] as bool? ?? json['notify'] as bool?;

    return AuthSession(
      user: user,
      sessionToken:
          (json['token'] as String?) ?? (sessionMap['token'] as String?) ?? '',
      activeOrganizationId: sessionMap['activeOrganizationId'] as String?,
      organization: json['organization'] is Map<String, dynamic>
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      expiresAt: sessionMap['expiresAt'] is String
          ? DateTime.tryParse(sessionMap['expiresAt'] as String)
          : null,
      fcm: (fcm == null || fcm.isEmpty) ? null : fcm,
      notify: notify ?? true,
    );
  }

  /// Copies this session, replacing the per-session FCM fields.
  AuthSession copyWithFcm({String? fcm, bool? notify}) => AuthSession(
        user: user,
        sessionToken: sessionToken,
        activeOrganizationId: activeOrganizationId,
        organization: organization,
        expiresAt: expiresAt,
        fcm: fcm ?? this.fcm,
        notify: notify ?? this.notify,
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'token': sessionToken,
        if (activeOrganizationId != null)
          'activeOrganizationId': activeOrganizationId,
        if (organization != null) 'organization': organization!.toJson(),
        if (fcm != null) 'fcm': fcm,
        'notify': notify,
      };
}
