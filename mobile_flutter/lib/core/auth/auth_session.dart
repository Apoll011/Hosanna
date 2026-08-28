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
  });

  final AuthUser user;

  /// Session token issued by the Better Auth bearer plugin
  /// (also persisted in secure storage and sent as `Authorization: Bearer`).
  final String sessionToken;

  final String? activeOrganizationId;
  final Organization? organization;
  final DateTime? expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    final sessionMap = session is Map<String, dynamic> ? session : <String, dynamic>{};
    final userMap = json['user'];
    final user = userMap is Map<String, dynamic>
        ? AuthUser.fromJson(userMap)
        : AuthUser(id: '', name: '', email: '');

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
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'token': sessionToken,
        if (activeOrganizationId != null)
          'activeOrganizationId': activeOrganizationId,
        if (organization != null) 'organization': organization!.toJson(),
      };
}
